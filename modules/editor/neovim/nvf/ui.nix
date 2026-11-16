# ============================================================================
# NVF UI Configuration
# ============================================================================
_: {
  den.aspects.nvf.ui = {
    homeManager = {lib, ...}: let
      lua = lib.generators.mkLuaInline;
    in {
      programs.nvf.settings.vim = {
        telescope.enable = false; # Using Snacks.picker
        filetree.neo-tree.enable = false; # Using Snacks.explorer

        git.enable = true;
        git.gitsigns = {
          enable = true;
          setupOpts = {
            # mini.diff extra draws the signs; gitsigns keeps hunk actions/blame.
            signcolumn = false;
            signs = {
              add.text = "▎";
              change.text = "▎";
              delete.text = "";
              topdelete.text = "";
              changedelete.text = "▎";
              untracked.text = "▎";
            };
            signs_staged = {
              add.text = "▎";
              change.text = "▎";
              delete.text = "";
              topdelete.text = "";
              changedelete.text = "▎";
            };
          };
        };

        statusline.lualine = {
          enable = true;
          setupOpts.options = {
            theme = "auto";
            globalstatus = true;
            disabled_filetypes.statusline = ["dashboard" "alpha" "ministarter" "snacks_dashboard"];
          };
        };

        tabline.nvimBufferline = {
          enable = true;
          setupOpts.options = {
            diagnostics = "nvim_lsp";
            always_show_bufferline = false;
            close_command = lua ''function(n) Snacks.bufdelete(n) end'';
            right_mouse_command = lua ''function(n) Snacks.bufdelete(n) end'';
            diagnostics_indicator = lua ''
              function(_, _, diag)
                local icons = { Error = " ", Warn = " " }
                local ret = (diag.error and icons.Error .. diag.error .. " " or "")
                  .. (diag.warning and icons.Warn .. diag.warning or "")
                return vim.trim(ret)
              end
            '';
            offsets = [
              {
                filetype = "snacks_layout_box";
              }
            ];
          };
        };

        # mini.* (pairs/icons core; ai, comment, surround, diff, hipatterns extras)
        mini = {
          pairs.enable = true;
          icons.enable = true;
          ai = {
            enable = true;
            setupOpts.n_lines = 500;
          };
          comment.enable = true; # extras.mini-comment
          surround = {
            enable = true; # extras.mini-surround
            setupOpts.mappings = {
              add = "gsa";
              delete = "gsd";
              find = "gsf";
              find_left = "gsF";
              highlight = "gsh";
              replace = "gsr";
              update_n_lines = "gsn";
            };
          };
          diff = {
            enable = true; # extras.mini-diff
            setupOpts.view = {
              style = "sign";
              signs = {
                add = "▎";
                change = "▎";
                delete = "";
              };
            };
          };
          hipatterns.enable = true; # extras.mini-hipatterns
        };
        visuals.nvim-web-devicons.enable = true;

        # Flash
        utility.motion.flash-nvim = {
          enable = true;
          mappings = {
            jump = "s";
            treesitter = "S";
            remote = "r";
            treesitter_search = "R";
            toggle = "<c-s>";
          };
        };

        notes.todo-comments.enable = true;

        # Aerial
        utility.outline.aerial-nvim.enable = true;

        # Project
        projects.project-nvim.enable = true;

        # Dap
        debugger.nvim-dap = {
          enable = true;
          ui.enable = true;
        };

        # Notify
        notify.nvim-notify.enable = true;

        # Noice
        ui.noice = {
          enable = true;
          setupOpts = {
            lsp.override = {
              "vim.lsp.util.convert_input_to_markdown_lines" = true;
              "vim.lsp.util.stylize_markdown" = true;
              "cmp.entry.get_documentation" = true;
            };
            presets = {
              bottom_search = true;
              command_palette = true;
              long_message_to_split = true;
              inc_rename = true;
              lsp_doc_border = true;
            };
          };
        };

        # WhichKey
        binds.whichKey = {
          enable = true;
          setupOpts.preset = "helix";
          register = {
            "<leader><tab>" = "+Tabs";
            "<leader>b" = "+Buffer";
            "<leader>c" = "+Code";
            "<leader>d" = "+Debug";
            "<leader>dp" = "+Profiler";
            "<leader>f" = "+File/Find";
            "<leader>g" = "+Git";
            "<leader>gh" = "+Hunks";
            "<leader>q" = "+Quit/Session";
            "<leader>r" = "+Refactor";
            "<leader>s" = "+Search";
            "<leader>t" = "+Test";
            "<leader>u" = "+UI";
            "<leader>w" = "+Windows";
            "<leader>x" = "+Diagnostics/Quickfix";
            "gs" = "+Surround";
            "[" = "+Prev";
            "]" = "+Next";
            "g" = "+Goto";
            "z" = "+Fold";
          };
        };
      };
    };
  };
}
