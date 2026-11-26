# ============================================================================
# Yazi
# Yazi file manager with preview dependencies and its Fish wrapper.
# ============================================================================
_: {
  den.aspects.yazi = {user, ...}: {
    homePersistence = {
      inherit (user) userName;
      directories = [".local/state/yazi"];
    };

    homeManager = {pkgs, ...}: {
      programs.yazi = {
        enable = true;

        # Defines the `y` Fish function so exiting yazi changes the cwd.
        enableFishIntegration = true;
        shellWrapperName = "y";

        # Tools used by yazi's previewers.
        extraPackages = with pkgs; [
          ffmpeg
          p7zip
          poppler-utils
          fd
          ripgrep
          fzf
          jq
        ];

        settings = {
          mgr = {
            show_hidden = true;
            show_symlink = true;
            ratio = [1 4 3];
            sort_by = "natural";
            linemode = "size";
            scrolloff = 5;
          };

          preview = {
            wrap = "no";
            tab_size = 2;
            max_width = 1000;
            max_height = 1000;
          };
        };

        # The theme is rendered by Noctalia into theme.toml.
        keymap.mgr.prepend_keymap = [
          {
            on = "T";
            run = "shell 'lazygit' --block";
            desc = "Open Lazygit";
          }
        ];
      };

      xdg.configFile = {
        # yazi does not ship a Fish completion file.
        "fish/completions/yazi.fish".text = ''
          complete -c yazi -l cwd-file -r -F -d "Write the cwd on exit"
          complete -c yazi -l chooser-file -r -F -d "Write selected files on open"
          complete -c yazi -l client-id -r -d "Use a specific client ID"
          complete -c yazi -l local-events -r -d "Report local events to stdout"
          complete -c yazi -l remote-events -r -d "Report remote events to stdout"
          complete -c yazi -s V -l version -d "Show version"
          complete -c yazi -s h -l help -d "Show help"
          complete -c yazi -F
        '';

        # The `y` wrapper accepts the same arguments as yazi.
        "fish/completions/y.fish".text = "complete -c y -w yazi\n";
      };
    };
  };
}
