# ============================================================================
# Niri Pro
# Full Niri profile: named workspaces, window and layer rules, overview
# tuning, the recent-windows switcher, and the desktop action binds.
#
# Merged on top of `niri-base` for users whose `desktopProfile` is `full`.
# Noctalia owns the launcher, session menu, screenshots, recording, and the
# system toggles; the binds here drive it over IPC.
# ============================================================================
_: {
  den.aspects.niri-pro.homeManager = {
    lib,
    config,
    pkgs,
    ...
  }: let
    noctaliaPackage =
      config.programs.noctalia.package
      or (throw "niri-pro requires the noctalia aspect");

    noctaliaExe = lib.getExe noctaliaPackage;
    kittyExe = lib.getExe pkgs.kitty;

    # Noctalia IPC helper.
    msg = args: [noctaliaExe "msg"] ++ args;
  in {
    programs.niri.settings = {
      input = {
        keyboard.xkb = {
          layout = "us,ara";
          options = "caps:none,grp:alt_shift_toggle,compose:ralt";
        };
      };

      layout = {
        preset-column-widths = [
          {proportion = 1.0 / 3.0;}
          {proportion = 1.0 / 2.0;}
          {proportion = 2.0 / 3.0;}
        ];

        default-column-width = {proportion = 1.0 / 2.0;};
      };

      prefer-no-csd = true;

      # ----------------------------------------------------------------------
      # Named workspaces
      # ----------------------------------------------------------------------
      workspaces = {
        "1-main" = {name = "main";};
        "2-web" = {name = "web";};
        "3-code" = {name = "code";};
        "4-media" = {name = "media";};
        "5-chat" = {name = "chat";};
        "6-misc" = {name = "misc";};
      };

      # ----------------------------------------------------------------------
      # Workspace and session binds
      # ----------------------------------------------------------------------
      binds = {
        # Vim-style focus and the floating/tiling toggle live in the full
        # profile only: `Mod+H/J/K/L` and `Mod+Space` would otherwise collide
        # with the simple profile's `Mod+L` lock and `Mod+Space` overview.
        "Mod+H".action.focus-column-left = [];
        "Mod+J".action.focus-window-or-workspace-down = [];
        "Mod+K".action.focus-window-or-workspace-up = [];
        "Mod+L".action.focus-column-right = [];

        "Mod+Ctrl+H".action.move-column-left = [];
        "Mod+Ctrl+L".action.move-column-right = [];
        "Mod+Ctrl+K".action.move-window-up-or-to-workspace-up = [];
        "Mod+Ctrl+J".action.move-window-down-or-to-workspace-down = [];

        "Mod+Shift+H".action.focus-monitor-left = [];
        "Mod+Shift+L".action.focus-monitor-right = [];
        "Mod+Shift+K".action.focus-monitor-up = [];
        "Mod+Shift+J".action.focus-monitor-down = [];

        "Mod+Space".action.switch-focus-between-floating-and-tiling = [];

        "Mod+1".action.focus-workspace = ["main"];
        "Mod+2".action.focus-workspace = ["web"];
        "Mod+3".action.focus-workspace = ["code"];
        "Mod+4".action.focus-workspace = ["media"];
        "Mod+5".action.focus-workspace = ["chat"];
        "Mod+6".action.focus-workspace = ["misc"];

        "Mod+Ctrl+1".action.move-column-to-workspace = ["main"];
        "Mod+Ctrl+2".action.move-column-to-workspace = ["web"];
        "Mod+Ctrl+3".action.move-column-to-workspace = ["code"];
        "Mod+Ctrl+4".action.move-column-to-workspace = ["media"];
        "Mod+Ctrl+5".action.move-column-to-workspace = ["chat"];
        "Mod+Ctrl+6".action.move-column-to-workspace = ["misc"];

        # --------------------------------------------------------------------
        # Launcher, clipboard, session, and shell actions
        # --------------------------------------------------------------------
        "Mod+T".action.spawn = [kittyExe];
        "Mod+Return".action.spawn = [kittyExe];
        "Mod+D".action.spawn = msg ["panel-toggle" "launcher"];
        "Mod+V".action.spawn = msg ["panel-toggle" "clipboard"];
        "Mod+Escape".action.spawn = msg ["panel-toggle" "session"];
        "Mod+Alt+L".action.spawn = msg ["session" "lock"];
        "Mod+O".action.toggle-overview = [];
        "Mod+Shift+Slash".action.show-hotkey-overlay = [];
        "Mod+Shift+C".action.spawn = msg ["config-reload"];

        # System toggles.
        "Mod+Shift+N".action.spawn = msg ["notification-dnd-toggle"];
        "Mod+Shift+P".action.spawn = msg ["caffeine-toggle"];
        "Mod+Shift+I".action.spawn = msg ["nightlight-toggle"];

        # --------------------------------------------------------------------
        # Screenshot suite
        # --------------------------------------------------------------------
        "Print".action.spawn = msg ["screenshot-region" "--annotate"];
        "Mod+Print".action.spawn = msg ["screenshot-fullscreen"];
        "Mod+Shift+Print".action.spawn = msg ["screenshot-window"];
        "Mod+Alt+Print".action.spawn = msg ["screenshot-fullscreen" "all"];
        "Ctrl+Print".action.screenshot-screen = [];
        "Alt+Print".action.screenshot-window = [];

        # --------------------------------------------------------------------
        # Screen recording (Noctalia screen_recorder plugin)
        # --------------------------------------------------------------------
        "Mod+Shift+Grave".action.spawn =
          msg ["plugin" "noctalia/screen_recorder:service" "all" "toggle"];
        "Mod+Alt+Grave".action.spawn =
          msg ["plugin" "noctalia/screen_recorder:service" "all" "replay-toggle"];

        # --------------------------------------------------------------------
        # Window switcher
        # --------------------------------------------------------------------
        "Alt+Tab".action.spawn = msg ["window-switcher" "hold"];
        "Alt+Shift+Tab".action.spawn = msg ["window-switcher" "hold" "reverse"];
        "Mod+Tab".action.spawn = msg ["window-switcher"];
      };

      # ----------------------------------------------------------------------
      # Window rules
      # ----------------------------------------------------------------------
      window-rules = [
        # Dialogs always float and center themselves.
        {
          matches = [{is-floating = true;}];
          geometry-corner-radius = 12.0;
        }

        # Common settings and connection dialogs float, unmanaged by the tiler.
        {
          matches = [
            {app-id = "^org\\.pulseaudio\\.pavucontrol$";}
            {app-id = "^nm-connection-editor$";}
          ];
          open-floating = true;
          default-column-width = {fixed = 800;};
          default-window-height = {fixed = 600;};
        }

        # File pickers land as a sensible floating window.
        {
          matches = [{title = "^(Open File|Open Folder|Save File|File Upload)$";}];
          open-floating = true;
        }

        # Password managers are never shown in screencasts.
        {
          matches = [
            {app-id = "^org\\.keepassxc\\.KeePassXC$";}
            {app-id = "^(.*bitwarden.*|.*Bitwarden.*)$";}
          ];
          block-out-from = "screencast";
        }
      ];

      # ----------------------------------------------------------------------
      # Layer rules: blur, shadows, and rounded corners for Noctalia surfaces
      # ----------------------------------------------------------------------
      layer-rules = [
        {
          matches = [
            {namespace = "^noctalia-(bar|dock|panel|attached-panel)$";}
          ];
          background-effect.blur = true;
          geometry-corner-radius = 16.0;
        }
        {
          matches = [{namespace = "^noctalia-(osd|notification|wallpaper|window-switcher)$";}];
          background-effect.blur = true;
        }
      ];

      # ----------------------------------------------------------------------
      # Overview tuning
      # ----------------------------------------------------------------------
      overview = {
        zoom = 0.5;
        workspace-shadow.enable = true;
      };

      # ----------------------------------------------------------------------
      # Recent windows (Alt-Tab)
      # ----------------------------------------------------------------------
      recent-windows = {
        enable = true;
        debounce-ms = 500;
        previews = {
          max-height = 480;
          max-scale = 0.5;
        };
      };
    };
  };
}
