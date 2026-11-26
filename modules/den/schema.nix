# ============================================================================
# Schema
# Typed per-entity options that extend den's user and home schemas.
#
# `desktopProfile` selects which desktop feature tier an entity gets. It is
# declared on both `user` (host-attached accounts) and `home` (standalone Home
# Manager configurations) so the desktop dispatcher can read it in either
# context. The default keeps new entities on the simple, Windows-like setup.
# ============================================================================
{lib, ...}: let
  # One module, attached to both kinds' base schemas.
  desktopProfileModule = {
    options.desktopProfile = lib.mkOption {
      type = lib.types.enum ["full" "simple"];
      default = "simple";
      description = ''
        Desktop feature tier for this entity.

        - `full`: pro Niri/Noctalia setup (workspaces, window rules, blur,
          widgets, screenshots, recording, and the full bar/dock).
        - `simple`: Windows-like setup (dock-first, minimal bar, basic binds).
      '';
    };
  };
in {
  den.schema.user = desktopProfileModule;
  den.schema.home = desktopProfileModule;
}
