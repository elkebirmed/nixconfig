# ============================================================================
# Kids User
# The kids account: identity plus locked-down managed-user wiring.
#
# No terminal, no Nix access (never a wheel member), and no rootless Podman.
# TODO: Add DNS filtering, parental controls, and other kid-friendly features.
# ============================================================================
{den, ...}: {
  den.aspects.kids = {
    user = {
      description = "Kids";

      # No SSH access.
      openssh.authorizedKeys.keys = [];
    };

    includes = [
      den.aspects.managed-user
      den.aspects.persisted-state
    ];

    nixos = {lib, ...}: {
      # Rootless Podman needs subordinate UID/GID ranges; without them the
      # account cannot create a user namespace or start a container.
      users.users.kids = {
        autoSubUidGidRange = false;
        subUidRanges = lib.mkForce [];
        subGidRanges = lib.mkForce [];
      };
    };

    homeManager = {lib, ...}: {
      # A terminal is a development tool here, so the kids desktop has none.
      # Everything else (browser, office, media, shell) comes from
      # `desktop-apps`; only the terminal is removed.
      programs.kitty.enable = lib.mkForce false;
    };
  };
}
