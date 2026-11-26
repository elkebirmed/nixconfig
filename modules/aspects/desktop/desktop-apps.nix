# ============================================================================
# Desktop Apps
# The default graphical application set for every desktop user.
#
# Profile-specific extras (theming tooling, editors, terminals used only by
# mohamed) stay in their own aspects. This aspect is included by `desktop` so
# `koko` and `kids` get the same browser, file manager, documents, media, and
# password manager as `mohamed`.
# ============================================================================
{inputs, ...}: {
  # Zen Browser is not in nixpkgs; the flake tracks its own nixpkgs.
  flake-file.inputs.zen-browser = {
    url = "github:0xc000022070/zen-browser-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.desktop-apps = {user, ...}: {
    # Browser profile and related state survive root rollbacks. The wallpaper
    # set is a Home Manager store symlink regenerated on activation, so it is
    # never persisted (`Pictures`, which holds it, is).
    homePersistence = {
      inherit (user) userName;
      directories = [
        ".zen"
        ".config/zen"
        ".local/share/zen"
      ];
    };

    homeManager = {pkgs, ...}: {
      # The wallpaper set lives with the apps so `simple` users get it too.
      home.file."Pictures/Wallpapers".source = ../../../assets/wallpapers;

      home.packages =
        [
          inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
        ]
        ++ (with pkgs; [
          # Files and archives.
          nautilus
          file-roller
          gnome-disk-utility
          baobab
          gnome-control-center

          # Documents.
          zathura
          zathuraPkgs.zathura_pdf_mupdf
          libreoffice

          # Media.
          mpv
          imv
          gnome-font-viewer

          # Credentials and chat.
          keepassxc
          fractal

          # Thumbnails and codecs for the file manager and viewers.
          ffmpegthumbnailer
          poppler-utils
        ]);
    };
  };
}
