# ============================================================================
# Nix daemon settings, store clean-up, unfree packages.
# ============================================================================
_: {
  # Configure Nix's command interface, trusted users, and automatic upkeep.
  den.aspects.nix.nixos = {
    nix = {
      settings = {
        # Enable the CLI and flake commands used to manage this configuration.
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          # Root manages the daemon; wheel users may perform trusted operations.
          "root"
          "@wheel"
        ];
      };

      gc = {
        # Reclaim old generations weekly while keeping two weeks of history.
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };
      # Deduplicate the Nix store after garbage collection.
      optimise.automatic = true;
    };

    # This host intentionally permits unfree packages.
    nixpkgs.config.allowUnfree = true;
  };
}
