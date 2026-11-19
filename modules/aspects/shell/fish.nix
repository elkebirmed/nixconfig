# ============================================================================
# Fish
# Persist the Fish data directory across root rollbacks.
# ============================================================================
_: {
  den.aspects.fish = {user, ...}: {
    homePersistence = {
      inherit (user) userName;
      directories = [".local/share/fish"];
    };
  };
}
