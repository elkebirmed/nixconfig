# ============================================================================
# OmniRoute Library
# Shared NixOS module for the self-hosted AI gateway.
#
# The aspect wrappers choose the SOPS file, the owner of the bootstrap key,
# and whether the state directories are backed by impermanence.
# ============================================================================
{
  sopsFile,
  owner,
  keyName ? "opencode",
  useImpermanence ? true,
  # The VPS runs OmniRoute through Quadlet (the server container path). The
  # desktop user instance keeps `oci-containers` so the desktop host is not
  # forced to adopt the Quadlet module and its inputs.
  useQuadlet ? false,
}: {
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

  # `oci-containers` names the unit after the container
  # (`podman-omniroute.service`); quadlet-nix derives the unit name from the
  # attribute name (`omniroute.service`). The bootstrap service must order
  # against whichever backend is in use.
  containerUnit =
    if useQuadlet
    then "omniroute.service"
    else "podman-omniroute.service";
in
  lib.optionalAttrs useImpermanence {
    environment.persistence."/persist".directories = [
      {
        directory = "/var/lib/omniroute";
        user = "10001";
        group = "10001";
        mode = "0750";
      }
      {
        # Holds the gateway API key, which only the owner may read.
        directory = "/var/lib/omniroute-bootstrap";
        user = owner;
        group = "root";
        mode = "0700";
      }
    ];
  }
  // {
    # Without impermanence the data directory is created on first boot.
    systemd.tmpfiles.rules = lib.optionals (!useImpermanence) [
      "d /var/lib/omniroute 0750 10001 10001 -"
    ];

    virtualisation =
      {
        podman.enable = true;
      }
      // lib.optionalAttrs (!useQuadlet) {
        oci-containers.backend = "podman";
      }
      // (
        if useQuadlet
        then {
          # Quadlet path (server): one declarative container interface, with an
          # explicit systemd unit the bootstrap service can depend on.
          quadlet.containers.omniroute = {
            containerConfig = {
              # Pinned by digest so a moved `:latest` tag cannot silently change
              # the code that reads the gateway key. Bump with:
              #   nix run nixpkgs#skopeo -- inspect --format '{{.Digest}}' \
              #     docker://docker.io/diegosouzapw/omniroute:latest
              # This is a PUBLIC upstream image, so keeping it here does not
              # disclose anything private.
              Image = "docker.io/diegosouzapw/omniroute@sha256:2c4c755a54f8ce5341bc1856580b71f47a0f16a9afab4a55f84d540810631f68";
              User = "10001:10001";
              PublishPort = ["127.0.0.1:20128:20128"];
              Volume = ["/var/lib/omniroute:/app/data"];
              Environment = ["REQUIRE_API_KEY=true"];
              EnvironmentFile = [config.sops.templates."omniroute.env".path];
              # Container hardening: no new privileges, no capabilities, and a
              # read-only root with a writable tmpfs for scratch space. State
              # lives only in the bind-mounted /app/data volume.
              NoNewPrivileges = true;
              DropCapability = ["all"];
              ReadOnly = true;
              Tmpfs = ["/tmp"];
            };
            serviceConfig = {
              Restart = "always";
              # Image pull can exceed the default 90 s startup budget.
              TimeoutStartSec = "600";
              MemoryMax = "1536M";
              CPUQuota = "200%";
            };
            unitConfig = {
              Description = "OmniRoute AI gateway (loopback)";
              WantedBy = ["multi-user.target"];
            };
          };
        }
        else {
          oci-containers.containers.omniroute = {
            image = "docker.io/diegosouzapw/omniroute@sha256:2c4c755a54f8ce5341bc1856580b71f47a0f16a9afab4a55f84d540810631f68";
            user = "10001:10001";
            ports = ["127.0.0.1:20128:20128"];
            volumes = ["/var/lib/omniroute:/app/data"];
            environment.REQUIRE_API_KEY = "true";
            environmentFiles = [config.sops.templates."omniroute.env".path];
          };
        }
      );

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
      # The unit name differs by container backend: `oci-containers` yields
      # `podman-omniroute.service`, Quadlet yields `omniroute.service`.
      after = [
        containerUnit
        "sops-install-secrets.service"
      ];
      requires = [containerUnit];
      wantedBy = ["multi-user.target"];
      # Re-run reconciliation when the provider list or any credential changes.
      restartTriggers =
        [providerSpecsFile]
        ++ map (name: config.sops.secrets.${name}.path) providerSecretNames;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # No `StateDirectory`: systemd would chown the impermanence bind mount
        # to root and make the key unreadable by its owner. The script creates
        # the directory with the right ownership instead.
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

        # Owned by the invoking user so only they can read the gateway key.
        install -d -m 0700 -o ${owner} -g root "$state_dir"

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

        # 1. Gateway API key consumed by OpenClaw. Owned by the invoking user
        # and unreadable by anyone else.
        if [ ! -s "$key_file" ]; then
          response=$(curl -fsS -b "$jar" -H 'Content-Type: application/json' \
            -d '{"name":"${keyName}"}' ${baseUrl}/api/keys)
          gateway_key=$(jq -er '.key // .apiKey // .data.key' <<<"$response")
          install -m 0400 -o ${owner} -g root /dev/stdin "$key_file" <<<"$gateway_key"
          log "created ${keyName} gateway API key"
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

    # The container definition itself lives in the single `virtualisation`
    # binding above (it must be one attribute, so it is merged there).
  }
