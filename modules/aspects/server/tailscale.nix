# ============================================================================
# Tailscale
# Tailnet connectivity with a SOPS-managed auth key.
# ============================================================================
_: {
  den.aspects.tailscale = {
    # Keep the node identity across root rollbacks on impermanent hosts.
    # NOTE: this only takes effect on hosts that include `impermanence`
    # (currently `crazy`). The `vps` host uses a persistent ext4 root and has no
    # Impermanence aspect, so this entry is inert there — its state survives
    # because the whole root is persistent, not because of this line.
    systemPersistence.directories = ["/var/lib/tailscale"];

    nixos = {config, ...}: {
      services.tailscale = {
        enable = true;
        authKeyFile = config.sops.secrets."tailscale-auth-key".path;
        openFirewall = true;
      };

      # Tailnet traffic is trusted; public services are opened explicitly.
      networking.firewall.trustedInterfaces = ["tailscale0"];

      # A switch must never bounce the tunnel: it would drop the SSH session
      # and every tailnet-only service. The daemon still starts normally.
      systemd.services.tailscaled.restartIfChanged = false;

      sops.secrets."tailscale-auth-key" = {
        # Each host keeps its own auth key in its own host secrets file.
        sopsFile = config.sops.defaultSopsFile;
        mode = "0400";
      };
    };
  };
}
