# ============================================================================
# Needed development tools
# ============================================================================
{
  den.aspects.dev.nixos = {pkgs, ...}: {
    environment.defaultPackages = with pkgs; [
      nix
      nixd
      alejandra
      statix
      deadnix
      sops
      age
      ssh-to-age
      openssh
      git
      jq
      openssl
      imagemagick
      sqlite
      file
      ast-grep
    ];
  };
}
