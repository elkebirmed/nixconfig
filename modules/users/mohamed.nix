# ============================================================================
# Mohamed User
# The mohamed account: profile, secrets, and included aspects.
# ============================================================================
{den, ...}: let
  fullName = "Mohamed Elkebir";
in {
  den.aspects.mohamed = {user, ...}: {
    user = {
      # Account information
      description = fullName;

      # SSH authorized keys for Mohamed's account.
      openssh.authorizedKeys.keys = [
        # Moz public key
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8+qPHnSDa2UnRFj5xrN4NQvRer5a+Nnn/Q3fz4dHjN bureau-pc@DESKTOP-932LUCP"
      ];
    };

    # Password hashes remain encrypted in SOPS and are needed before users
    # are created during boot.
    nixos = {config, ...}: {
      # `neededForUsers` makes the encrypted hash available before account
      # creation; its path is assigned to the generated user entry.
      sops.secrets."passwords/${user.userName}" = {
        sopsFile = ../../secrets/users + "/${user.userName}.yaml";
        neededForUsers = true;
      };
      users.users.${user.userName}.hashedPasswordFile =
        config.sops.secrets."passwords/${user.userName}".path;
    };

    # Aspects every login pulls in.
    includes = [
      den.batteries.define-user
      den.batteries.primary-user
      (den.batteries.user-shell "fish")
      den.aspects.persisted-home
      den.aspects.persisted-state
      den.aspects.fish
      den.aspects.completions
      den.aspects.bat
      den.aspects.fd
      den.aspects.ripgrep
      den.aspects.lsd
      den.aspects.fzf
      den.aspects.yazi
      den.aspects.tuios
      den.aspects.kitty
      den.aspects.kanata
      den.aspects.desktop
      den.aspects.theming
      den.aspects.apps
      den.aspects.prompt
      den.aspects.languages
      den.aspects.user-ssh-key
      den.aspects.sops-home
      den.aspects.git
      den.aspects.gh
      den.aspects.lazygit
      den.aspects.nvf
      den.aspects.opencode
      den.aspects.commandcode
    ];
  };
}
