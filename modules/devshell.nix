# ============================================================================
# Dev Shells
# ============================================================================
_: {
  perSystem = {pkgs, ...}: {
    devShells = {
      default = pkgs.mkShell {
        packages = with pkgs; [
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
        ];

        shellHook = ''
          echo "NixOS configuration development environment"
        '';
      };
    };
  };
}
