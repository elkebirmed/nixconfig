# ============================================================================
# Koko's user aspect
# ============================================================================
{den, ...}: let
  fullName = "Koko";
in {
  den.aspects.koko = {user, ...}: {
    user = {
      # Account information
      description = fullName;

      # SSH authorized keys for Mohamed's account.
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

    includes = [
      den.batteries.define-user
      (den.batteries.user-shell "fish")
      den.aspects.persisted-home
      den.aspects.fish
    ];
  };
}
