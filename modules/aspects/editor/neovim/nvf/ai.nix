# ============================================================================
# NVF AI
# Command Code Provider API helper plus CodeCompanion and Minuet integrations.
#
# This used to talk to OmniRoute, a local gateway container; there is no local
# service to run now, so there is no bootstrap key file to wait on either.
# ============================================================================
let
  cc = import ../../../ai/_commandcode-lib.nix;

  # Model IDs are sent verbatim to the API, so `choices` is a list of ids.
  modelIds = map (m: m.id) cc.models;
in {
  den.aspects.nvf.ai = {
    homeManager = {
      lib,
      pkgs,
      osConfig,
      ...
    }: let
      # The key stays in SOPS; it is read at call time, so a rotated key takes
      # effect without restarting Neovim.
      apiKeyPath =
        osConfig.sops.secrets."cmdc/api-key".path
        or "/run/secrets/cmdc/api-key";
    in {
      programs.nvf.settings.vim = {
        # Shared helper, available to every plugin via require("commandcode").
        luaConfigRC.commandcode = ''
          package.preload["commandcode"] = function()
            local provider_root = "${cc.providerRoot}"
            local key_path = "${apiKeyPath}"

            local M = {
              -- Root without /v1: CodeCompanion's adapter appends
              -- /v1/chat/completions itself.
              base_url = provider_root,
              -- Full base including /v1, for clients that append only
              -- /chat/completions (Minuet).
              url = function()
                return provider_root .. "/v1"
              end,
              key_path = key_path,
              -- Read the key from SOPS on every call so rotated keys are
              -- picked up without restarting Neovim.
              api_key = function()
                local f = io.open(key_path, "r")
                if not f then
                  return nil
                end
                local key = f:read("l")
                f:close()
                return key
              end,
              model = "${cc.defaultModel}",
              completion_model = "${cc.fastModel}",
              models = {
                "${lib.concatStringsSep "\",\n                \"" modelIds}"
              },
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

        # AI agent backed by the Command Code Provider API.
        assistant.codecompanion-nvim = {
          enable = true;
          setupOpts = {
            adapters = lib.generators.mkLuaInline ''
              {
                http = {
                  commandcode = function()
                    local commandcode = require("commandcode")
                    return require("codecompanion.adapters").extend("openai_compatible", {
                      formatted_name = "Command Code",
                      env = {
                        -- Base without /v1; the adapter appends
                        -- /v1/chat/completions.
                        url = commandcode.base_url,
                        api_key = "file:" .. commandcode.key_path,
                      },
                      schema = {
                        model = {
                          default = commandcode.model,
                          choices = commandcode.models,
                        },
                        -- Cap the completion explicitly. Every adapter inherits
                        -- the upstream default here, and an uncapped reply is
                        -- both slower and billed; 2048 is enough for a chat
                        -- turn or an inline edit.
                        max_tokens = {
                          order = 2,
                          mapping = "parameters",
                          type = "integer",
                          default = 2048,
                          desc = "Maximum tokens to generate in the reply.",
                        },
                      },
                    })
                  end,
                },
              }
            '';
            interactions = {
              chat.adapter = "commandcode";
              inline.adapter = "commandcode";
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
            # Inline completion wants low latency: small, infrequent requests.
            request_timeout = 4;
            throttle = 1500;
            debounce = 600;
            context_window = 6000;
            notify = "warn";
            provider_options = {
              openai_compatible = {
                api_key = lib.generators.mkLuaInline ''function() return require("commandcode").api_key() end'';
                end_point = lib.generators.mkLuaInline ''require("commandcode").url() .. "/chat/completions"'';
                model = lib.generators.mkLuaInline ''require("commandcode").completion_model'';
                name = "Command Code";
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
