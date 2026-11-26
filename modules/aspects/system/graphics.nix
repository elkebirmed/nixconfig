# ============================================================================
# Graphics
# GPU acceleration, portals, removable media, and power reporting for a
# Wayland desktop.
# ============================================================================
_: {
  den.aspects.graphics.nixos = {pkgs, ...}: {
    hardware.graphics.enable = true;

    # GTK portal for file pickers; niri adds the GNOME portal for screencasts.
    xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

    # Needed by desktop file managers, trash, and battery/bar widgets.
    services.gvfs.enable = true;
    services.udisks2.enable = true;
    services.upower.enable = true;

    # Mount Windows and exFAT USB sticks from the file manager.
    boot.supportedFilesystems = ["ntfs3" "exfat"];
    environment.systemPackages = with pkgs; [
      ntfs3g
      exfatprogs
    ];

    # Used by the Noctalia control center and bar.
    hardware.bluetooth.enable = true;
    services.power-profiles-daemon.enable = true;
  };
}
