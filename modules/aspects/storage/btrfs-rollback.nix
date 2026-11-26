# ============================================================================
# Btrfs Rollback
# Recreate an empty "root" subvolume on every boot, before it becomes sysroot.
#
# Runs as a systemd unit in the initrd, hence `boot.initrd.systemd.enable`.
# Depends on the layout from disko-btrfs.nix (subvolume "/root" on partition
# "root").
# ============================================================================
_: {
  # Run rollback in the initrd before the root subvolume is mounted.
  den.aspects.btrfs-rollback.nixos = {
    config,
    pkgs,
    utils,
    ...
  }: let
    # Wait for the disk device that Disko assigns to the Btrfs root partition.
    device = config.disko.devices.disk.main.content.partitions.root.device;
    deviceUnit = "${utils.escapeSystemdPath device}.device";
  in {
    boot.initrd = {
      supportedFilesystems = ["btrfs"];
      systemd = {
        # Provide Btrfs tools early and enable systemd-based initrd units.
        initrdBin = [pkgs.btrfs-progs pkgs.coreutils pkgs.findutils];

        services.rollback-root = {
          # Run after the disk appears and before sysroot.mount.
          description = "Reset btrfs root subvolume to a blank state";
          wantedBy = ["initrd.target"];
          requires = [deviceUnit];
          after = [deviceUnit];
          before = ["sysroot.mount"];
          unitConfig.DefaultDependencies = "no";
          serviceConfig.Type = "oneshot";
          script = ''
            # Mount the top-level Btrfs tree so the root subvolume can be replaced.
            set -eu
            mkdir -p /mnt
            mount -t btrfs -o subvolid=5 ${device} /mnt

            delete_subvolume_recursively() {
              # Delete nested subvolumes first; Btrfs refuses to remove a non-empty parent.
              btrfs subvolume list -o "$1" | while read -r _ _ _ _ _ _ _ _ sub; do
                delete_subvolume_recursively "/mnt/$sub"
              done
              btrfs subvolume delete "$1"
            }

            # Move the previous root aside instead of deleting it outright, so a
            # bad boot can be inspected. Btrfs cannot rename across the
            # top-level, so a snapshot is created at the new name first.
            if [ -e /mnt/root ]; then
              mkdir -p /mnt/old_roots
              stamp=$(date -u +%Y%m%dT%H%M%SZ)
              btrfs subvolume snapshot /mnt/root "/mnt/old_roots/$stamp"
              delete_subvolume_recursively /mnt/root
            fi
            btrfs subvolume create /mnt/root

            # Keep two weeks of previous roots; drop older snapshot subvolumes
            # recursively so their nested subvolumes go too.
            find /mnt/old_roots -mindepth 1 -maxdepth 1 -type d -mtime +14 2>/dev/null |
              while read -r old; do
                delete_subvolume_recursively "$old"
              done

            umount /mnt
          '';
        };
      };
    };
  };
}
