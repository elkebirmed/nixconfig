# ============================================================================
# Nix Daemon
# Nix daemon settings, automatic upkeep, `nh`, and command-not-found.
# ============================================================================
{inputs, ...}: {
  # nix-index-database ships a prebuilt index, so `comma` works without
  # running nix-index locally.
  flake-file.inputs.nix-index-database = {
    url = "github:nix-community/nix-index-database";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Configure Nix's command interface, trusted users, and automatic upkeep.
  den.aspects.nix-daemon.nixos = {
    imports = [inputs.nix-index-database.nixosModules.nix-index];

    nix = {
      settings = {
        # Enable the CLI and flake commands used to manage this configuration.
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        # Only root may use the daemon's trusted operations (adding
        # substituters, importing unsigned paths, overriding settings).
        # `nh os switch` and `nixos-rebuild` run through sudo, so they still
        # work for mohamed.
        trusted-users = ["root"];

        # Every account needs to *connect* to the daemon: Home Manager
        # activates as the user (home-manager-<user>.service), so restricting
        # this to @wheel broke `home-manager-koko` and `home-manager-kids`
        # with "cancelled while waiting for the Nix daemon". Trusted
        # operations above remain root-only.
        allowed-users = ["@users" "root"];
      };
    };

    # `nh` drives builds, `nvd` diffs, and cleans old generations. `nh clean`
    # replaces the old `nix.gc` timer, which would otherwise duplicate it.
    programs.nh = {
      enable = true;
      flake = "/home/mohamed/Projects/nixconfig";
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 5 --keep-since 7d";
      };
    };

    # `,` runs any program from nixpkgs on demand using the prebuilt index.
    programs.nix-index-database.comma.enable = true;

    # This host intentionally permits unfree packages.
    nixpkgs.config.allowUnfree = true;
  };
}
