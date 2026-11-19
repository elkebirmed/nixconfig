# ============================================================================
# Fish
# Shell defaults and persistence across root rollbacks.
# ============================================================================
_: {
  den.aspects.fish = {user, ...}: {
    homePersistence = {
      inherit (user) userName;
      directories = [".local/share/fish"];
    };

    homeManager = {
      programs.fish = {
        # Prefer abbreviations when other modules offer both.
        preferAbbrs = true;

        interactiveShellInit = ''
          set -g fish_greeting
        '';
      };
    };
  };
}
