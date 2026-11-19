# ============================================================================
# Kitty
# Kitty terminal using Maple Mono NF CN, with Fish shell integration.
# ============================================================================
_: {
  den.aspects.kitty.homeManager = {pkgs, ...}: {
    programs.kitty = {
      enable = true;

      font = {
        package = pkgs.maple-mono.NF-CN;
        name = "Maple Mono NF CN";
        size = 12;
      };

      shellIntegration.enableFishIntegration = true;

      settings = {
        shell = "${pkgs.fish}/bin/fish";
        confirm_os_window_close = 0;
        enable_audio_bell = false;
        update_check_interval = 0;
        scrollback_lines = 10000;
        window_padding_width = 8;
        cursor_shape = "beam";
        cursor_blink_interval = 0;
      };
    };
  };
}
