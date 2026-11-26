# ============================================================================
# Network VPS
# systemd-networkd with DHCPv4 and a static IPv6 address.
#
# OVH assigns a /128 IPv6 address with an on-link gateway, so the gateway
# route must be marked on-link explicitly.
#
# The real address is an infrastructure identifier and is therefore NOT kept in
# this public repository. It is supplied through host options whose defaults are
# placeholders. This is a documented, deliberate exception to the runtime-secret
# boundary: the address is needed by systemd-networkd at boot, before SOPS has
# decrypted anything, so it cannot be rendered into /run at activation time.
# Supply the real values locally (or from a private overlay) and never commit
# them. See README "Network address handling".
# ============================================================================
_: {
  den.schema.host = {lib, ...}: {
    options.network.v6 = {
      address = lib.mkOption {
        type = lib.types.str;
        default = "REDACTED_IPV6";
        example = "REDACTED_IPV6";
        description = ''
          Static IPv6 address (without prefix length) for the VPS WAN link.
          The committed default is a placeholder; set the real address locally.
        '';
      };

      prefixLength = lib.mkOption {
        type = lib.types.ints.between 1 128;
        default = 64;
        description = ''
          Prefix length applied to `network.v6.address`. OVH's IPv6 network is
          a /64; using /64 makes the gateway on-link.
        '';
      };

      gateway = lib.mkOption {
        type = lib.types.str;
        default = "REDACTED_IPV6_GATEWAY";
        example = "REDACTED_IPV6_GATEWAY";
        description = ''
          On-link IPv6 gateway for the VPS WAN link. The committed default is a
          placeholder; set the real address locally.
        '';
      };
    };
  };

  den.aspects.network-vps.nixos = {host, ...}: {
    networking.useNetworkd = true;
    networking.useDHCP = false;

    systemd.network = {
      enable = true;

      networks."10-wan" = {
        matchConfig.Name = "ens3";

        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = false;
        };

        address = ["${host.network.v6.address}/${toString host.network.v6.prefixLength}"];

        routes = [
          {
            Destination = "::/0";
            Gateway = host.network.v6.gateway;
          }
        ];

        linkConfig.RequiredForOnline = "routable";
      };
    };
  };
}
