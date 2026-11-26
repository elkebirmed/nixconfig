# ============================================================================
# Backups
# Restic backups of application state to a private, operator-supplied target.
#
# Design notes:
#   * The repository location and password are read at RUNTIME from SOPS-rendered
#     files (`/run/restic/*`). Neither the destination nor the password is ever a
#     Nix store literal, and the destination is an infrastructure identifier.
#   * Disabled by default. Enabling a backup before the owner provides the
#     secret names in docs/vps.md "Owner actions" would create a timer that fails
#     every night, so activation stays inert until then.
#   * Container image storage is deliberately excluded: images are re-pulled
#     from pinned digests, so backing them up wastes the small disk.
#   * A backup that has never been restore-tested is not a backup. See
#     docs/vps.md for the restore drill; this module only schedules and prunes.
# ============================================================================
_: {
  den.aspects.backups.nixos = {
    config,
    lib,
    ...
  }: let
    cfg = config.vps.backups;

    # Application state worth restoring. Each entry is a real data directory
    # owned by its service; caches and container layers are excluded.
    backupPaths = [
      # OpenClaw workspace/sessions (assistant state).
      "/home/claw/.openclaw"
      # Monitoring state.
      "/var/lib/grafana"
      "/var/lib/prometheus"
      # Identity that must not be regenerated on restore.
      "/var/lib/tailscale"
      "/etc/ssh"
    ];
  in {
    options.vps.backups = {
      enable = lib.mkEnableOption ''
        nightly restic backups of application state. Requires the
        `restic-repository` and `restic-password` secrets in the VPS host
        secrets file; leave disabled until those exist
      '';

      schedule = lib.mkOption {
        type = lib.types.str;
        default = "02:30";
        description = "Local time (HH:MM) for the nightly backup.";
      };
    };

    config = lib.mkIf cfg.enable {
      sops.secrets."restic-password" = {
        sopsFile = ../../../secrets/hosts/vps.yaml;
        mode = "0400";
      };

      # The repository string is an infrastructure identifier, so it is a
      # secret too. `services.restic` accepts `repositoryFile` at runtime.
      sops.secrets."restic-repository" = {
        sopsFile = ../../../secrets/hosts/vps.yaml;
        mode = "0400";
      };

      services.restic.backups.appdata = {
        repositoryFile = config.sops.secrets."restic-repository".path;
        passwordFile = config.sops.secrets."restic-password".path;

        paths = backupPaths;

        # Skip regenerable or high-churn data inside the preserved trees.
        exclude = [
          "/home/claw/.openclaw/logs"
          "/home/claw/.cache"
          "*.log"
        ];

        initialize = true;

        timerConfig = {
          OnCalendar = cfg.schedule;
          Persistent = true;
          # Spread load and avoid thundering herd with other timers.
          RandomizedDelaySec = "15m";
        };

        # Keep two weeks daily and two months weekly: proportionate for a
        # single small VPS.
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 2"
        ];

        extraBackupArgs = ["--compression max"];
      };
    };
  };
}
