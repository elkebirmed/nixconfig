# ============================================================================
# Managed User
# Shared wiring for the managed non-admin accounts (koko, kids).
#
# Both accounts get the same shell, secrets plumbing, desktop profile, and
# password wiring. Their own files only describe identity, keys, and the few
# per-account differences, so they stay a handful of lines.
# ============================================================================
{den, ...}: {
  den.aspects.managed-user = {user, ...}: {
    # Password hashes remain encrypted in SOPS and are needed before users
    # are created during boot. Declared once for every managed account.
    nixos = {config, ...}: {
      sops.secrets."passwords/${user.userName}" = {
        sopsFile = ../../../secrets/users + "/${user.userName}.yaml";
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
      den.aspects.desktop
    ];
  };
}
