# ============================================================================
# NVF Completion Configuration
# ============================================================================
_: {
  den.aspects.nvf.completion = {
    homeManager = {lib, ...}: let
      lua = lib.generators.mkLuaInline;
    in {
      programs.nvf.settings.vim = {
        autocomplete.blink-cmp = {
          enable = true;
          friendly-snippets.enable = true;

          # Extra sources
          sourcePlugins = {
            emoji.enable = true;
            ripgrep.enable = true;
            spell.enable = true;
          };

          setupOpts = {
            appearance = {
              use_nvim_cmp_as_default = true;
              nerd_font_variant = "mono";
            };
            signature.enabled = true;

            completion = {
              accept.auto_brackets.enabled = true;
              menu.draw.treesitter = ["lsp"];
              documentation = {
                auto_show = true;
                auto_show_delay_ms = 200;
              };
              ghost_text.enabled = false;
            };

            keymap.preset = "default";

            cmdline = {
              enabled = true;

              keymap = {
                preset = "cmdline";
                # nvf's keymap option only accepts lists; blink treats an empty
                # list like `false` and removes the mapping from the preset.
                "<Right>" = [];
                "<Left>" = [];
              };
              completion = {
                list.selection.preselect = false;
                menu.auto_show = lua ''function(ctx) return vim.fn.getcmdtype() == ":" end'';
                ghost_text.enabled = true;
              };
            };

            sources = {
              default = lib.mkForce ["lsp" "path" "snippets" "buffer"];
              per_filetype = {
                sql = ["snippets" "dadbod" "buffer"];
                codecompanion = ["codecompanion" "lsp" "path" "snippets" "buffer"];
                codecompanion_chat_input = ["codecompanion" "lsp" "path" "snippets" "buffer"];
                codecompanion_input = ["codecompanion" "lsp" "path" "snippets" "buffer"];
              };
              providers.dadbod = {
                name = "Dadbod";
                module = "vim_dadbod_completion.blink";
              };
            };
          };
        };
      };
    };
  };
}
