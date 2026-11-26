# ============================================================================
# Private Application Containers
# Declarative *shell* for applications whose image reference must stay private.
#
# Problem: quadlet-nix writes unit files into the Nix store, and Podman Quadlet
# does NOT expand environment variables in `Image=` (verified against the
# podman-systemd.unit(5) manual). So there is no way to keep a private image
# reference out of the store while declaring it as a normal Quadlet unit.
#
# Solution: use Quadlet's runtime search path. The Podman generator reads
# `/run/containers/systemd/`, which takes precedence over `/etc` and
# `/usr/share`, and Podman re-reads it on `daemon-reload`. This module writes
# only a *placeholder* unit into the store; the operator-side oneshot renders
# the real unit (with the real image digest) into `/run/containers/systemd/`
# from a SOPS template at activation, then reloads systemd.
#
# Net effect:
#   * no private image path, registry path, or app repo name in the store;
#   * nothing private in the flake, derivations, or build logs;
#   * the unit is a normal systemd unit, so `systemctl status` still works.
#
# Trade-offs (documented honestly):
#   * The unit file must be regenerated on every activation/secret change.
#   * A `daemon-reload` is required before the unit can start, so first-boot
#     ordering is explicit (`Before=` the container unit).
#   * VERIFY-ON-HOST: pickup of /run units across a real reboot.
# ============================================================================
_: {
  den.aspects.private-app.nixos = {
    config,
    lib,
    ...
  }: let
    cfg = config.vps.privateApps;

    mkApp = name: app: {
      # Rendered at activation from the SOPS secret holding the image digest.
      sops.secrets."${app.secretName}" = {
        sopsFile = config.sops.defaultSopsFile;
        mode = "0400";
      };

      sops.templates."private-app-${name}.container" = {
        path = "/run/containers/systemd/${name}.container";
        mode = "0400";
        content = ''
          [Unit]
          Description=${app.description}
          # Rendered from SOPS at activation; the real image reference never
          # enters the Nix store.

          [Container]
          Image=${config.sops.placeholder."${app.secretName}"}
          ContainerName=app-${name}
          # Loopback only: Caddy is the sole ingress.
          PublishPort=127.0.0.1:${toString app.port}:${toString app.containerPort}
          # One explicit persistent data directory per app.
          Volume=${app.dataDir}:${app.containerPath}
          # Hardening baseline.
          NoNewPrivileges=true
          DropCapability=all
          ReadOnly=true
          Tmpfs=/tmp

          [Service]
          Restart=always
          TimeoutStartSec=600
          MemoryMax=${app.memoryMax}
          CPUQuota=${app.cpuQuota}

          [Install]
          WantedBy=multi-user.target
        '';
        # Rendering a new unit requires systemd to re-read it.
        restartUnits = ["systemd-daemon-reload.service"];
      };

      # Reload systemd so the freshly rendered /run unit is picked up. This must
      # happen before the container unit is started.
      systemd.services."private-app-${name}-render" = {
        description = "Render ${app.description} unit and reload systemd";
        wantedBy = ["multi-user.target"];
        after = ["sops-install-secrets.service"];
        requires = ["sops-install-secrets.service"];
        before = ["${name}.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${config.systemd.package}/bin/systemctl daemon-reload";
        };
      };

      # Narrow persistent state with correct ownership.
      systemd.tmpfiles.rules = [
        "d ${app.dataDir} 0750 ${app.user} ${app.group} -"
      ];
    };
  in {
    options.vps.privateApps = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (_: {
        options = {
          description = lib.mkOption {
            type = lib.types.str;
            description = "Human description for the systemd unit.";
          };

          secretName = lib.mkOption {
            type = lib.types.str;
            description = ''
              Name of the SOPS secret holding the image reference. Contains the
              real registry/image/digest, so it is never a Nix literal.
            '';
            example = "app-image-a";
          };

          port = lib.mkOption {
            type = lib.types.port;
            description = "Loopback host port Caddy proxies to.";
          };

          containerPort = lib.mkOption {
            type = lib.types.port;
            description = "Port the application listens on inside the container.";
          };

          dataDir = lib.mkOption {
            type = lib.types.str;
            description = "Host path for the application's persistent data.";
            example = "/var/lib/app-a";
          };

          containerPath = lib.mkOption {
            type = lib.types.str;
            description = "Container path mounted from `dataDir`.";
            example = "/data";
          };

          user = lib.mkOption {
            type = lib.types.str;
            default = "root";
            description = "Owner of `dataDir`.";
          };

          group = lib.mkOption {
            type = lib.types.str;
            default = "root";
            description = "Group owner of `dataDir`.";
          };

          memoryMax = lib.mkOption {
            type = lib.types.str;
            default = "512M";
            description = "systemd MemoryMax for the container unit.";
          };

          cpuQuota = lib.mkOption {
            type = lib.types.str;
            default = "100%";
            description = "systemd CPUQuota for the container unit.";
          };

          access = lib.mkOption {
            type = lib.types.enum ["public" "tailnet"];
            default = "tailnet";
            description = "Caddy access tier for the generated site.";
          };
        };
      }));
      default = {};
      description = ''
        Applications whose image reference must stay private. Each entry
        generates a runtime-only Quadlet unit and a tailnet Caddy route. The
        application's repository name and image digest live only in SOPS.
      '';
    };

    config = lib.mkIf (cfg != {}) (let
      apps = lib.attrNames cfg;
      parts = map (name: mkApp name cfg.${name}) apps;
    in {
      sops.secrets = lib.mkMerge (map (p: p.sops.secrets) parts);
      sops.templates = lib.mkMerge (map (p: p.sops.templates) parts);
      systemd.services = lib.mkMerge (map (p: p.systemd.services) parts);
      systemd.tmpfiles.rules = lib.concatMap (p: p.systemd.tmpfiles.rules) parts;

      # Route each app through Caddy. The Caddy route only needs the logical
      # name, never the image or repository.
      web.sites = lib.mapAttrs' (name: app:
        lib.nameValuePair "app-${name}" {
          upstream = "http://127.0.0.1:${toString app.port}";
          inherit (app) access;
        })
      cfg;
    });
  };
}
