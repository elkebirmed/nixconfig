# ============================================================================
# Root is wiped on every boot (btrfs-rollback.nix); everything worth keeping
# is bind-mounted from /persist. Other features that need state add to
# persistence quirks consumed here.
# ============================================================================
{
  den,
  inputs,
  ...
}: {
  # Add impermanence input
  flake-file.inputs.impermanence = {
    url = "github:nix-community/impermanence";
    inputs.home-manager.follows = "home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Register per-user home persistence data as a Den quirk so features can
  # declare paths without depending directly on the system persistence module.
  den.quirks.homePersistence = {
    description = "Per-user home directories to preserve across root rollbacks.";
  };

  den.quirks.systemPersistence = {
    description = "System paths to preserve across root rollbacks.";
  };

  # Lift each user's persistence data into its parent host scope.
  den.policies.expose-home-persistence = _: let
    inherit (den.lib.policy) pipe;
  in [(pipe.from "homePersistence" [pipe.expose])];

  # Apply that data-routing policy to each user entity.
  den.schema.user.includes = [den.policies.expose-home-persistence];

  # Keep general user data that survives root rollback in one place.
  den.aspects.persisted-home = {user, ...}: {
    homePersistence = {
      inherit (user) userName;
      directories = [
        "Documents"
        "Downloads"
        "Projects"
      ];
    };
  };

  # Collect user data on the host and combine it with system-level persistent
  # state required by NixOS services.
  den.aspects.impermanence.nixos = {
    homePersistence,
    systemPersistence,
    lib,
    ...
  }: {
    imports = [inputs.impermanence.nixosModules.impermanence];

    environment.persistence."/persist" = {
      # Hide bind mounts from ordinary directory listings.
      hideMounts = true;
      # Preserve general state required by the base system.
      directories =
        [
          "/var/lib/nixos" # uid/gid allocations (users.mutableUsers = false)
          "/var/lib/systemd" # random seed, timer stamps, and systemd state
        ]
        ++ lib.concatMap (entry: entry.directories or []) systemPersistence;
      # Keep the machine identity stable across root rollbacks.
      files = ["/etc/machine-id"] ++ lib.concatMap (entry: entry.files or []) systemPersistence;
      # Convert the collected user quirk values into impermanence's schema.
      users = let
        perUser = lib.groupBy (entry: entry.userName) homePersistence;
      in
        lib.mapAttrs (_: entries: {
          directories = lib.concatMap (entry: entry.directories) entries;
        })
        perUser;
    };
  };
}
