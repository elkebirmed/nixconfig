# ============================================================================
# Create `nix run .#<name>` apps for building declared hosts and homes with nh.
# ============================================================================
{den, ...}: {
  perSystem = {pkgs, ...}: {
    packages = den.lib.nh.denPackages {fromFlake = true;} pkgs;
  };
}
