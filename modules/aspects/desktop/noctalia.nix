# ============================================================================
# Noctalia
# Noctalia Shell base configuration shared by every desktop user.
#
# The shell is configured through the project's Home Manager module and uses
# the flake package from the Noctalia cache. Theme, notifications, clipboard,
# lock/idle, location, and the greeter sync live here; the selected profile
# aspect (`noctalia-pro` or `noctalia-simple`) adds bar, dock, and widget
# layout. The module system deep-merges all of them into one `config.toml`.
# ============================================================================
{inputs, ...}: {
  flake-file.inputs.noctalia = {
    # The cachix branch points at the latest commit whose flake outputs are
    # already in the Noctalia cache. Do not follow nixpkgs: following changes
    # the derivation hash and causes cache misses.
    url = "github:noctalia-dev/noctalia/cachix";
  };

  den.aspects.noctalia.homeManager = {pkgs, ...}: {
    imports = [inputs.noctalia.homeModules.default];

    programs.noctalia = {
      enable = true;

      # Run as a systemd user service instead of `spawn-at-startup`: niri's
      # `niri-session` starts `graphical-session.target`, and the module's
      # service is pulled in by `wayland.systemd.target`.
      systemd.enable = true;

      # Commands used by plugins, including the screen recorder.
      extraPackages = [pkgs.gpu-screen-recorder];

      settings = {
        shell = {
          font_family = "Rubik";

          # Noctalia owns authentication now; the niri-flake agent is disabled
          # in `niri.nix`.
          polkit_agent = true;

          # Rounded, animated surfaces with soft shadows.
          corner_radius_scale = 1.25;
          animation = {
            enabled = true;
            speed = 1.0;
          };
          shadow = {
            direction = "down";
            alpha = 0.55;
          };
          panel = {
            transparency_mode = "glass";
            borders = true;
            shadow = true;
          };

          clipboard_enabled = true;
          clipboard_history_max_entries = 100;
          clipboard_keep_from_closed_apps = true;
          clipboard_image_action_command = "satty -f -";

          # Screenshots: keep the default copy/save behavior of the old setup.
          screenshot = {
            skip_annotate_on_copy_save = false;
            close_on_copy = true;
            close_on_save = true;
          };

          password_style = "default";

          # Mirror Noctalia's palette and wallpaper on the login screen.
          greeter_sync.auto_sync = true;
        };

        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Catppuccin";
          pure_black_dark = false;
        };

        # Propagate the palette to GTK and let the theming aspect own the
        # per-application templates (kitty, fish, lsd, bat, yazi, ...).
        theme.templates = {
          enable_builtin_templates = true;
          builtin_ids = ["gtk3" "gtk4"];
          enable_community_templates = false;
        };

        # Glass and blur behind floating surfaces.
        backdrop = {
          enabled = true;
          blur_intensity = 0.6;
          tint_intensity = 0.3;
        };

        notification = {
          enable_daemon = true;
          group_by_app = true;
          keep_dismissed_in_history = true;
          show_actions = true;
        };

        lockscreen = {
          enabled = true;
          blurred_desktop = true;
          grace_period_seconds = 0;
        };

        idle = {
          behavior.lock = {
            timeout = 600; # 10 minutes
            action = "lock";
            enabled = true;
          };
          behavior.screen-off = {
            timeout = 900; # 15 minutes
            action = "screen_off";
            enabled = true;
          };
          behavior.suspend = {
            timeout = 1800; # 30 minutes
            action = "lock_and_suspend";
            enabled = true;
          };
        };

        # Weather, night light, and day/night theming use a fixed location.
        location.address = "Blida, DZ";

        # Backlight only; no ddcutil probing of external monitors.
        brightness.enable_ddcutil = false;

        system.monitor.enabled = true;
      };
    };
  };
}
