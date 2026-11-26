# ============================================================================
# Kitty
# Kitty terminal using Maple Mono NF CN, with Fish shell integration.
#
# Colors are rendered by Noctalia into kitty-colors.conf and pulled in through
# `extraConfig`; the file is optional at startup.
# ============================================================================
_: {
  den.aspects.kitty.homeManager = {pkgs, ...}: {
    programs.kitty = {
      enable = true;

      font = {
        package = pkgs.maple-mono.NF-CN;
        name = "Maple Mono NF CN";
        size = 11;
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

        background_opacity = "0.90";
        cursor_trail = 10;
        cursor_trail_start_threshold = 0;
        cursor_trail_decay = "0.01 0.15";
      };

      extraConfig = ''
        include ~/.config/kitty/kitty-colors.conf
      '';
    };
  };
}
