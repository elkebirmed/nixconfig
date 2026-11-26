# ============================================================================
# OpenClaw
# OpenClaw gateway for the VPS via the official nix-openclaw Home Manager
# module. The gateway runs as the unprivileged `claw` user, binds loopback,
# reads every secret from a runtime file, and is proxied by Caddy over the
# tailnet.
#
# Security boundary: this is an assistant, not an operator. It gets no shell
# toolchain (the upstream default PATH includes git/curl/jq/python3), no host
# terminal, no container or Nix socket, no sudo, and no deployment credentials.
# See the README "OpenClaw boundary" section before relaxing any of this.
# ============================================================================
{inputs, ...}: {
  # Pin the official module. nix-openclaw follows this flake's nixpkgs and
  # Home Manager so the gateway is built against the same package set.
  flake-file.inputs.nix-openclaw = {
    url = "github:openclaw/nix-openclaw";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };

  den.aspects.openclaw = {user, ...}: {
    homeManager = {
      lib,
      pkgs,
      ...
    }: let
      package = inputs.nix-openclaw.packages.${pkgs.stdenv.hostPlatform.system}.openclaw;

      # Command Code Provider API catalog (base URL, default model, model list).
      cc = import ../ai/_commandcode-lib.nix;

      # Home Manager publishes openclaw.json as a symlink into the read-only
      # Nix store, and `controlUi.allowedOrigins` must contain the public
      # hostname, which may never be evaluated into the store. So the gateway
      # runs against a RUNTIME copy instead:
      #   1. read the store file (symlink target),
      #   2. materialize it as a regular file in the state dir,
      #   3. inject allowedOrigins from the SOPS-rendered /run file.
      # Home Manager restores the symlink on the next activation and this hook
      # re-materializes it on the next start, so the two never fight.
      patchControlUi = pkgs.writeShellScript "openclaw-patch-control-ui" ''
        set -euo pipefail
        export PATH=${lib.makeBinPath [pkgs.coreutils]}:$PATH

        cfg=/home/${user.userName}/.openclaw/openclaw.json
        origin_file=/run/openclaw-origin

        if [ ! -e "$cfg" ]; then
          echo "control-ui: config missing at $cfg" >&2
          exit 1
        fi

        # The template is rendered during activation while the lingered user
        # manager may already be starting; wait briefly rather than fail boot.
        attempt=0
        until [ -r "$origin_file" ]; do
          attempt=$((attempt + 1))
          if [ "$attempt" -gt 60 ]; then
            echo "control-ui: origin not available after 60s: $origin_file" >&2
            exit 1
          fi
          sleep 1
        done

        origin=$(tr -d '[:space:]' < "$origin_file")
        if [ -z "$origin" ]; then
          echo "control-ui: origin file is empty: $origin_file" >&2
          exit 1
        fi

        # Store the runtime config in the same directory so the symlink can be
        # replaced atomically. `mktemp` guarantees a same-filesystem target.
        work=$(mktemp -p "$(dirname "$cfg")" .openclaw-config.XXXXXX)
        chmod 600 "$work"

        # Resolve the symlink into the template before patching.
        cp -L "$cfg" "$work"

        ${pkgs.jq}/bin/jq --arg origin "$origin" \
          '.gateway.controlUi = ((.gateway.controlUi // {}) + {
             enabled: true,
             allowedOrigins: [$origin]
           })' \
          "$work" > "$work.out"
        chmod 600 "$work.out"
        mv -f "$work.out" "$cfg"
        rm -f "$work"

        # Never echo the origin: it is a private identifier.
        echo "control-ui: runtime config written (origin len=$(printf %s "$origin" | wc -c))"
      '';
    in {
      imports = [inputs.nix-openclaw.homeManagerModules.openclaw];

      programs.openclaw = {
        # The top-level package is explicit so the module never evaluates the
        # `pkgs.openclaw` default from an overlay that is not applied.
        inherit package;

        # Deny the upstream toolchain entirely. Its default set is
        # nodejs/pnpm/git/curl/jq/python3/ffmpeg/sox/ripgrep plus helper CLIs,
        # which would give the assistant an execution and network path into
        # the host and the tailnet. `toolNames = []` empties the wrapper PATH;
        # the explicit excludes are belt-and-braces if upstream reintroduces a
        # default. Extra packages are never added at runtime.
        toolNames = [];
        excludeTools = [
          "nodejs_24"
          "pnpm"
          "git"
          "curl"
          "jq"
          "python3"
          "ffmpeg"
          "sox"
          "ripgrep"
          "gogcli"
          "goplaces"
          "summarize"
          "camsnap"
          "sonoscli"
        ];
        runtimePackages = [];

        instances.default = {
          enable = true;
          inherit package;
          stateDir = "/home/${user.userName}/.openclaw";
          workspaceDir = "/home/${user.userName}/.openclaw/workspace";
          logPath = "/home/${user.userName}/.openclaw/openclaw-gateway.log";
        };

        environment = {
          OPENCLAW_GATEWAY_TOKEN = "/run/secrets/openclaw-gateway-token";
          # nix-openclaw's env wrapper reads a path-valued entry as a file, so
          # this resolves to the key itself at start, never in the store.
          CMDC_API_KEY = "/run/secrets/cmdc/api-key";
        };

        workspace.bootstrapFiles = {
          agents = ./openclaw/workspace/AGENTS.md;
          soul = ./openclaw/workspace/SOUL.md;
          tools = ./openclaw/workspace/TOOLS.md;
          identity = ./openclaw/workspace/IDENTITY.md;
          user = ./openclaw/workspace/USER.md;
        };

        # Linux headless only, and the minimal set that confers no
        # infrastructure access. `summarize` is disabled rather than merely
        # unused: it is the only bundled plugin that pulls a large npm tree
        # (and the one that makes the closure unbuildable offline), and URL
        # summarisation is a network-fetch path the assistant does not need.
        bundledPlugins = {
          summarize.enable = false;
          discrawl.enable = false;
          wacrawl.enable = false;
          peekaboo.enable = false;
          poltergeist.enable = false;
          sag.enable = false;
          camsnap.enable = false;
          gogcli.enable = false;
          goplaces.enable = false;
          sonoscli.enable = false;
          imsg.enable = false;
        };

        config = {
          gateway = {
            mode = "local";
            bind = "loopback";

            # Caddy is the only process that reaches the gateway. Trust its
            # forwarded client headers so proxied requests are attributable.
            trustedProxies = ["127.0.0.1" "::1"];

            # The browser control UI is enabled. It must be: every path except
            # /health(z) returns 404 otherwise.
            #
            # `allowedOrigins` is deliberately NOT set here. It must contain the
            # real public hostname, and this file is evaluated into the Nix
            # store. Instead a pre-start hook injects it from a SOPS-derived
            # value; see the ExecStartPre below. The store copy only ever holds
            # `enabled: true`.
            controlUi = {
              enabled = true;
            };

            # Config is authoritative at START only, not on the running process.
            #
            # Home Manager regenerates openclaw.json as a symlink into the store,
            # and on every rebuild that store copy has `allowedOrigins` absent.
            # The pre-start hook below materializes the runtime copy with the
            # origin injected — but a hook only runs at unit start. Upstream's
            # default `hybrid` mode hot-reloads the file, so a rebuild silently
            # dropped `allowedOrigins` from the live gateway and every browser
            # connection was rejected with `origin not allowed`.
            #
            # `off` makes a restart mandatory, which is correct here: the config
            # is generated by Nix, so live edits are not a workflow, and the
            # pre-start hook then governs every load. Upstream marks `restart`
            # and `hot` as retired; `off` and `hybrid` are the accepted values.
            reload.mode = "off";

            # Upstream defaults this to enabled: an admin-scoped host PTY that
            # inherits the gateway environment. That is an execution path to
            # the host, so it is switched off explicitly.
            terminal.enabled = false;

            # Client file/image uploads are not needed for a chat assistant and
            # widen the ingestion surface.
            uploads.enabled = false;

            auth = {
              mode = "token";
              token = {
                source = "env";
                provider = "default";
                id = "OPENCLAW_GATEWAY_TOKEN";
              };
            };
          };

          channels.telegram = {
            enabled = true;
            tokenFile = "/run/secrets/openclaw-telegram-token";
            # Keep user IDs out of the public repo: approve the first DM
            # with `openclaw pairing approve telegram <CODE>`.
            dmPolicy = "pairing";
            groups."*".requireMention = true;
          };

          models = {
            mode = "merge";
            # Command Code's Provider API is OpenAI-compatible, so the gateway
            # reaches it directly over HTTPS — no local gateway container.
            # Every id below supports /chat/completions; Claude-family models
            # advertise /messages only and would be rejected here.
            providers.commandcode = {
              baseUrl = cc.baseURL;
              api = "openai-completions";
              apiKey = {
                source = "env";
                provider = "default";
                id = "CMDC_API_KEY";
              };
              inherit (cc) models;
            };
          };

          # `commandcode/` + model id. The default id is slash-free on purpose:
          # the first path segment is the provider name, so a model id that
          # itself contains a slash would make that split ambiguous.
          agents.defaults.model.primary = "commandcode/${cc.defaultModel}";
        };
      };

      systemd.user.services.openclaw-gateway = {
        Install.WantedBy = ["default.target"];
        Service = {
          NoNewPrivileges = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectSystem = "strict";
          ProtectHome = "read-only";
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          ProtectClock = true;
          ProtectHostname = true;
          ProtectProc = "invisible";
          RestrictNamespaces = true;
          RestrictSUIDSGID = true;
          RestrictRealtime = true;
          RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
          LockPersonality = true;
          # Do NOT set MemoryDenyWriteExecute here. OpenClaw is a Node.js/V8
          # process and V8's JIT must be able to mprotect its code pages to
          # PROT_EXEC. With this enabled the gateway dies on startup with
          # `Check failed: ENOMEM` in v8::base::OS::SetPermissions (SIGTRAP).
          # Verified on the pinned nodejs-24 build; the rest of the hardening
          # below still applies.
          SystemCallArchitectures = "native";
          SystemCallFilter = ["@system-service"];
          SystemCallErrorNumber = "EPERM";
          # The gateway needs no capability at all: it is unprivileged and
          # binds a high loopback port.
          CapabilityBoundingSet = "";
          AmbientCapabilities = "";
          UMask = "0077";
          ReadWritePaths = [
            "/home/${user.userName}/.openclaw"
            "/home/${user.userName}/.cache"
            "/home/${user.userName}/.config"
            "/home/${user.userName}/.local"
          ];
          # Inject allowedOrigins before the gateway starts. There is no
          # ordering on a local model gateway any more: the Provider API is
          # remote and needs no bootstrap wait.
          ExecStartPre = ["${patchControlUi}"];
          TimeoutStartSec = "360s";
          # Move these to user-<uid>.slice if the user manager cannot delegate.
          CPUQuota = "200%";
          MemoryMax = "3G";
        };
      };
    };

    provides.to-hosts.nixos = {
      config,
      lib,
      ...
    }: {
      # Flat names keep the files directly under /run/secrets, so the
      # unprivileged gateway user can traverse to them.
      sops.secrets."openclaw-gateway-token" = {
        sopsFile = ../../../secrets/hosts/vps.yaml;
        owner = user.userName;
        mode = "0400";
      };

      sops.secrets."openclaw-telegram-token" = {
        sopsFile = ../../../secrets/hosts/vps.yaml;
        owner = user.userName;
        mode = "0400";
      };

      # Command Code API key, host-scoped on purpose: the VPS host key must
      # never be able to decrypt secrets/users/*.yaml, so the gateway reads it
      # from the host file. The gateway sees only the path; the value lands in
      # its process environment at start, never in the Nix store.
      sops.secrets."cmdc/api-key" = {
        sopsFile = ../../../secrets/hosts/vps.yaml;
        owner = user.userName;
        mode = "0400";
      };

      # The public browser origin, used as the control-UI `allowedOrigins`
      # entry. The browser sends `https://<site-host>` for this route, and an
      # apex-only origin is rejected with `origin not allowed` — so the value is
      # derived from the declared site host rather than hand-written, which
      # keeps it from drifting out of sync with `web.sites.openclaw`.
      #
      # `web.sites.openclaw.host` is `openclaw.{$WEB_DOMAIN}` (the Caddy env
      # placeholder); swapping that for the SOPS placeholder yields the real
      # origin only at activation. The store copy holds the placeholder plus the
      # static label, never the hostname.
      sops.templates."openclaw-origin" = {
        path = "/run/openclaw-origin";
        owner = user.userName;
        mode = "0400";
        content =
          "https://"
          + lib.replaceStrings ["{$WEB_DOMAIN}"] [config.sops.placeholder."web-domain"]
          config.web.sites.openclaw.host;
        # No restartUnits: the gateway is a per-user unit, and sops-nix can
        # only restart system units. The hook re-reads this file on every
        # start, so after rotating the domain run:
        #   machinectl shell claw@ -- systemctl --user restart openclaw-gateway
      };

      # The gateway is a Home Manager user service, so the Caddy route is
      # declared at the NixOS level. Caddy reaches the loopback port.
      web.sites.openclaw = {
        upstream = "http://127.0.0.1:18789";
      };
    };
  };
}
