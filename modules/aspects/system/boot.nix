# ============================================================================
# Boot
# UEFI systemd-boot with a bounded number of retained entries.
# ============================================================================
_: {
  den.aspects.boot.nixos = {
    boot.loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };
  };
}
