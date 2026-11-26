# ============================================================================
# Desktop Binary Caches
# Binary caches for the desktop stack.
#
# Noctalia publishes a Cachix cache, and its flake package is built against
# the flake's own pinned nixpkgs, so `noctalia` does not follow nixpkgs when a
# cache hit is desired. niri comes from nixpkgs (`pkgs.niri`), so no niri
# substituter is configured.
# ============================================================================
_: let
  substituters = [
    "https://noctalia.cachix.org"
  ];

  trusted-public-keys = [
    "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
  ];
in {
  # Allows `nixos-rebuild --accept-flake-config` and plain Nix commands to use
  # the caches before the rebuilt system's nix.settings is active.
  flake-file.nixConfig = {
    extra-substituters = substituters;
    extra-trusted-public-keys = trusted-public-keys;
  };

  # Persist the same caches in the installed system.
  den.aspects.desktop-cache.nixos = {
    nix.settings = {
      extra-substituters = substituters;
      extra-trusted-public-keys = trusted-public-keys;
    };
  };
}
