# ============================================================================
# Crazy Host
# Host-specific settings for the `crazy` aspect.
# ============================================================================
{den, ...}: {
  den.hosts.x86_64-linux.crazy = {
    disk.device = "/dev/sda";
  };

  den.aspects.crazy = {
    includes = [
      den.aspects.boot
      den.aspects.disko-btrfs
      den.aspects.btrfs-rollback
      den.aspects.zram
      den.aspects.impermanence
      den.aspects.locale
      den.aspects.maintenance
      den.aspects.nix-daemon
      den.aspects.sops
      den.aspects.git
      den.aspects.networking
      den.aspects.openssh
      den.aspects.dev-tools
      den.aspects.podman
    ];

    nixos = {
      time.timeZone = "Africa/Algiers";

      # Host-scoped secrets live next to the host definition.
      sops.defaultSopsFile = ../../secrets/hosts/crazy.yaml;
    };

    nixos.imports = [./crazy/_nixos/hardware-configuration.nix];
  };
}
