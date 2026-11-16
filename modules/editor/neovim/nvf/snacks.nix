# ============================================================================
# NVF Snacks Configuration
# ============================================================================
_: {
  den.aspects.nvf.snacks = {
    homeManager.programs.nvf.settings.vim = {
      utility.snacks-nvim = {
        enable = true;
        setupOpts = {
          bigfile.enabled = true;
          dashboard = {
            enabled = true;
            preset = {
              header = ''
                ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
                ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
                ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
                ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
                ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
                ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
              '';
              keys = [
                {
                  key = "f";
                  desc = "Find File";
                  action = ":lua Snacks.picker.files()";
                }
                {
                  key = "n";
                  desc = "New File";
                  action = ":enew";
                }
                {
                  key = "r";
                  desc = "Recent Files";
                  action = ":lua Snacks.picker.recent()";
                }
                {
                  key = "g";
                  desc = "Find Text";
                  action = ":lua Snacks.picker.grep()";
                }
                {
                  key = "c";
                  desc = "Config";
                  action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })";
                }
                {
                  key = "s";
                  desc = "Restore Session";
                  action = ":lua require('persistence').load()";
                }
                {
                  key = "p";
                  desc = "Projects";
                  action = ":lua Snacks.picker.projects()";
                }
                {
                  key = "q";
                  desc = "Quit";
                  action = ":qa";
                }
              ];
            };
            sections = [
              {section = "header";}
              {
                section = "keys";
                gap = 1;
                padding = 1;
              }
              {
                text = "Mohamed Elkebir";
                align = "center";
                padding = 1;
              }
            ];
          };
          explorer.enabled = true;
          indent.enabled = true;
          input.enabled = true;
          notifier = {
            enabled = true;
            timeout = 3000;
          };
          picker = {
            enabled = true;
            sources.explorer.replace_netrw = true;
          };
          quickfile.enabled = true;
          scope.enabled = true;
          scroll.enabled = true;
          statuscolumn.enabled = true;
          words.enabled = true;
          bufdelete.enabled = true;
          git.enabled = true;
          gitbrowse.enabled = true;
          lazygit.enabled = true;
          rename.enabled = true;
          scratch.enabled = true;
          terminal.enabled = true;
          toggle.enabled = true;
          zen.enabled = true;
          dim.enabled = true;
          profiler.enabled = true;
          styles.snacks_image = {};
        };
      };
    };
  };
}
