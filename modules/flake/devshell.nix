# ============================================================================
# Dev Shells
# Development shell with the tools needed to edit and check this flake.
# ============================================================================
_: {
  perSystem = {pkgs, ...}: {
    devShells = {
      default = pkgs.mkShell {
        # Formatting, linting, and Nix tooling for this flake.
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
