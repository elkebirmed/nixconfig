# ============================================================================
# OpenSSH
# Key-only SSH with the host key kept on persistent storage.
#
# The host key also backs sops-nix age decryption (see sops.nix), so this
# path is the single source of truth.
# ============================================================================
_: {
  # Declare which interfaces may reach SSH. Empty keeps the old host-wide
  # reachability; a non-empty list makes the firewall open port 22 only there.
  den.schema.host = {lib, ...}: {
    options.ssh.interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["wlp8s0" "enp9s0"];
      description = "Network interfaces on which SSH (port 22) is reachable.";
    };

    options.ssh.hostKeyPath = lib.mkOption {
      type = lib.types.str;
      default = "/persist/etc/ssh/ssh_host_ed25519_key";
      example = "/etc/ssh/ssh_host_ed25519_key";
      description = "Path to the ed25519 host key used for SSH and SOPS age decryption.";
    };
  };

  # Restrict SSH to key authentication and keep the host key on persistent
  # storage so it remains available after the root subvolume is reset.
  den.aspects.openssh = {user, ...}: {
    homePersistence = {
      inherit (user) userName;
      directories = [
        {
          directory = ".ssh";
          mode = "0700";
        }
      ];
    };

    # The host includes this aspect once per user, so the shared daemon
    # settings below are merged once per account.
    nixos = {
      config,
      host,
      ...
    }: {
      services.openssh = {
        enable = true;

        # `openFirewall` would add port 22 to every interface, defeating the
        # per-interface restriction in firewall.nix.
        openFirewall = host.ssh.interfaces == [];

        hostKeys = [
          # Reuse the persistent host key for SSH identity and SOPS age decryption.
          {
            path = host.ssh.hostKeyPath;
            type = "ed25519";
          }
        ];

        settings = {
          # Require public-key authentication and disallow root SSH login.
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";

          # Each user's instance adds only itself when it has keys, so the
          # merged list never duplicates an account.
          AllowUsers =
            if (config.users.users.${user.userName}.openssh.authorizedKeys.keys or []) == []
            then []
            else [user.userName];
        };
      };
    };

    # Client-side defaults for every account on the host.
    homeManager = {
      programs.ssh = {
        enable = true;

        settings."*" = {
          ServerAliveInterval = 60;
          ServerAliveCountMax = 3;
        };
      };
    };
  };
}
