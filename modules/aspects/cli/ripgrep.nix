# ============================================================================
# Ripgrep
# ripgrep with sensible search defaults.
# ============================================================================
_: {
  den.aspects.ripgrep.homeManager = {
    programs.ripgrep = {
      enable = true;

      # ripgrep reads these through RIPGREP_CONFIG_PATH.
      arguments = [
        "--smart-case"
        "--hidden"
        "--glob=!.git/*"
      ];
    };
  };
}
