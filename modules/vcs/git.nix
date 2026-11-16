# ============================================================================
# Git identity
# ============================================================================
{
  # Keep OS secret generation and Home Manager Git configuration together as
  # one user-scoped feature.
  den.aspects.git = {user, ...}: {
    nixos = {config, ...}: {
      # Render the user's email secret to a Git-readable include file.
      sops.secrets."email/${user.userName}" = {};
      sops.templates."git-${user.userName}" = {
        owner = user.userName;
        content = ''
          [user]
            email = ${config.sops.placeholder."email/${user.userName}"}
        '';
      };
    };

    provides.to-users = {user, ...}: {
      homeManager = {osConfig, ...}: {
        # Keep the public author name in Nix and load only the secret email.
        programs.git = {
          enable = true;

          settings = {
            # Keep email out of the store; it comes from the SOPS include.
            user.name = user.fullName or user.userName;
            init.defaultBranch = "main";
          };

          # Load the generated, user-owned email configuration.
          includes = [
            {path = osConfig.sops.templates."git-${user.userName}".path;}
          ];
        };
      };
    };
  };
}
