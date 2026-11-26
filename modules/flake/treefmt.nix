# ============================================================================
# Treefmt
# `nix fmt` and the `treefmt` flake check.
# ============================================================================
{inputs, ...}: {
  # Add treefmt-nix input.
  flake-file.inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Expose nixfmt and static Nix checks through `nix fmt` and flake checks.
  imports = [inputs.treefmt-nix.flakeModule];

  perSystem.treefmt = {
    # Anchor root discovery at the generated flake entry point.
    projectRootFile = "flake.nix";

    settings = {
      # SOPS files must stay byte-for-byte as sops wrote them, and the Noctalia
      # palette/template files are upstream data that is copied verbatim.
      excludes = [
        "flake.nix"
        "secrets/hosts/*"
        "secrets/users/*"
        "modules/aspects/desktop/theming/palettes/*"
        "modules/aspects/desktop/theming/templates/*"
        "assets/wallpapers/*"
      ];
    };

    programs = {
      alejandra.enable = true;
      deadnix.enable = true;
      gofumpt.enable = true;
      prettier.enable = true;
      statix.enable = true;
    };
  };
}
