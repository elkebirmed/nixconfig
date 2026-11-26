# ============================================================================
# Disko Btrfs
# GPT disk with an EFI system partition and Btrfs subvolumes.
# ============================================================================
{inputs, ...}: {
  # Add the disko input.
  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Declare a typed host setting so missing or malformed disk paths are caught
  # while evaluating the Den host metadata.
  den.schema.host = {lib, ...}: {
    options.disk.device = lib.mkOption {
      type = lib.types.str;
      example = "/dev/nvme0n1";
      description = "Whole-disk device to partition with disko.";
    };
  };

  # Build a GPT disk with an EFI partition and separate Btrfs subvolumes.
  den.aspects.disko-btrfs = {host, ...}: let
    # Use the same compression and access-time policy for each Btrfs mount.
    mountOptions = [
      "compress=zstd"
      "noatime"
    ];
    subvolume = mountpoint: {inherit mountpoint mountOptions;};
  in {
    nixos = {
      # Import Disko's NixOS module before declaring its disk schema.
      imports = [inputs.disko.nixosModules.disko];

      # Partition the host's configured disk and mount the system subvolumes.
      disko.devices.disk.main = {
        type = "disk";
        device = host.disk.device;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              # The EFI System Partition is mounted with restrictive defaults.
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };
            root = {
              # The remaining disk space backs the Btrfs system subvolumes.
              size = "100%"; # -> /dev/disk/by-partlabel/disk-main-root
              content = {
                type = "btrfs";
                extraArgs = [
                  "-f"
                  "-L"
                  "nixos"
                ];
                subvolumes = {
                  # Root is recreated during initrd; these other mounts persist.
                  "/root" = subvolume "/"; # wiped on every boot (btrfs-rollback.nix)
                  "/nix" = subvolume "/nix";
                  "/persist" = subvolume "/persist"; # survives reboots (impermanence.nix)
                  "/log" = subvolume "/var/log";
                };
              };
            };
          };
        };
      };

      # Make persistent state and logs available to initrd services.
      fileSystems = {
        # Needed before root is mounted so rollback and persistence can run.
        "/persist".neededForBoot = true;
        "/var/log".neededForBoot = true;
      };
    };
  };
}
