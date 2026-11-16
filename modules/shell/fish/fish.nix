# ============================================================================
# Fish Shell
# ============================================================================
_: {
  den.aspects.fish = {user, ...}: {
    homePersistence = {
      inherit (user) userName;
      directories = [".local/share/fish"];
    };
  };
}
