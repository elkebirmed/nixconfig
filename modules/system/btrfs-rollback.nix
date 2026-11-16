# ============================================================================
# Recreate an empty "root" subvolume on every boot, once the partition is
# available and before it is mounted as /sysroot. Runs as a systemd unit in
# the initrd, hence `boot.initrd.systemd.enable`.
# Depends on the layout from disko.nix (subvolume "/root" on partition "root").
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
        initrdBin = [pkgs.btrfs-progs];

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

            # Recreate an empty root every boot; /nix, /persist, and /var/log
            # live in independent subvolumes and are left intact.
            if [ -e /mnt/root ]; then
              delete_subvolume_recursively /mnt/root
            fi
            btrfs subvolume create /mnt/root

            umount /mnt
          '';
        };
      };
    };
  };
}
