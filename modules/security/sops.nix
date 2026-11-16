# ============================================================================
# Secrets are decrypted at activation with the host's SSH ed25519 key
# (`sops.age.sshKeyPaths` defaults to `services.openssh.hostKeys`).
# Secret files mirror the module tree: secrets/hosts/<host>.yaml and
# secrets/users/<user>.yaml. Each consumer declares its own `sopsFile`
# (hosts/*.nix: host secrets, users/*.nix: passwords, git.nix: emails).
{inputs, ...}: let
  # ============================================================================
  mkKeySecret = {
    user,
    name,
    file,
  }: {
    "${name}/${user.userName}" = {
      sopsFile = ../../secrets/users + "/${user.userName}.yaml";
      owner = user.userName;
      mode = "0600";
      path = "/persist/home/${user.userName}/${file}";
    };
  };
in {
  # Add sops-nix input.
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Host side: password hashes, host secrets (uses the SSH host key)
  den.aspects.sops.nixos.imports = [inputs.sops-nix.nixosModules.sops];

  den.aspects.user-ssh-key = {user, ...}: {
    nixos.sops.secrets = mkKeySecret {
      inherit user;
      name = "ssh";
      file = ".ssh/id_ed25519";
    };
  };

  # Not for the primary user: his age key is a backed-up root of trust.
  den.aspects.user-age-key = {user, ...}: {
    nixos.sops.secrets = mkKeySecret {
      inherit user;
      name = "age";
      file = ".config/sops/age/keys.txt";
    };
  };

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
        defaultSopsFile = ../../secrets/users + "/${user.userName}.yaml";
        age = {
          keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
          sshKeyPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];
        };
      };
    };
  };
}
