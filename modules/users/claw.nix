# ============================================================================
# Claw User
# The dedicated, unprivileged OpenClaw gateway account. It has no sudo, no
# SSH access, and no group access to other homes or SOPS keys.
# ============================================================================
{den, ...}: {
  den.aspects.claw = {user, ...}: {
    user = {
      description = "OpenClaw gateway";

      # The gateway is reached over the local API, not SSH.
      openssh.authorizedKeys.keys = [];
    };

    includes = [
      den.batteries.define-user
      den.aspects.openclaw
    ];

    nixos = {
      users.users.${user.userName} = {
        uid = 1002;
        isNormalUser = true;
        homeMode = "0700";
        extraGroups = [];
        linger = true;
      };
    };
  };
}
