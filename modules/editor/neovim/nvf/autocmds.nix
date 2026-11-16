# ============================================================================
# NVF Autocmds Configuration
# ============================================================================
_: {
  den.aspects.nvf.autocmds = {
    homeManager = {lib, ...}: let
      lua = lib.generators.mkLuaInline;
    in {
      programs.nvf.settings.vim = {
        augroups = [
          {
            name = "me_autocmds";
            clear = true;
          }
        ];

        autocmds = [
          {
            event = ["FocusGained" "TermClose" "TermLeave"];
            pattern = ["*"];
            group = "me_autocmds";
            desc = "Check if we need to reload the file when it changed";

            command = "checktime";
          }
          {
            event = ["TextYankPost"];

            pattern = ["*"];
            group = "me_autocmds";
            desc = "Highlight when yanking text";
            callback = lua ''function() vim.hl.on_yank() end'';
          }
          {
            event = ["VimResized"];
            pattern = ["*"];
            group = "me_autocmds";
            desc = "Resize splits if window got resized";
            callback = lua ''
              function()
                local current_tab = vim.fn.tabpagenr()
                vim.cmd("tabdo wincmd =")
                vim.cmd("tabnext " .. current_tab)
              end
            '';
          }
          {
            event = ["BufReadPost"];
            pattern = ["*"];
            group = "me_autocmds";
            desc = "Go to last loc when opening a buffer";
            callback = lua ''
              function(event)
                local exclude = { "gitcommit" }
                local buf = event.buf
                if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].me_last_loc then
                  return
                end
                vim.b[buf].me_last_loc = true
                local mark = vim.api.nvim_buf_get_mark(buf, '"')
                local lcount = vim.api.nvim_buf_line_count(buf)
                if mark[1] > 0 and mark[1] <= lcount then
                  pcall(vim.api.nvim_win_set_cursor, 0, mark)
                end
              end
            '';
          }
          {
            event = ["FileType"];
            pattern = [
              "PlenaryTestPopup"
              "checkhealth"
              "dbout"
              "gitsigns-blame"
              "grug-far"
              "help"
              "lspinfo"
              "neotest-output"
              "neotest-output-panel"
              "neotest-summary"
              "notify"
              "qf"
              "spectre_panel"
              "startuptime"
              "tsplayground"
            ];
            group = "me_autocmds";
            desc = "Close some filetypes with <q>";

            callback = lua ''
              function(event)

                vim.bo[event.buf].buflisted = false
                vim.schedule(function()
                  vim.keymap.set("n", "q", function()
                    vim.cmd("close")
                    pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
                  end, { buffer = event.buf, silent = true, desc = "Quit buffer" })
                end)
              end
            '';
          }
          {
            event = ["FileType"];
            pattern = ["man"];
            group = "me_autocmds";
            desc = "Make man pages unlisted";
            callback = lua ''function(event) vim.bo[event.buf].buflisted = false end'';
          }
          {
            event = ["FileType"];
            pattern = ["text" "plaintex" "typst" "gitcommit" "markdown"];
            group = "me_autocmds";
            desc = "Wrap and check for spell in text filetypes";
            callback = lua ''
              function()
                vim.opt_local.wrap = true
                vim.opt_local.spell = true
              end
            '';
          }
          {
            event = ["FileType"];
            pattern = ["json" "jsonc" "json5"];
            group = "me_autocmds";
            desc = "Fix conceallevel for json files";
            callback = lua ''function() vim.opt_local.conceallevel = 0 end'';
          }
          {
            event = ["BufWritePre"];
            pattern = ["*"];
            group = "me_autocmds";
            desc = "Auto create dir when saving a file";
            callback = lua ''
              function(event)
                if event.match:match("^%w%w+:[\\/][\\/]") then
                  return
                end
                local file = vim.uv.fs_realpath(event.match) or event.match
                vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
              end
            '';
          }
          # extras.linting.eslint: fix on save
          {
            event = ["BufWritePre"];
            pattern = ["*.js" "*.jsx" "*.ts" "*.tsx" "*.mjs" "*.cjs"];
            group = "me_autocmds";
            desc = "ESLint fix all on save";
            callback = lua ''

              function(event)
                local client = vim.lsp.get_clients({ bufnr = event.buf, name = "eslint" })[1]
                if client then
                  vim.cmd("silent! LspEslintFixAll")
                end
              end
            '';
          }
        ];
      };
    };
  };
}
