# ============================================================================
# NVF AI Configuration
# ============================================================================
_: {
  den.aspects.nvf.ai = {
    homeManager = {
      lib,
      pkgs,
      ...
    }: {
      programs.nvf.settings.vim = {
        # Shared OmniRoute helper, available to every plugin via
        # `require("omniroute")`.
        luaConfigRC.omniroute = ''
          -- Local OmniRoute gateway (free auto-routed models).
          package.preload["omniroute"] = function()
            local base_url = "http://127.0.0.1:20128"

            local M = {
              -- Gateway base URL without /v1; CodeCompanion's adapter appends
              -- /v1/chat/completions itself.
              base_url = base_url,
              -- OpenAI-compatible base URL, including /v1.
              url = function()
                return base_url .. "/v1"
              end,
              -- Read the gateway key on every call so rotated keys are picked
              -- up without restarting Neovim.
              api_key = function()
                local f = io.open("/var/lib/omniroute-bootstrap/api-key", "r")
                if not f then
                  return nil
                end
                local key = f:read("l")
                f:close()
                return key
              end,
              model = "auto/coding:free",
              models = {
                "auto/coding:free",
                "auto/reasoning:free",
                "auto/vision:free",
                "auto/chat:free",
                "auto/best-free",
              },
              completion_model = "auto/coding:free",
            }

            return M
          end
        '';

        # Minuet installs its FileType autocmd when the lazy plugin loads on
        # InsertEnter, which is after the current buffer's FileType already
        # fired. Seed the per-buffer switch ourselves so the first buffer
        # auto-triggers too.
        luaConfigRC.minuetAutoTrigger = ''
          vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
            group = vim.api.nvim_create_augroup("minuet-auto-trigger", { clear = true }),
            callback = function(args)
              local ignored = {
                "codecompanion",
                "codecompanion_chat_input",
                "codecompanion_input",
              }
              vim.b[args.buf].minuet_virtual_text_auto_trigger =
                not vim.tbl_contains(ignored, vim.bo[args.buf].filetype)
            end,
          })
        '';

        # AI agent backed by OmniRoute's free auto-routed models.
        assistant.codecompanion-nvim = {
          enable = true;
          setupOpts = {
            adapters = lib.generators.mkLuaInline ''
              {
                http = {
                  omniroute = function()
                    local omniroute = require("omniroute")
                    return require("codecompanion.adapters").extend("openai_compatible", {
                      formatted_name = "OmniRoute",
                      env = {
                        -- Base URL without /v1; the adapter appends
                        -- /v1/chat/completions.
                        url = omniroute.base_url,
                        api_key = "file:/var/lib/omniroute-bootstrap/api-key",
                      },
                      schema = {
                        model = {
                          default = omniroute.model,
                          choices = omniroute.models,
                        },
                      },
                    })
                  end,
                },
              }
            '';
            interactions = {
              chat.adapter = "omniroute";
              inline.adapter = "omniroute";
            };
          };
        };

        # Inline ghost-text completion (virtual text, not menu completion).
        lazy.plugins."minuet-ai.nvim" = {
          package = pkgs.vimPlugins.minuet-ai-nvim;
          setupModule = "minuet";
          event = "InsertEnter";
          setupOpts = {
            provider = "openai_compatible";
            # Free keyless routing is slow; keep requests small and infrequent.
            request_timeout = 4;
            throttle = 1500;
            debounce = 600;
            context_window = 6000;
            notify = "warn";
            provider_options = {
              openai_compatible = {
                api_key = lib.generators.mkLuaInline ''function() return require("omniroute").api_key() end'';
                end_point = lib.generators.mkLuaInline ''require("omniroute").url() .. "/chat/completions"'';
                model = lib.generators.mkLuaInline ''require("omniroute").completion_model'';
                name = "OmniRoute";
                stream = true;
                optional = {
                  max_tokens = 128;
                  temperature = 0.2;
                };
              };
            };
            virtualtext = {
              auto_trigger_ft = ["*"];
              auto_trigger_ignore_ft = ["codecompanion" "codecompanion_chat_input" "codecompanion_input"];
              keymap = {
                accept = "<A-A>";
                accept_line = "<A-a>";
                accept_n_lines = "<A-z>";
                prev = "<A-p>";
                next = "<A-n>";
                dismiss = "<A-e>";
              };
            };
          };
        };
      };
    };
  };
}
