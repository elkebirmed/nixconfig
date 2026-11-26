# ============================================================================
# Niri Simple
# Windows-like Niri profile: mouse-first, Super-based shortcuts, and the plain
# Alt-Tab switcher.
#
# Merged on top of `niri-base` for users whose `desktopProfile` is `simple`.
# The core tiling binds still come from `niri-base`; this file adds the
# obvious, Windows-style entry points plus the screenshot and window-switching
# keys a complete desktop is expected to have.
# ============================================================================
_: {
  den.aspects.niri-simple.homeManager = {
    lib,
    config,
    ...
  }: let
    noctaliaPackage =
      config.programs.noctalia.package
      or (throw "niri-simple requires the noctalia aspect");

    noctaliaExe = lib.getExe noctaliaPackage;

    msg = args: [noctaliaExe "msg"] ++ args;
  in {
    programs.niri.settings = {
      input = {
        keyboard.xkb = {
          layout = "fr,ara";
          options = "grp:alt_shift_toggle,compose:ralt";
        };
      };

      layout = {
        preset-column-widths = [
          {proportion = 1.0 / 3.0;}
          {proportion = 1.0 / 2.0;}
          {proportion = 2.0 / 3.0;}
          {proportion = 1.0;}
        ];

        default-column-width = {proportion = 1.0;};
      };

      binds = {
        # `Mod` is Super on the TTY backend, so use it everywhere instead of
        # the raw `Super` name the rest of the config (and Noctalia) uses.
        "Mod+Space".action.toggle-overview = [];
        "Mod+Tab".action.spawn = msg ["window-switcher"];
        "Mod+D".action.toggle-overview = [];

        # Mod+E is the file manager, as on Windows.
        "Mod+E".action.spawn = ["nautilus"];

        # Alt-Tab and Alt-F4 match the Windows muscle memory.
        "Alt+Tab".action.spawn = msg ["window-switcher" "hold"];
        "Alt+Shift+Tab".action.spawn = msg ["window-switcher" "hold" "reverse"];
        "Alt+F4".action.close-window = [];
        "Mod+L".action.spawn = msg ["session" "lock"];

        # Screenshots: Print for a region with annotation, Mod+Print for the
        # whole screen, Mod+Shift+Print for the focused window.
        "Print".action.spawn = msg ["screenshot-region"];
        "Mod+Print".action.spawn = msg ["screenshot-fullscreen"];
        "Mod+Shift+Print".action.spawn = msg ["screenshot-window"];
      };

      # Dialogs and file pickers float; everything else is tiled by default.
      window-rules = [
        {
          matches = [{is-floating = true;}];
          geometry-corner-radius = 12.0;
        }
        {
          matches = [{title = "^(Open File|Open Folder|Save File|File Upload)$";}];
          open-floating = true;
        }
      ];
    };
  };
}
