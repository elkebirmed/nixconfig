# ============================================================================
# Crazy Host
# Host-specific settings for the `crazy` aspect.
# ============================================================================
{den, ...}: {
  den.hosts.x86_64-linux.crazy = {
    disk.device = "/dev/sda";

    # Only the wired and Wi-Fi LAN interfaces carry SSH; nothing else does.
    ssh.interfaces = ["enp9s0" "wlp8s0"];
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
      den.aspects.networking
      den.aspects.firewall
      den.aspects.tailscale
      den.aspects.openssh
      den.aspects.audio
      den.aspects.graphics
      den.aspects.fonts
      den.aspects.session
      den.aspects.desktop-cache
      den.aspects.niri
      den.aspects.polkit-keyring
      den.aspects.display-manager
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
