# ============================================================================
# Maple Mono NF CN
# Install the Nerd Font build of Maple Mono and make it the default monospace.
# ============================================================================
_: {
  den.aspects.maple-mono.homeManager = {pkgs, ...}: {
    fonts.fontconfig = {
      enable = true;
      defaultFonts.monospace = ["Maple Mono NF CN"];
    };

    home.packages = [pkgs.maple-mono.NF-CN];
  };
}
