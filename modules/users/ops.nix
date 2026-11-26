# ============================================================================
# Ops User
# The VPS administrator: SSH key only, wheel, and a small CLI environment.
# ============================================================================
{den, ...}: {
  den.aspects.ops = {user, ...}: {
    user = {
      description = "VPS administrator";

      openssh.authorizedKeys.keys = [
        # Same public key as the primary desktop account.
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8+qPHnSDa2UnRFj5xrN4NQvRer5a+Nnn/Q3fz4dHjN bureau-pc@DESKTOP-932LUCP"

        # Desktop key used for deployment and day-to-day administration.
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFnctYXaFydNbmnBOfxa3vEwtp2jSWAuJuAvkY7VCN+u mohamed@crazy"
      ];
    };

    includes = [
      den.batteries.define-user
      (den.batteries.user-shell "fish")
      den.aspects.openssh
    ];

    # Keep the VPS account small: no desktop, no user-owned SOPS identities.
    #
    # The git email is a personal identifier and must not be a literal here. It
    # is read from a HOST-scoped secret (secrets/hosts/vps.yaml) declared at the
    # NixOS level, because:
    #   * the VPS host key must never decrypt secrets/users/*.yaml, and
    #   * user-level sops would need an identity this account does not have.
    # The host key decrypts it at activation, the rendered file is owned by the
    # account, and git reads it as an include. It never enters the Nix store.
    homeManager = {pkgs, ...}: {
      programs.fish.enable = true;

      programs.git = {
        enable = true;
        settings.user = {
          name = "Mohamed Elkebir";
        };
        includes = [{path = "/run/secrets/rendered/git-email";}];
      };

      home.packages = with pkgs; [
        bat
        curl
        fd
        fzf
        git
        htop
        jq
        ripgrep
        tmux
        wget
      ];
    };

    nixos = {config, ...}: {
      users.users.${user.userName} = {
        uid = 1001;
        isNormalUser = true;
        extraGroups = ["wheel"];
      };

      sops.secrets."git-email" = {
        # `config.sops.defaultSopsFile` is the VPS host file.
        owner = user.userName;
        mode = "0400";
      };

      sops.templates."git-email" = {
        path = "/run/secrets/rendered/git-email";
        owner = user.userName;
        mode = "0400";
        content = ''
          [user]
            email = ${config.sops.placeholder."git-email"}
        '';
      };
    };
  };
}
