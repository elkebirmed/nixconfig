# ============================================================================
# Boot in UEFI mode with systemd-boot and retain a bounded set of entries.
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
