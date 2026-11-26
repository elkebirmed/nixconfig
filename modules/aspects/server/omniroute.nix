# ============================================================================
# OmniRoute VPS
# Self-hosted AI gateway for the VPS, bound to loopback.
#
# The gateway key is owned by the OpenClaw user; provider credentials come from
# the host SOPS file. Caddy reaches it over the tailnet as a tailnet-only site.
# ============================================================================
_: {
  den.aspects.omniroute-vps.nixos = {
    imports = [
      (import ../ai/_omniroute-lib.nix {
        sopsFile = ../../../secrets/hosts/vps.yaml;
        owner = "claw";
        keyName = "openclaw";
        # VPS root is persistent ext4 (no Impermanence), so the data and
        # bootstrap dirs are created by tmpfiles rather than a bind mount.
        useImpermanence = false;
        # Server containers go through Quadlet: one declarative path.
        useQuadlet = true;
      })
    ];

    web.sites.omniroute = {
      upstream = "http://127.0.0.1:20128";
    };
  };
}
