# ============================================================================
# Git identity
# ============================================================================
_: {
  den.aspects.git.provides.to-users = {user, ...}: {
    homeManager = {config, ...}: {
      sops.secrets."email/${user.userName}" = {};

      sops.templates.git-email.content = ''
        [user]
          email = ${config.sops.placeholder."email/${user.userName}"}
      '';

      programs.git = {
        enable = true;

        settings = {
          user.name = user.fullName or user.userName;
          init.defaultBranch = "main";
        };

        includes = [{path = config.sops.templates.git-email.path;}];
      };
    };
  };
}
