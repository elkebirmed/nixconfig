# ============================================================================
# Fonts
# System font set: Noto coverage, emoji, Nerd Font symbols, and Rubik.
#
# ============================================================================
_: {
  den.aspects.fonts.nixos = {pkgs, ...}: {
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      dejavu_fonts
      liberation_ttf
      nerd-fonts.symbols-only
      maple-mono.NF-CN
      rubik
    ];

    fonts.fontconfig.defaultFonts = {
      serif = ["Rubik" "Noto Serif"];
      sansSerif = ["Rubik" "Noto Sans"];
      monospace = ["Maple Mono NF CN" "Noto Sans Mono"];
      emoji = ["Noto Color Emoji"];
    };
  };
}
