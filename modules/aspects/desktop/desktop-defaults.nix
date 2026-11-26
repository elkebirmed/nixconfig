# ============================================================================
# Desktop Defaults
# Baseline desktop behavior shared by every user with a graphical session:
# dconf, MIME defaults, XDG user directories, portals, cursor/theme, 32-bit
# and AppImage runtimes, and the hardware health services.
#
# Themed files belong to Noctalia (see `theming.nix`); this aspect only sets
# the GTK/Qt preferences that Noctalia does not own.
# ============================================================================
_: {
  den.aspects.desktop-defaults = {
    # dconf needs a writable database and the settings service.
    nixos.programs.dconf.enable = true;

    # niri has no portal of its own; pair the GTK portal with GNOME's for
    # screencasts and screensharing.
    nixos.xdg.portal = {
      enable = true;
      config = {
        common.default = ["gtk"];
        niri.default = ["gnome" "gtk"];
      };
    };

    # A terminal for `xdg-terminal-exec` and the default MIME handler.
    nixos.xdg.terminal-exec = {
      enable = true;
      settings.default = ["kitty.desktop"];
    };

    # 32-bit binaries and AppImages need the runtime shim.
    nixos.programs.nix-ld.enable = true;
    nixos.programs.appimage.enable = true;

    # Firmware updates, SMART monitoring, and the userspace OOM killer.
    nixos = {
      services.fwupd.enable = true;
      services.smartd.enable = true;
      systemd.oomd.enable = true;
    };

    homeManager = {pkgs, ...}: {
      # Browser, file manager, documents, images, media, mail, and terminal.
      xdg.mimeApps = {
        enable = true;
        defaultApplications = let
          browser = "zen-beta.desktop";
        in {
          "text/html" = browser;
          "x-scheme-handler/http" = browser;
          "x-scheme-handler/https" = browser;
          "x-scheme-handler/about" = browser;
          "x-scheme-handler/unknown" = browser;

          "inode/directory" = "org.gnome.Nautilus.desktop";
          "application/pdf" = "org.pwmt.zathura.desktop";

          "image/png" = "imv.desktop";
          "image/jpeg" = "imv.desktop";
          "image/gif" = "imv.desktop";
          "image/webp" = "imv.desktop";
          "image/svg+xml" = "imv.desktop";

          "audio/mpeg" = "mpv.desktop";
          "audio/flac" = "mpv.desktop";
          "audio/ogg" = "mpv.desktop";
          "video/mp4" = "mpv.desktop";
          "video/webm" = "mpv.desktop";
          "video/x-matroska" = "mpv.desktop";

          "x-scheme-handler/mailto" = "org.gnome.Evolution.desktop";

          "text/plain" = "kitty.desktop";
        };
      };

      # Create the standard XDG user directories on first activation.
      xdg.userDirs = {
        enable = true;
        createDirectories = true;
      };

      # Bibata cursors from `apps.nix`; apply them to GTK and the cursor
      # environment so Wayland clients agree.
      home.pointerCursor = {
        enable = true;
        gtk.enable = true;
        name = "Bibata-Modern-Ice";
        package = pkgs.bibata-cursors;
        size = 24;
      };

      # Dark GTK preference and icon theme; Noctalia owns the color palette
      # and the generated GTK CSS, so nothing here writes those files.
      gtk = {
        enable = true;
        colorScheme = "dark";
        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
      };

      # Qt follows the GTK3 platform theme, using qt6ct for style overrides.
      qt = {
        enable = true;
        platformTheme.name = "gtk3";
      };
    };
  };
}
