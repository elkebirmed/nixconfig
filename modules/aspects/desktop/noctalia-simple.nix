# ============================================================================
# Noctalia Simple
# Windows-like Noctalia profile: a large bottom dock with a minimal bar.
#
# Merged on top of `noctalia` for users whose `desktopProfile` is `simple`.
# Keeps notifications, clipboard, and lock/idle behavior from the base while
# dropping the pro-only widgets and services.
# ============================================================================
_: {
  den.aspects.noctalia-simple.homeManager = {
    programs.noctalia.settings = {
      shell.launcher = {
        layout = "simple";
        default_view = "all";
        categories = true;
      };

      # ----------------------------------------------------------------------
      # Minimal bar
      # ----------------------------------------------------------------------
      bar.main = {
        position = "top";
        thickness = 34;
        background_opacity = 0.9;
        compositor_blur = true;
        radius = 12;
        shadow = true;

        start = ["launcher"];
        center = ["clock"];
        end = ["tray" "volume" "network" "battery" "session"];
      };

      # ----------------------------------------------------------------------
      # Windows-like dock
      # ----------------------------------------------------------------------
      dock = {
        enabled = true;
        position = "bottom";
        icon_size = 56;
        magnification = true;
        magnification_scale = 1.3;
        show_running = true;
        show_instance_count = true;
        launcher_position = "start";
        auto_hide = true;

        # Browser, files, settings, office, and media. No terminal: the
        # simple profile is deliberately app-driven.
        pinned = [
          "zen-beta"
          "org.gnome.Nautilus"
          "org.gnome.Settings"
          "startcenter"
          "mpv"
        ];
      };

      # Wallpaper rotation over the shared wallpaper set, so the simple
      # profile has a lived-in desktop without palette management.
      wallpaper = {
        enabled = true;
        fill_mode = "crop";
        transition_duration = 1500;
        automation = {
          enabled = true;
          interval_seconds = 1800;
          order = "random";
          recursive = true;
        };
      };
    };
  };
}
