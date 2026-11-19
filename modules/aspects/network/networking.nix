# ============================================================================
# Networking
# NetworkManager host networking with persistent connection profiles.
# ============================================================================
_: {
  den.aspects.networking = {
    # Keep saved Wi-Fi and VPN profiles across root rollbacks.
    systemPersistence.directories = ["/etc/NetworkManager/system-connections"];

    # Use NetworkManager for host network configuration.
    nixos.networking.networkmanager.enable = true;
  };
}
