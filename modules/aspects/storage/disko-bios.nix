# ============================================================================
# Disko BIOS
# GPT disk with a BIOS boot partition and a persistent ext4 root.
# ============================================================================
{inputs, ...}: {
  den.aspects.disko-bios = {host, ...}: {
    nixos = {
      # Import Disko's NixOS module before declaring its disk schema.
      imports = [inputs.disko.nixosModules.disko];

      disko.devices.disk.main = {
        type = "disk";
        device = host.disk.device;
        content = {
          type = "gpt";
          partitions = {
            # GRUB needs a BIOS boot partition on a GPT disk.
            bios = {
              size = "1M";
              type = "EF02";
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
