# ============================================================================
# GitHub CLI
# Configure gh and its SOPS-backed token.
# ============================================================================
_: {
  den.aspects.gh = {user, ...}: {
    homeManager = {config, ...}: {
      sops.secrets."github/${user.userName}" = {};
      # Render the SOPS token into gh's private hosts file.
      sops.templates.gh-hosts = {
        mode = "0600";
        content = ''
          github.com:
            git_protocol: https
            users:
              ${user.userName}:
                oauth_token: "${config.sops.placeholder."github/${user.userName}"}"
            user: ${user.userName}
            oauth_token: "${config.sops.placeholder."github/${user.userName}"}"
        '';
      };

      programs.gh = {
        enable = true;
        gitCredentialHelper.enable = true;
        settings = {
          git_protocol = "https";
          prompt = "enabled";
        };
      };

      xdg.configFile."gh/hosts.yml".source =
        config.lib.file.mkOutOfStoreSymlink config.sops.templates.gh-hosts.path;
    };
  };
}
