# ============================================================================
# Server Nix
# Nix daemon settings, automatic store optimisation, and garbage collection.
# ============================================================================
_: {
  den.aspects.server-nix.nixos = {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      # The base module already trusts `root`; add the wheel group so an
      # operator can `--build-host localhost` and copy unsigned paths.
      trusted-users = ["@wheel"];
      allowed-users = ["@users" "root"];
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    nixpkgs.config.allowUnfree = true;
  };
}
