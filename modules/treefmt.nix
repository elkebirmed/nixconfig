# ============================================================================
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
    programs = {
      alejandra.enable = true;
      deadnix.enable = true;
      gofumpt.enable = true;
      prettier.enable = true;
      statix.enable = true;
    };
  };
}
