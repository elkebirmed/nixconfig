# ============================================================================
# Apps
# Mohamed's personal extras on top of the shared `desktop-apps` set.
#
# The default applications every desktop user gets live in `desktop-apps.nix`.
# This aspect only holds tools specific to the full profile.
# ============================================================================
_: {
  den.aspects.apps.homeManager = {pkgs, ...}: {
    home.packages = with pkgs; [
      # Screenshot annotation used by Noctalia's clipboard and screenshot
      # actions.
      satty

      # Wayland color picker, driven by the community `color_picker` plugin.
      hyprpicker

      # Theme inspection while building the Noctalia palette pipeline.
      nwg-look
      qt6Packages.qt6ct
    ];
  };
}
