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

  # Host side: password hashes, host secrets (uses the SSH host key)
  den.aspects.sops.nixos.imports = [inputs.sops-nix.nixosModules.sops];

  # User side: secrets only this user needs (uses ~/.config/sops/age/keys.txt)
  den.aspects.sops-home = {user, ...}: {
    homePersistence = {
      inherit (user) userName;
      directories = [
        {
          directory = ".config/sops/age";
          mode = "0700";
        }
      ];
    };

    homeManager = {config, ...}: {
      imports = [inputs.sops-nix.homeManagerModules.sops];
      sops = {
        age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
        defaultSopsFile = ../../secrets/users + "/${user.userName}.yaml";
      };
    };
  };
}
