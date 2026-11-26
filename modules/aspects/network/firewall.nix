# ============================================================================
# Firewall
# Default-deny inbound firewall with SSH reachable.
# ============================================================================
_: {
  den.aspects.firewall.nixos = {host, ...}: let
    sshInterfaces = host.ssh.interfaces;
  in {
    # Use nftables as the backend; the firewall module rewrites its ruleset.
    networking.nftables.enable = true;

    networking.firewall = {
      enable = true;

      # SSH is the only service that must accept connections from the network.
      # When `ssh.interfaces` is set, only those interfaces reach port 22 so a
      # Wi-Fi or VPN outage never exposes it on every network at once.
      allowedTCPPorts =
        if sshInterfaces == []
        then [22]
        else [];
      interfaces =
        if sshInterfaces == []
        then {}
        else
          builtins.listToAttrs (map (name: {
              inherit name;
              value.allowedTCPPorts = [22];
            })
            sshInterfaces);

      # Podman bridges and the veth setup make strict reverse-path filtering
      # drop legitimate traffic.
      checkReversePath = "loose";
    };
  };
}
