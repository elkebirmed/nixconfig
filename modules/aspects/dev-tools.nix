# ============================================================================
# Development Tools
# Command-line tools available on every host.
#
# These go in `environment.systemPackages` (not `defaultPackages`, which is
# reserved for NixOS's own defaults) and exclude anything the devshell
# already provides or that a user profile installs.
# ============================================================================
_: {
  den.aspects.dev-tools.nixos = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      # Archive, file, and search utilities.
      openssl
      imagemagick
      sqlite
      file
      ast-grep
      tealdeer
      dust
      navi
      pastel
      yq
      grex
      tectonic
      fastfetch
      lsof
      tree
      zip
      unzip
      _7zz
      bind
      inotify-tools

      # Hardware inspection and firmware.
      smartmontools
      pciutils
      usbutils
      fwupd
      usql
      lazydocker
    ];
  };
}
