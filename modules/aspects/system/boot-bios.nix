# ============================================================================
# Boot BIOS
# GRUB on a GPT disk. Disko already points GRUB at the host disk, so only the
# loader and generation limit are set here.
# ============================================================================
_: {
  den.aspects.boot-bios.nixos.boot.loader.grub = {
    enable = true;
    configurationLimit = 10;
  };
}
