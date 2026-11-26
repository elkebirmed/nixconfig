# ============================================================================
# Prompt
# Starship prompt, zoxide, and direnv integration for Fish.
#
# Starship's `starship.toml` is rendered by Noctalia, so only the package and
# the shell hook are configured here. zoxide's `--cmd cd` is left off so `cd`
# keeps its usual behavior.
# ============================================================================
_: {
  den.aspects.prompt.homeManager = {
    programs.starship = {
      enable = true;
      enableFishIntegration = true;
    };

    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      silent = true;
    };
  };
}
