# ============================================================================
# NVF Extras
# Additional plugins wired through nvf, plus the language toolchains that the
# LSP, DAP, formatter, and test adapters shell out to.
# ============================================================================
_: {
  den.aspects.nvf.extras = {
    homeManager = {pkgs, ...}: {
      programs.nvf.settings.vim = {
        # ------------------------------------------------------------------
        # Editing: motions and operators
        # ------------------------------------------------------------------
        mini = {
          # mini.bracketed targets that would otherwise clobber mappings
          # defined in keymaps.nix (buffers, diagnostics, quickfix, treesitter
          # windows, yank history) are disabled with an empty suffix; the
          # remaining targets add the new [ ] motions.
          bracketed = {
            enable = true;
            setupOpts = {
              buffer.suffix = "";
              diagnostic.suffix = "";
              quickfix.suffix = "";
              treesitter.suffix = "";
              window.suffix = "";
              yank.suffix = "";
            };
          };

          # The stock prefixes collide with existing bindings: `gr` (LSP
          # references), `gs` (mini.surround), and builtin `gx`. Remap the
          # whole operator family behind `gz` instead.
          operators = {
            enable = true;
            setupOpts = {
              evaluate.prefix = "gz=";
              exchange.prefix = "gzx";
              multiply.prefix = "gzm";
              replace.prefix = "gzr";
              sort.prefix = "gzs";
            };
          };

          align.enable = true;
        };

        # ------------------------------------------------------------------
        # UI / readability
        # ------------------------------------------------------------------
        ui = {
          # dropbar's defaults already limit the bar to buffers that have an
          # LSP or treesitter symbol source, so no overrides are needed.
          dropbar-nvim.enable = true;

          illuminate = {
            enable = true;
            setupOpts = {
              delay = 120;
              filetypes_denylist = [
                "dirvish"
                "fugitive"
                "help"
                "neo-tree"
                "notify"
                "NvimTree"
                "TelescopePrompt"
                "snacks_dashboard"
                "snacks_explorer"
                "snacks_picker_input"
                "snacks_picker_list"
              ];
            };
          };

          colorizer = {
            enable = true;
            setupOpts.user_default_options = {
              RGB = true;
              RRGGBB = true;
              RRGGBBAA = true;
              AARRGGBB = true;
              names = false;
              rgb_fn = true;
              hsl_fn = true;
              css = true;
              tailwind = true;
              mode = "background";
            };
          };
        };

        # nvim-ufo is intentionally absent: it calls `require("async")(...)`,
        # but refactoring.nvim depends on async.nvim which puts a non-callable
        # table in `lua/async.lua`, while promise-async ships a different
        # callable under the same name. refactoring needs `async.wrap` and ufo
        # needs `async(...)`, so the two cannot coexist. Treesitter folding
        # (treesitter.nix) provides folds instead.

        # ------------------------------------------------------------------
        # Git: diff/history UI, pinned files, GitHub, shareable links
        # ------------------------------------------------------------------
        # Harpoon's stock <leader>a / <C-j|k|l> bindings collide with the
        # CodeCompanion `a` group and window navigation, so move to <leader>h.
        navigation.harpoon = {
          enable = true;
          mappings = {
            markFile = "<leader>ha";
            listMarks = "<leader>hh";
            file1 = "<leader>h1";
            file2 = "<leader>h2";
            file3 = "<leader>h3";
            file4 = "<leader>h4";
          };
        };

        git = {
          octo-nvim = {
            enable = true;
            setupOpts.picker = "snacks";
          };
          gitlinker-nvim.enable = true;
        };

        # ------------------------------------------------------------------
        # Tools: multicursors, CSV tables, diff/history, undo tree, direnv
        # ------------------------------------------------------------------
        # direnv.vim and nix-develop.nvim shell out to `direnv` / `nix`.
        utility = {
          multicursors.enable = true;

          csvview = {
            enable = true;
            autoEnable = true;
            mappings.toggle = "<leader>um";
          };

          diffview-nvim.enable = true;
          undotree.enable = true;
          direnv.enable = true;
          nix-develop.enable = true;
        };

        # ------------------------------------------------------------------
        # Toolchains
        # The LSP servers, formatters, linters, and test adapters are wired by
        # absolute path, but gopls, rust-analyzer, neotest, and direnv still
        # invoke plain `go`, `cargo`, `rustc`, `python3`, and `direnv` from
        # PATH. `glib` provides `gio trash`, which the Snacks explorer needs
        # for non-permanent deletes.
        # ------------------------------------------------------------------
        extraPackages = with pkgs; [
          glib
          go
          gofumpt
          cargo
          rustc
          python3
          direnv
          gcc
        ];
      };
    };
  };
}
