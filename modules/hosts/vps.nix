# ============================================================================
# VPS Host
# OVH VPS-1: BIOS boot, a single ext4 disk, public web, and a private
# tailnet. OpenClaw stays on loopback and talks to the Command Code Provider
# API over HTTPS; there is no local model gateway.
# ============================================================================
{den, ...}: {
  den.hosts.x86_64-linux.vps = {
    disk.device = "/dev/sda";

    # Static WAN IPv6. The committed defaults are placeholders; set the real
    # address and gateway here (locally, from a private overlay) and never
    # commit them. See modules/aspects/server/network.nix.
    network.v6 = {
      # address = "REDACTED_IPV6";
      # gateway = "REDACTED_IPV6_GATEWAY";
    };

    # Public SSH is closed; only the tailnet reaches port 22.
    ssh.interfaces = ["tailscale0"];

    # The VPS keeps its host key on the normal system path.
    ssh.hostKeyPath = "/etc/ssh/ssh_host_ed25519_key";

    users.ops = {};
    users.claw = {};
  };

  den.aspects.vps = {
    includes = [
      den.aspects.boot-bios
      den.aspects.disko-bios
      den.aspects.zram
      den.aspects.locale
      den.aspects.sops
      den.aspects.firewall
      den.aspects.network-vps
      den.aspects.tailscale
      den.aspects.web
      den.aspects.site-example
      # Container platform: Quadlet is the single declarative container path.
      den.aspects.quadlet
      # Runtime-only Quadlet units for applications with private images.
      den.aspects.private-app
      # Observability and backups, sized for this single node.
      den.aspects.monitoring
      den.aspects.backups
      den.aspects.server-nix
      den.aspects.server-misc
    ];

    nixos = {
      # Host secrets live next to the host definition.
      sops.defaultSopsFile = ../../secrets/hosts/vps.yaml;

      # `ops` is the only interactive account; passwordless sudo is expected.
      security.sudo.wheelNeedsPassword = false;
    };

    nixos.imports = [./vps/_nixos/hardware-configuration.nix];
  };
}
