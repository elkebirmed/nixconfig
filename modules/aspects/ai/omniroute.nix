# ============================================================================
# OmniRoute
# Self-hosted AI gateway with SOPS-managed provider credentials.
# ============================================================================
_: {
  den.aspects.omniroute = {user, ...}: let
    # AI credentials live in the owning user's SOPS file so a host rebuild only
    # needs that user's secrets unlocked.
    sopsFile = ../../../secrets/users + "/${user.userName}.yaml";
  in {
    provides.to-hosts.nixos = {
      config,
      lib,
      pkgs,
      ...
    }: let
      baseUrl = "http://127.0.0.1:20128";

      # Free providers that authenticate with a static API token, so their
      # credentials can live in SOPS and be reconciled declaratively.
      #
      # Set the matching `omniroute.providers.<id>.api-key` value with `sops`
      # to enable a provider. Entries that are empty or left as REPLACE_ME are
      # skipped. `llm7` accepts any non-empty key, so `fallbackApiKey` keeps it
      # working out of the box (a real token only raises its rate limits).
      providerCatalog = {
        mistral = {name = "Mistral";};
        nara = {name = "NaraRouter";};
        groq = {name = "Groq";};
        openrouter = {name = "OpenRouter";};
        opencode-zen = {name = "OpenCode Zen";};
        gemini = {name = "Gemini (Google AI Studio)";};
        nvidia = {name = "NVIDIA NIM";};
        cloudflare-ai = {
          name = "Cloudflare Workers AI";
          hasAccountId = true;
        };
        llm7 = {
          name = "LLM7.io";
          fallbackApiKey = "unused";
        };
      };

      providerSpecs =
        lib.mapAttrsToList (provider: cfg: {
          inherit provider;
          inherit (cfg) name;
          connection = "nix-${provider}";
          apiKeyFile = config.sops.secrets."omniroute/providers/${provider}/api-key".path;
          fallbackApiKey = cfg.fallbackApiKey or "";
          accountIdFile =
            if cfg.hasAccountId or false
            then config.sops.secrets."omniroute/providers/${provider}/account-id".path
            else "";
        })
        providerCatalog;

      providerSecretNames = lib.concatMap (
        provider:
          ["omniroute/providers/${provider}/api-key"]
          ++ lib.optional (providerCatalog.${provider}.hasAccountId or false)
          "omniroute/providers/${provider}/account-id"
      ) (lib.attrNames providerCatalog);

      providerSpecsFile = pkgs.writeText "omniroute-providers.json" (builtins.toJSON providerSpecs);
    in {
      environment.persistence."/persist".directories = [
        {
          directory = "/var/lib/omniroute";
          user = "10001";
          group = "10001";
          mode = "0750";
        }
        {
          # Only the host reads this directory (the gateway key is consumed by
          # OpenCode), so keep it traversable for the unprivileged user.
          directory = "/var/lib/omniroute-bootstrap";
          user = "root";
          group = "root";
          mode = "0755";
        }
      ];

      sops.secrets =
        lib.genAttrs providerSecretNames (_: {inherit sopsFile;})
        // {
          "omniroute/jwt-secret" = {inherit sopsFile;};
          "omniroute/api-key-secret" = {inherit sopsFile;};
          "omniroute/admin-password" = {inherit sopsFile;};
        };

      sops.templates."omniroute.env".content = ''
        JWT_SECRET=${config.sops.placeholder."omniroute/jwt-secret"}
        API_KEY_SECRET=${config.sops.placeholder."omniroute/api-key-secret"}
        INITIAL_PASSWORD=${config.sops.placeholder."omniroute/admin-password"}
      '';

      systemd.services.omniroute-bootstrap = {
        description = "Create OmniRoute gateway API key and reconcile provider credentials";
        after = [
          "podman-omniroute.service"
          "sops-install-secrets.service"
        ];
        requires = ["podman-omniroute.service"];
        wantedBy = ["multi-user.target"];
        # Re-run reconciliation when the provider list or any credential changes.
        restartTriggers =
          [providerSpecsFile]
          ++ map (name: config.sops.secrets.${name}.path) providerSecretNames;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          StateDirectory = "omniroute-bootstrap";
          StateDirectoryMode = "0755";
        };
        path = with pkgs; [
          curl
          jq
          coreutils
          gawk
          gnused
        ];
        script = ''
          set -euo pipefail
          umask 077

          state_dir=/var/lib/omniroute-bootstrap
          key_file=$state_dir/api-key
          state_file=$state_dir/providers.state

          log() { echo "omniroute-bootstrap: $*"; }

          # Read a single-line secret, dropping the trailing newline SOPS adds.
          read_secret() {
            if [ ! -r "$1" ]; then
              return 0
            fi
            tr -d '\r\n' < "$1"
          }

          until curl -s -o /dev/null ${baseUrl}/; do
            sleep 2
          done

          jar=$(mktemp)
          trap 'rm -f "$jar"' EXIT

          # Wait for the dashboard to be ready to accept the admin password.
          attempt=0
          until jq -n --rawfile p ${config.sops.secrets."omniroute/admin-password".path} \
            '{password: ($p | rtrimstr("\n"))}' |
            curl -fsS -c "$jar" -H 'Content-Type: application/json' -d @- \
              ${baseUrl}/api/auth/login >/dev/null; do
            attempt=$((attempt + 1))
            if [ "$attempt" -ge 30 ]; then
              log "login failed after $attempt attempts"
              exit 1
            fi
            sleep 2
          done

          # 1. Gateway API key consumed by OpenCode.
          if [ ! -s "$key_file" ]; then
            response=$(curl -fsS -b "$jar" -H 'Content-Type: application/json' \
              -d '{"name":"opencode"}' ${baseUrl}/api/keys)
            gateway_key=$(jq -er '.key // .apiKey // .data.key' <<<"$response")
            install -m 0440 -o mohamed -g users /dev/stdin "$key_file" <<<"$gateway_key"
            log "created OpenCode gateway API key"
          fi

          # 2. Provider connections, reconciled by name so repeated runs update
          # the existing connection instead of creating duplicates.
          specs=$(mktemp)
          jq -c '.[]' ${providerSpecsFile} > "$specs"

          while IFS= read -r spec; do
            provider=$(jq -r '.provider' <<<"$spec")
            connection=$(jq -r '.connection' <<<"$spec")
            api_key_file=$(jq -r '.apiKeyFile' <<<"$spec")
            account_id_file=$(jq -r '.accountIdFile' <<<"$spec")

            api_key=$(read_secret "$api_key_file")
            case "$api_key" in
              "" | REPLACE_ME)
                api_key=$(jq -r '.fallbackApiKey' <<<"$spec")
                ;;
            esac
            case "$api_key" in
              "" | REPLACE_ME)
                log "$provider: no API key in SOPS, skipping"
                continue
                ;;
            esac

            payload=$(jq -cn --arg provider "$provider" --arg name "$connection" \
              --arg apiKey "$api_key" '{provider: $provider, name: $name, apiKey: $apiKey}')

            if [ -n "$account_id_file" ]; then
              account_id=$(read_secret "$account_id_file")
              case "$account_id" in
                "" | REPLACE_ME)
                  log "$provider: no account id in SOPS, skipping"
                  continue
                  ;;
              esac
              payload=$(jq -c --arg accountId "$account_id" \
                '. + {providerSpecificData: {accountId: $accountId}}' <<<"$payload")
            fi

            digest=$(printf '%s' "$payload" | sha256sum | cut -d ' ' -f 1)

            if ! connections=$(curl -fsS -b "$jar" \
              --get --data-urlencode "provider=$provider" ${baseUrl}/api/providers); then
              log "$provider: could not list connections"
              continue
            fi
            existing_id=$(jq -r --arg name "$connection" \
              '[.connections[] | select(.name == $name)][0].id // empty' <<<"$connections")

            if [ -n "$existing_id" ] && grep -qxF "$provider $digest" "$state_file" 2>/dev/null; then
              log "$provider: unchanged"
              continue
            fi

            if [ -n "$existing_id" ]; then
              connection_id=$existing_id
              if ! curl -fsS -b "$jar" -X PUT -H 'Content-Type: application/json' \
                -d "$(jq -c 'del(.provider)' <<<"$payload")" \
                "${baseUrl}/api/providers/$existing_id" >/dev/null; then
                log "$provider: update failed"
                continue
              fi
              # Updating does not re-test, so probe explicitly to (re)activate it.
              curl -fsS -b "$jar" -H 'Content-Type: application/json' -d '{}' \
                "${baseUrl}/api/providers/$existing_id/test" >/dev/null || true
              log "$provider: updated"
            else
              if ! response=$(curl -fsS -b "$jar" -H 'Content-Type: application/json' \
                -d "$payload" ${baseUrl}/api/providers); then
                log "$provider: create failed"
                continue
              fi
              connection_id=$(jq -r '.connection.id // empty' <<<"$response")
              log "$provider: created"
            fi

            # Refresh the provider's model list so new connections do not keep
            # the (possibly stale) built-in catalog that OmniRoute ships.
            if [ -n "$connection_id" ]; then
              if curl -fsS -b "$jar" -X POST --max-time 30 \
                "${baseUrl}/api/providers/$connection_id/sync-models" >/dev/null; then
                log "$provider: models synced"
              else
                # Do not record the credentials hash, so the next run retries.
                log "$provider: model sync failed, will retry next run"
                continue
              fi
            fi

            updated_state=$(mktemp)
            awk -v provider="$provider" '$1 != provider' "$state_file" 2>/dev/null \
              > "$updated_state" || true
            printf '%s %s\n' "$provider" "$digest" >> "$updated_state"
            mv "$updated_state" "$state_file"
          done < "$specs"

          rm -f "$specs"
          log "provider reconciliation complete"
        '';
      };

      virtualisation.oci-containers.containers.omniroute = {
        image = "docker.io/diegosouzapw/omniroute:latest";
        user = "10001:10001";
        ports = ["127.0.0.1:20128:20128"];
        volumes = ["/var/lib/omniroute:/app/data"];
        environment.REQUIRE_API_KEY = "true";
        environmentFiles = [config.sops.templates."omniroute.env".path];
      };
    };
  };
}
