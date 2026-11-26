# ============================================================================
# Impermanence
# Keep root ephemeral and bind-mount persistent state from /persist.
#
# Root is wiped on every boot (btrfs-rollback.nix). Other features declare
# what to keep through the persistence quirks consumed here.
# ============================================================================
{
  den,
  inputs,
  ...
}: {
  # Add the impermanence input.
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
        "Desktop"
        "Music"
        "Videos"
        "Pictures"
      ];
    };
  };

  # Store application secrets in the login keyring and keep that keyring, the
  # trash, dconf, container storage, and the dev-tool state across rollbacks.
  # Noctalia's own state/cache live under the `noctalia` identity
  # (~/.local/state/noctalia and ~/.cache/noctalia).
  den.aspects.persisted-state = {user, ...}: {
    homePersistence = {
      inherit (user) userName;
      directories = [
        ".local/share/keyrings"
        ".local/share/Trash"
        ".config/dconf"
        ".local/share/containers"
        ".local/state/wireplumber"
        ".local/share/zoxide"
        ".local/share/direnv"
        ".local/share/nvim"
        ".local/state/nvim"
        ".local/state/noctalia"
        ".cache/noctalia"
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

    # Forces accounts to come from the declarative `users.users` entries, so
    # state that must survive a rollback cannot drift from the config.
    users.mutableUsers = false;

    environment.persistence."/persist" = {
      # Hide bind mounts from ordinary directory listings.
      hideMounts = true;
      # Preserve general state required by the base system.
      directories =
        [
          "/var/lib/nixos" # uid/gid allocations (users.mutableUsers = false)
          "/var/lib/systemd" # random seed, timer stamps, and systemd state
          "/var/lib/bluetooth"
          "/var/lib/NetworkManager"
          "/var/lib/upower"
          "/var/lib/cups"
          "/var/lib/fwupd"
          "/var/lib/AccountsService"
          "/var/lib/power-profiles-daemon"
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
