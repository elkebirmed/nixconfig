# ============================================================================
# Locale Configuration
# ============================================================================
_: {
  # Set stable defaults while allowing individual hosts to override them.
  den.aspects.locale.nixos = {lib, ...}: {
    time.timeZone = lib.mkDefault "UTC";
    i18n.defaultLocale = "en_US.UTF-8";
    console.keyMap = lib.mkDefault "us";
  };
}
