# ============================================================================
# Lazygit
# Lazygit with a static config and a Noctalia-rendered theme.
#
# The theme file is written at runtime by Noctalia. `LG_CONFIG_FILE` merges it
# over the Home Manager config without letting a hook rewrite a store symlink.
# ============================================================================
_: {
  den.aspects.lazygit.homeManager = {
    lib,
    config,
    ...
  }: let
    themeFile = "${config.xdg.configHome}/lazygit/themes/noctalia.yml";
  in {
    programs.lazygit = {
      enable = true;

      settings = {
        gui = {
          nerdFontsVersion = "3";
          showFileTree = true;
        };

        git.paging.colorArg = "always";
      };
    };

    # Comma-separated list; the later files override the earlier ones.
    home.sessionVariables.LG_CONFIG_FILE = "${config.xdg.configHome}/lazygit/config.yml,${themeFile}";

    # lazygit fails if a config file in the list does not exist, so seed an
    # empty theme file on activation. Noctalia overwrites it on the next apply.
    home.activation.lazygitThemeFile = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run mkdir -p "$(dirname ${lib.escapeShellArg themeFile})"
      if [ ! -e ${lib.escapeShellArg themeFile} ]; then
        run touch ${lib.escapeShellArg themeFile}
      fi
    '';
  };
}
