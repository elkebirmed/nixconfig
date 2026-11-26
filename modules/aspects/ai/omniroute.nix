# ============================================================================
# OmniRoute
# Self-hosted AI gateway with SOPS-managed provider credentials.
#
# This user-owned instance keeps its secrets in the owning user's SOPS file.
# The VPS variant lives in `modules/aspects/server/omniroute.nix`.
# ============================================================================
_: {
  den.aspects.omniroute = {user, ...}: {
    provides.to-hosts.nixos = import ./_omniroute-lib.nix {
      sopsFile = ../../../secrets/users + "/${user.userName}.yaml";
      owner = user.userName;
      useImpermanence = true;
    };
  };
}
