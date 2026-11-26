# ============================================================================
# Desktop
# Selects which desktop aspects a user (or standalone home) receives.
#
# The profile comes from the entity's typed `desktopProfile` option
# (`modules/den/schema.nix`): `full` gets the pro Niri/Noctalia setup, `simple`
# the Windows-like one. Both profiles share `desktop-defaults`,
# `desktop-apps`, `niri-base`, and `noctalia`.
# ============================================================================
{den, ...}: {
  den.aspects.desktop = {
    user,
    home ? null,
    ...
  }: let
    # A standalone home binds a synthetic `user` without the schema option, so
    # prefer `home` and fall back to the default when it is absent.
    profile =
      if home != null
      then home.desktopProfile
      else user.desktopProfile or "simple";
  in {
    includes = [
      den.aspects.desktop-defaults
      den.aspects.desktop-apps
      den.aspects.niri-base
      den.aspects.noctalia
      (
        if profile == "full"
        then den.aspects.niri-pro
        else den.aspects.niri-simple
      )
      (
        if profile == "full"
        then den.aspects.noctalia-pro
        else den.aspects.noctalia-simple
      )
    ];
  };
}
