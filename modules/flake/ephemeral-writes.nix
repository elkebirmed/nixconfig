# ============================================================================
# Ephemeral Writes
# List files written to the ephemeral root since boot, so missing persistence
# is easy to find. Exposed as `nix run .#ephemeral-writes`.
#
# Paths that already live on a persistent mount (/persist, /nix, /boot,
# /var/log) or in a mount point are skipped: only what would be lost on the
# next rollback is reported.
# ============================================================================
_: {
  perSystem = {pkgs, ...}: {
    packages.ephemeral-writes = pkgs.writeShellApplication {
      name = "ephemeral-writes";

      # `find -quit` gates on the privileges for reading the ephemeral root.
      runtimeInputs = with pkgs; [coreutils findutils gawk];
      text = ''
        set -euo pipefail

        # Files changed since boot, excluding persistent mounts and pseudo
        # filesystems. `btime` is the kernel boot timestamp in epoch seconds.
        boot_time=$(awk '/^btime/ { print $2 }' /proc/stat)
        find / \
          -xdev \
          -newermt "@$boot_time" \
          \( -path /proc -o -path /sys -o -path /dev -o -path /run -o -path /tmp \
             -o -path /persist -o -path /nix -o -path /boot -o -path /var/log \
             -o -path /old_roots \) -prune \
          -o -type f -print 2>/dev/null |
          sort
      '';
    };
  };
}
