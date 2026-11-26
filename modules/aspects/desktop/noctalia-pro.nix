# ============================================================================
# Noctalia Pro
# Full Noctalia profile: complete bar, magnifying dock, system monitor,
# control-center shortcuts, weather and calendar, wallpaper automation, night
# light, audio polish, hooks, and the screen-recorder plugin.
#
# Merged on top of `noctalia` for users whose `desktopProfile` is `full`.
# ============================================================================
{inputs, ...}: {
  # Pin the official plugin repository so the recorder follows flake.lock
  # instead of being fetched at runtime.
  flake-file.inputs.noctalia-plugins = {
    url = "github:noctalia-dev/official-plugins";
    flake = false;
  };

  # The community plugins (`color_picker`, `keybind-cheatsheet`) are pinned the
  # same way. Noctalia's `git` source kind has no rev field, so a `path` source
  # backed by this input is the only way to make them reproducible.
  flake-file.inputs.noctalia-community-plugins = {
    url = "github:noctalia-dev/community-plugins";
    flake = false;
  };

  den.aspects.noctalia-pro.homeManager = _: {
    programs.noctalia.settings = {
      shell = {
        launcher = {
          layout = "full";
          default_view = "recent";
          show_settings_button = true;
          show_session_button = true;

          providers = {
            calculator = {
              prefix = "calc";
              global = true;
            };
            emoji.prefix = "emo";
            session.prefix = "session";
            wallpaper.prefix = "wall";
            windows.prefix = "win";
          };
        };

        window_switcher = {
          style = "carousel";
          mru = true;
          show_caption = true;
          show_app_icon = true;
        };

        # Type-to-launch from the niri overview.
        niri_overview_type_to_launch_enabled = true;
      };

      # ----------------------------------------------------------------------
      # Full bar layout
      # ----------------------------------------------------------------------
      bar.main = {
        position = "top";
        thickness = 34;
        background_opacity = 0.85;
        compositor_blur = true;
        radius = 12;
        capsule = true;
        shadow = true;

        start = ["launcher" "wallpaper" "workspaces"];
        center = ["clock"];
        end = [
          "media"
          "tray"
          "notifications"
          "clipboard"
          "network"
          "bluetooth"
          "volume"
          "brightness"
          "battery"
          "sysmon"
          "control-center"
          "session"
        ];
      };

      # ----------------------------------------------------------------------
      # Dock
      # ----------------------------------------------------------------------
      dock = {
        enabled = false;
      };

      # ----------------------------------------------------------------------
      # Control center
      # ----------------------------------------------------------------------
      control_center = {
        show_session_button = true;
        media.show_visualizer = true;
        shortcuts = [
          {type = "wifi";}
          {type = "bluetooth";}
          {type = "nightlight";}
          {type = "notification";}
          {type = "caffeine";}
          {type = "session";}
        ];
      };

      # ----------------------------------------------------------------------
      # Weather and calendar
      # ----------------------------------------------------------------------
      weather = {
        enabled = true;
        unit = "celsius";
        effects = true;
      };

      calendar = {
        enabled = true;
        reminders.enabled = true;
      };

      # ----------------------------------------------------------------------
      # Wallpaper automation
      # ----------------------------------------------------------------------
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

      # ----------------------------------------------------------------------
      # Night light and audio polish
      # ----------------------------------------------------------------------
      nightlight = {
        enabled = true;
        temperature_day = 6500;
        temperature_night = 4000;
      };

      audio = {
        enable_overdrive = true;
        enable_sounds = true;
        spectrum_frame_rate = 60;
      };

      # ----------------------------------------------------------------------
      # Hooks
      # ----------------------------------------------------------------------
      hooks = {
        battery_percentage_changed = "notify-send -a Noctalia 'Battery' \"$NOCTALIA_BATTERY_PERCENT%\"";
        power_profile_changed = "notify-send -a Noctalia 'Power' \"Profile: $NOCTALIA_POWER_PROFILE\"";
      };

      # ----------------------------------------------------------------------
      # Plugins
      # ----------------------------------------------------------------------
      plugins = {
        enabled = [
          "noctalia/screen_recorder"
          "noctalia/bongocat"
          "noctalia/kaomoji"
          "oldirtty/color_picker"
          "kenn/keybind-cheatsheet"
        ];

        source = [
          {
            name = "official";
            kind = "path";
            location = "${inputs.noctalia-plugins}";
            enabled = true;
          }
          {
            name = "community";
            kind = "path";
            location = "${inputs.noctalia-community-plugins}";
            enabled = true;
          }
        ];
      };

      plugin_settings."noctalia/screen_recorder" = {
        frame_rate = 30;
        show_cursor = false;
      };
    };
  };
}
