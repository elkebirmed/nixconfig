# ============================================================================
# Connect den and flake-file to the flake-parts dendritic module system.
# ============================================================================
{inputs, ...}: {
  imports = [
    (inputs.flake-file.flakeModules.dendritic or {})
    (inputs.den.flakeModules.dendritic or {})
  ];

  # Expose flake-parts' option tree as `debug.options` so nixd can
  # complete den.*, flake-file.*, etc.
  debug = true;

  # Declare inputs here so flake-file can regenerate the generated flake.nix.
  flake-file.inputs = {
    den.url = "github:denful/den";

    flake-file.url = "github:vic/flake-file";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
