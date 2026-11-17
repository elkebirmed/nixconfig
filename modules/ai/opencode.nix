# ============================================================================
# Opencode
# ============================================================================
_: {
  den.aspects.opencode = {user, ...}: {
    homePersistence = {
      inherit (user) userName;
      directories = [".local/state/opencode"];
    };

    homeManager.programs.opencode = {
      enable = true;
    };
  };
}
