# ============================================================================
# Needed development tools
# ============================================================================
{
  den.aspects.dev.nixos = {pkgs, ...}: {
    environment.defaultPackages = with pkgs; [
      sops
      age
      ssh-to-age
    ];
  };
}
