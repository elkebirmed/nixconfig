# ============================================================================
# Niri Base
# Shared Niri home configuration for every desktop user.
#
# Input, layout, core navigation binds, and the media/brightness keys routed
# through Noctalia's OSD. The selected profile aspect (`niri-pro` or
# `niri-simple`) adds its own binds, window rules, and workspaces on top; the
# module system deep-merges all of them into one `programs.niri.settings`.
# ============================================================================
{inputs, ...}: {
  den.aspects.niri-base = {home ? null, ...}: {
    homeManager = {
      lib,
      config,
      pkgs,
      ...
    }: let
      # Use whichever Noctalia package its aspect selected.
      noctaliaPackage =
        config.programs.noctalia.package
        or inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

      # Absolute paths keep spawn commands independent of the session PATH.
      noctaliaExe = lib.getExe noctaliaPackage;
      playerctlExe = lib.getExe pkgs.playerctl;
    in {
      # Under a NixOS host, niri-flake injects this module through
      # `home-manager.sharedModules`. Importing it again there would duplicate
      # the `programs.niri` options, so only standalone homes import it.
      imports = lib.optionals (home != null) [inputs.niri.homeModules.niri];

      programs.niri = {
        # niri.nix owns the host-wide choice (`pkgs.niri`); standalone homes
        # get the same nixpkgs package.
        package = pkgs.niri;
        settings = {
          # Palette colors (background, focus ring, shadow) come from the
          # Noctalia template; every profile includes them.
          includes = ["colors.kdl"];

          input = {
            touchpad = {
              tap = true;
              natural-scroll = true;
            };
          };

          layout = {
            gaps = 12;
            border = {};
            focus-ring.width = 2;
          };

          # Electron and other toolkits look for this under Wayland.
          environment.NIXOS_OZONE_WL = "1";

          hotkey-overlay.skip-at-startup = true;

          binds = {
            # ------------------------------------------------------------------
            # Core navigation
            # ------------------------------------------------------------------
            "Mod+Q".action.close-window = [];
            "Mod+Shift+E".action.quit = [];

            "Mod+Left".action.focus-column-left = [];
            "Mod+Right".action.focus-column-right = [];
            "Mod+Up".action.focus-window-or-workspace-up = [];
            "Mod+Down".action.focus-window-or-workspace-down = [];

            "Mod+Ctrl+Left".action.move-column-left = [];
            "Mod+Ctrl+Right".action.move-column-right = [];
            "Mod+Ctrl+Up".action.move-window-up-or-to-workspace-up = [];
            "Mod+Ctrl+Down".action.move-window-down-or-to-workspace-down = [];

            "Mod+Home".action.focus-column-first = [];
            "Mod+End".action.focus-column-last = [];
            "Mod+Ctrl+Home".action.move-column-to-first = [];
            "Mod+Ctrl+End".action.move-column-to-last = [];

            "Mod+Shift+Left".action.focus-monitor-left = [];
            "Mod+Shift+Right".action.focus-monitor-right = [];
            "Mod+Shift+Up".action.focus-monitor-up = [];
            "Mod+Shift+Down".action.focus-monitor-down = [];

            "Mod+Page_Down".action.focus-workspace-down = [];
            "Mod+Page_Up".action.focus-workspace-up = [];
            "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = [];
            "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = [];

            "Mod+R".action.switch-preset-column-width = [];
            "Mod+Shift+R".action.switch-preset-column-width-back = [];
            "Mod+F".action.maximize-column = [];
            "Mod+Shift+F".action.fullscreen-window = [];
            "Mod+M".action.maximize-window-to-edges = [];

            "Mod+Shift+Space".action.toggle-window-floating = [];

            "Mod+BracketLeft".action.consume-or-expel-window-left = [];
            "Mod+BracketRight".action.consume-or-expel-window-right = [];
            "Mod+Comma".action.consume-window-into-column = [];
            "Mod+Period".action.expel-window-from-column = [];

            "Mod+Minus".action.set-column-width = ["-10%"];
            "Mod+Equal".action.set-column-width = ["+10%"];
            "Mod+Shift+Minus".action.set-window-height = ["-10%"];
            "Mod+Shift+Equal".action.set-window-height = ["+10%"];

            # ------------------------------------------------------------------
            # Media and brightness keys through Noctalia's OSD
            # ------------------------------------------------------------------
            "XF86AudioRaiseVolume" = {
              allow-when-locked = true;
              action.spawn = [noctaliaExe "msg" "volume-up"];
            };
            "XF86AudioLowerVolume" = {
              allow-when-locked = true;
              action.spawn = [noctaliaExe "msg" "volume-down"];
            };
            "XF86AudioMute" = {
              allow-when-locked = true;
              action.spawn = [noctaliaExe "msg" "volume-mute"];
            };
            "XF86AudioMicMute" = {
              allow-when-locked = true;
              action.spawn = [noctaliaExe "msg" "mic-mute"];
            };
            "XF86AudioPlay" = {
              allow-when-locked = true;
              action.spawn = [playerctlExe "play-pause"];
            };
            "XF86AudioNext" = {
              allow-when-locked = true;
              action.spawn = [playerctlExe "next"];
            };
            "XF86AudioPrev" = {
              allow-when-locked = true;
              action.spawn = [playerctlExe "previous"];
            };
            "XF86AudioStop" = {
              allow-when-locked = true;
              action.spawn = [playerctlExe "stop"];
            };
            "XF86MonBrightnessUp" = {
              allow-when-locked = true;
              action.spawn = [noctaliaExe "msg" "brightness-up"];
            };
            "XF86MonBrightnessDown" = {
              allow-when-locked = true;
              action.spawn = [noctaliaExe "msg" "brightness-down"];
            };
          };
        };
      };

      # Session helpers shared by every desktop user. `networkmanagerapplet`
      # is provided by the host (polkit-keyring), and screenshot annotation
      # (`satty`) plus the app set come from the user's app aspects.
      home.packages = with pkgs; [
        wl-clipboard
        grim
        slurp
        brightnessctl
        playerctl
        pavucontrol
        libnotify
        btop
        cava
      ];
    };
  };
}
