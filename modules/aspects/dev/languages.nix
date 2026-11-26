# ============================================================================
# Languages
# Language toolchains for development work, installed per user.
# ============================================================================
_: {
  den.aspects.languages = {user, ...}: {
    # Toolchain state lives outside the ephemeral root.
    homePersistence = {
      inherit (user) userName;
      directories = [
        ".cargo"
        ".rustup"
        ".npm"
        ".local/share/pipx"
        ".local/share/pnpm"
      ];
    };

    homeManager = {pkgs, ...}: {
      # Home Manager builds its own package set unless useGlobalPkgs is on;
      # terraform's BSL license has to be accepted here too.
      nixpkgs.config.allowUnfree = true;

      home.packages = with pkgs; [
        go
        gofumpt
        nodejs
        rustup
        python3
        pipx
        terraform
        just
        tree-sitter
      ];
    };
  };
}
