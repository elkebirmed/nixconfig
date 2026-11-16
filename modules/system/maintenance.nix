# ============================================================================
# Maintenance
# ============================================================================
_: {
  # Trim SSD-backed storage regularly and scrub the persistent Btrfs volume.
  den.aspects.maintenance.nixos.services = {
    fstrim.enable = true;
    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = ["/persist"];
    };
  };
}
