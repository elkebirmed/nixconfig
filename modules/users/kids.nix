# ============================================================================
# Kids User
# The kids account: profile, secrets, and included aspects.
# ============================================================================
{den, ...}: let
  fullName = "Kids";
in {
  den.aspects.kids = {user, ...}: {
    user = {
      # Account information
      description = fullName;

      # SSH authorized keys for the kids account.
      openssh.authorizedKeys.keys = [];
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
      (den.batteries.user-shell "fish")
      den.aspects.persisted-home
      den.aspects.fish
      den.aspects.user-ssh-key
      den.aspects.user-age-key
      den.aspects.sops-home
    ];
  };
}
