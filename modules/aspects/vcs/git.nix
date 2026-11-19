# ============================================================================
# Git
# Git identity with a SOPS-backed email address.
# ============================================================================
_: {
  den.aspects.git.provides.to-users = {user, ...}: {
    homeManager = {config, ...}: {
      sops.secrets."email/${user.userName}" = {};

      # Render the SOPS-backed email into a git include.
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
