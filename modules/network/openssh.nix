# ============================================================================
# OpenSSH
# ============================================================================
# Key-only SSH. The host key lives on /persist, and sops-nix derives its age
# key from it (see sops.nix), so this path is the single source of truth.
_: {
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

    nixos = {
      services.openssh = {
        enable = true;
        hostKeys = [
          # Reuse the persistent host key for SSH identity and SOPS age decryption.
          {
            path = "/persist/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ];
        settings = {
          # Require public-key authentication and disallow root SSH login.
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
        };
      };
    };
  };
}
