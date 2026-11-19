# ============================================================================
# NVF Plugins
# Extra plugins wired directly through nvf's settings.
# ============================================================================
_: {
  den.aspects.nvf.plugins = {
    homeManager = {pkgs, ...}: let
      # neotest-golang declares nvim-dap-go as a dependency, but nvf already
      # manages that plugin through `vim.languages.go.dap`. Keeping both makes
      # mnw install it in /start and /opt, so drop the redundant dependency.
      neotest-golang = pkgs.vimPlugins.neotest-golang.overrideAttrs (old: {
        dependencies =
          builtins.filter
          (dep: (dep.pname or dep.name or "") != "nvim-dap-go")
          (old.dependencies or []);
      });
    in {
      programs.nvf.settings.vim = {
        # Dashboard: Snacks (nvf's built-in dashboards disabled)
        dashboard.alpha.enable = false;
        dashboard.dashboard-nvim.enable = false;

        extraPlugins = {
          # Persistence
          persistence = {
            package = pkgs.vimPlugins.persistence-nvim;
            setup = ''require("persistence").setup()'';
          };

          # Grug Far
          grug-far = {
            package = pkgs.vimPlugins.grug-far-nvim;
            setup = ''require("grug-far").setup({ headerMaxWidth = 80 })'';
          };

          # SchemaStore
          schemastore.package = pkgs.vimPlugins.SchemaStore-nvim;

          # Yanky
          yanky = {
            package = pkgs.vimPlugins.yanky-nvim;
            setup = ''
              require("yanky").setup({
                highlight = { timer = 150 },
              })
            '';
          };

          # Dial
          dial = {
            package = pkgs.vimPlugins.dial-nvim;
            setup = ''

              local augend = require("dial.augend")
              local logical_alias = augend.constant.new({
                elements = { "&&", "||" },
                word = false,
                cyclic = true,
              })
              local ordinal_numbers = augend.constant.new({
                elements = { "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth" },
                word = false,
                cyclic = true,
              })
              local weekdays = augend.constant.new({
                elements = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" },
                word = true,
                cyclic = true,
              })
              local months = augend.constant.new({
                elements = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" },
                word = true,
                cyclic = true,
              })
              local capitalized_boolean = augend.constant.new({
                elements = { "True", "False" },
                word = true,
                cyclic = true,
              })
              require("dial.config").augends:register_group({
                default = {
                  augend.integer.alias.decimal,
                  augend.integer.alias.hex,
                  augend.date.alias["%Y/%m/%d"],
                  augend.constant.alias.bool,
                  augend.semver.alias.semver,
                  augend.constant.new({ elements = { "let", "const" } }),
                  ordinal_numbers, weekdays, months,
                },

                typescript = {
                  augend.integer.alias.decimal, augend.integer.alias.hex,
                  augend.constant.new({ elements = { "let", "const" } }),
                },
                css = {
                  augend.integer.alias.decimal, augend.integer.alias.hex,
                  augend.hexcolor.new({ case = "lower" }),
                  augend.hexcolor.new({ case = "upper" }),
                },
                markdown = {
                  augend.constant.new({ elements = { "[ ]", "[x]" }, word = false, cyclic = true }),
                  augend.misc.alias.markdown_header,
                },
                json = { augend.integer.alias.decimal, augend.semver.alias.semver },
                lua = {
                  augend.integer.alias.decimal,
                  augend.constant.alias.bool,
                  augend.constant.new({ elements = { "and", "or" }, word = true, cyclic = true }),
                },
                python = {
                  augend.integer.alias.decimal,
                  capitalized_boolean,
                  logical_alias,
                },
              })
            '';
          };

          # IncRename
          inc-rename = {
            package = pkgs.vimPlugins.inc-rename-nvim;
            setup = ''require("inc_rename").setup()'';
          };

          # Refactoring
          refactoring = {
            package = pkgs.vimPlugins.refactoring-nvim;
            setup = ''require("refactoring").setup({})'';
          };

          # Edgy
          edgy = {
            package = pkgs.vimPlugins.edgy-nvim;
            setup = ''
              require("edgy").setup({
                animate = { enabled = true },
                exit_when_last = true,
                bottom = {
                  {
                    ft = "snacks_terminal",
                    size = { height = 0.4 },
                    title = "%{b:snacks_terminal.id}: %{b:term_title}",
                    filter = function(_buf, win)
                      return vim.w[win].snacks_win
                        and vim.w[win].snacks_win.position == "bottom"

                        and vim.w[win].snacks_win.relative == "editor"
                        and not vim.w[win].trouble_preview
                    end,
                  },
                  {
                    ft = "trouble",
                    size = { height = 0.4 },
                    filter = function(_buf, win)
                      return vim.w[win].trouble
                        and vim.w[win].trouble.position == "bottom"
                        and vim.w[win].trouble.type == "split"
                        and vim.w[win].trouble.relative == "editor"
                        and not vim.w[win].trouble_preview
                    end,
                  },
                  { ft = "qf", title = "QuickFix" },
                  {
                    ft = "help",
                    size = { height = 20 },
                    filter = function(buf) return vim.bo[buf].buftype == "help" end,
                  },
                  { title = "Neotest Output", ft = "neotest-output-panel", size = { height = 15 } },
                },
                left = {
                  { title = "Neotest Summary", ft = "neotest-summary" },
                },
                right = {
                  { title = "Grug Far", ft = "grug-far", size = { width = 0.4 } },
                },
                keys = {
                  ["<c-Right>"] = function(win) win:resize("width", 2) end,
                  ["<c-Left>"]  = function(win) win:resize("width", -2) end,
                  ["<c-Up>"]    = function(win) win:resize("height", 2) end,
                  ["<c-Down>"]  = function(win) win:resize("height", -2) end,
                },
              })
            '';
          };

          # Neotest
          nvim-nio.package = pkgs.vimPlugins.nvim-nio;
          neotest-python.package = pkgs.vimPlugins.neotest-python;
          neotest-golang.package = neotest-golang;
          neotest-jest.package = pkgs.vimPlugins.neotest-jest;
          neotest = {
            package = pkgs.vimPlugins.neotest;
            setup = ''
              local adapters = {}
              local function add(name, opts)
                local ok, mod = pcall(require, name)
                if ok then
                  table.insert(adapters, opts and mod(opts) or mod)
                end
              end
              add("neotest-python", { dap = { justMyCode = false } })
              add("neotest-golang")
              add("neotest-jest", {})
              add("rustaceanvim.neotest")
              require("neotest").setup({
                adapters = adapters,
                status = { virtual_text = true },
                output = { open_on_run = true },
                quickfix = {
                  open = function() require("trouble").open({ mode = "quickfix", focus = false }) end,
                },
              })
            '';
          };

          # Dadbod
          vim-dadbod.package = pkgs.vimPlugins.vim-dadbod;
          vim-dadbod-completion.package = pkgs.vimPlugins.vim-dadbod-completion;
          vim-dadbod-ui = {
            package = pkgs.vimPlugins.vim-dadbod-ui;
            setup = ''
              vim.g.db_ui_use_nerd_fonts = 1
              vim.g.db_ui_show_database_icon = 1
              vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/dadbod_ui"
            '';
          };

          # Markdown Preview
          markdown-preview.package = pkgs.vimPlugins.markdown-preview-nvim;

          # Treesitter Textobjects
          treesitter-textobjects.package = pkgs.vimPlugins.nvim-treesitter-textobjects;
        };
      };
    };
  };
}
