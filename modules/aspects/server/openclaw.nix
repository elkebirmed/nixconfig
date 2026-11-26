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

      # The OmniRoute gateway key is created at first boot by the bootstrap
      # service, so wait briefly before starting the gateway.
      waitForOmniRoute = pkgs.writeShellScript "wait-omniroute-key" ''
        export PATH=${lib.makeBinPath [pkgs.coreutils]}:$PATH
        for _ in $(seq 1 150); do
          [ -s /var/lib/omniroute-bootstrap/api-key ] && exit 0
          sleep 2
        done
        exit 1
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
          OMNIROUTE_API_KEY = "/var/lib/omniroute-bootstrap/api-key";
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

            # The browser control UI is disabled. It is not needed for the
            # messaging-only assistant, and it is the only part of the config
            # that would require naming a public hostname (the origin
            # allowlist), which must not enter the Nix store.
            controlUi.enabled = false;

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
            providers.omniroute = {
              baseUrl = "http://127.0.0.1:20128/v1";
              api = "openai-completions";
              apiKey = {
                source = "env";
                provider = "default";
                id = "OMNIROUTE_API_KEY";
              };
              models = [
                {
                  id = "auto";
                  name = "OmniRoute Auto";
                }
              ];
            };
          };

          agents.defaults.model.primary = "omniroute/auto";
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
          MemoryDenyWriteExecute = true;
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
          ExecStartPre = "${waitForOmniRoute}";
          TimeoutStartSec = "360s";
          # Move these to user-<uid>.slice if the user manager cannot delegate.
          CPUQuota = "200%";
          MemoryMax = "3G";
        };
      };
    };

    provides.to-hosts.nixos = {
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

      # The gateway is a Home Manager user service, so the Caddy route is
      # declared at the NixOS level. Caddy reaches the loopback port.
      web.sites.openclaw = {
        upstream = "http://127.0.0.1:18789";
      };
    };
  };
}
