# ============================================================================
# Secrets are decrypted at activation with the host's SSH ed25519 key
# (`sops.age.sshKeyPaths` defaults to `services.openssh.hostKeys`).
# Secret files mirror the module tree: secrets/hosts/<host>.yaml and
# secrets/users/<user>.yaml. Each consumer declares its own `sopsFile`
# (hosts/*.nix: host secrets, users/*.nix: passwords, git.nix: emails).
# ============================================================================
{inputs, ...}: {
  # Add sops-nix input.
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Decrypt secrets at activation and keep secret declarations with consumers.
  den.aspects.sops = {user, ...}: {
    homePersistence = {
      inherit (user) userName;
      directories = [
        {
          directory = ".config/sops/age";
          mode = "0700";
        }
      ];
    };

    nixos = {
      imports = [inputs.sops-nix.nixosModules.sops];
    };
  };
}
