# ============================================================================
# Zram
# Compressed RAM swap with a raised swap preference to make it effective.
# ============================================================================
_: {
  # Use compressed RAM swap and increase swap preference to make it effective.
  den.aspects.zram.nixos = {
    zramSwap = {
      enable = true;
      memoryPercent = 50;
    };
    boot.kernel.sysctl."vm.swappiness" = 150;
  };
}
