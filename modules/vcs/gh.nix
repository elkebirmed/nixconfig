# ============================================================================
# GitHub CLI
# ============================================================================
{lib, ...}: {
  # The token lives in the user's SOPS file; GitHub CLI reads the
  # activation-rendered hosts.yml instead of a world-readable store file.
  den.aspects.gh = {user, ...}: {
    nixos = {config, ...}: {
      sops.secrets."github/${user.userName}" = {
        sopsFile = ../../secrets/users + "/${user.userName}.yaml";
      };

      sops.templates."gh-hosts-${user.userName}" = {
        owner = user.userName;
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
    };

    homeManager = {
      config,
      osConfig,
      ...
    }: {
      programs.gh = {
        enable = true;
        gitCredentialHelper.enable = true;
        settings = {
          git_protocol = "https";
          prompt = "enabled";
        };
      };

      # `programs.gh.hosts` would put the token in the Nix store; link the
      # rendered template instead. Standalone Home Manager has no osConfig,
      # so it only gets the CLI and can authenticate itself.
      xdg.configFile."gh/hosts.yml" = lib.mkIf (osConfig != null) {
        source = config.lib.file.mkOutOfStoreSymlink osConfig.sops.templates."gh-hosts-${user.userName}".path;
      };
    };
  };
}
