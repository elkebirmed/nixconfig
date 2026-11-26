# ============================================================================
# NVF Lua
# Extra Lua helpers, filetype detection, and Snacks toggles.
# ============================================================================
_: {
  den.aspects.nvf.lua = {
    homeManager.programs.nvf.settings.vim = {
      luaConfigRC.me-extras = ''
        -- Root dir helper (git root or cwd), used by the Snacks keymaps.
        _G.Root = function()
          local ok, root = pcall(function() return Snacks.git.get_root() end)
          return (ok and root) or vim.uv.cwd()
        end

        -- extras.util.dot (dotfiles): filetype detection for common config files.
        vim.filetype.add({

          extension = { env = "dotenv" },
          filename = {
            [".env"] = "dotenv",
            ["env"] = "dotenv",
            ["tsconfig.json"] = "jsonc",
            [".yamlfmt"] = "yaml",
            ["docker-compose.yml"] = "yaml.docker-compose",
            ["docker-compose.yaml"] = "yaml.docker-compose",
            ["compose.yml"] = "yaml.docker-compose",
            ["compose.yaml"] = "yaml.docker-compose",
          },
          pattern = {
            ["[jt]sconfig.*.json"] = "jsonc",
            ["%.env%.[%w_.-]+"] = "dotenv",
            [".*/git/config"] = "gitconfig",
            [".*/%.?gitconfig.*"] = "gitconfig",
            [".*/waybar/config"] = "jsonc",
            [".*/mako/config"] = "dosini",
            [".*/kitty/.+%.conf"] = "bash",
            [".*/hypr/.+%.conf"] = "hyprlang",
            [".*/ghostty/config"] = "toml",
            [".*/alacritty/.+%.toml"] = "toml",
            [".*/fish/.+%.fish"] = "fish",
          },
        })

        -- Snacks toggles
        vim.schedule(function()
          if not _G.Snacks then return end
          Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
          Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
          Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
          Snacks.toggle.diagnostics():map("<leader>ud")
          Snacks.toggle.line_number():map("<leader>ul")
          Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "Conceal Level" }):map("<leader>uc")
          Snacks.toggle.option("showtabline", { off = 0, on = vim.o.showtabline > 0 and vim.o.showtabline or 2, name = "Tabline" }):map("<leader>uA")
          Snacks.toggle.treesitter():map("<leader>uT")
          Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
          Snacks.toggle.dim():map("<leader>uD")
          Snacks.toggle.animate():map("<leader>ua")
          Snacks.toggle.indent():map("<leader>ug")
          Snacks.toggle.scroll():map("<leader>uS")
          Snacks.toggle.zen():map("<leader>uz")
          Snacks.toggle.profiler():map("<leader>dpp")
          Snacks.toggle.profiler_highlights():map("<leader>dph")
          Snacks.toggle({
            name = "Treesitter Context",
            get = function() return require("treesitter-context").enabled() end,
            set = function(state)
              if state then require("treesitter-context").enable() else require("treesitter-context").disable() end
            end,
          }):map("<leader>ut")
        end)
      '';
    };
  };
}
