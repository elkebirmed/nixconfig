# ============================================================================
# NVF LSP
# LSP servers, inlay hints, trouble, and per-server settings.
# ============================================================================
{inputs, ...}: {
  den.aspects.nvf.lsp = {
    homeManager = {
      user,
      pkgs,
      lib,
      ...
    }: let
      flake = "builtins.getFlake \"${inputs.self}\"";
      host = user.host or null;
      hostName =
        if host != null
        then host.name
        else null;
      system =
        if host != null
        then host.system
        else "x86_64-linux";

      lua = lib.generators.mkLuaInline;
    in {
      programs.nvf.settings.vim = {
        lsp = {
          enable = true;
          formatOnSave = true;
          inlayHints.enable = true;

          mappings.hover = "K";

          trouble = {
            enable = true;
            setupOpts = {
              auto_close = true;

              auto_preview = false;
              focus = true;
              modes.lsp.win.position = "right";
            };

            mappings = {
              workspaceDiagnostics = "<leader>xx";
              documentDiagnostics = "<leader>xX";
              lspReferences = "<leader>cS";
              quickfix = "<leader>xQ";
              locList = "<leader>xL";

              symbols = null; # Aerial owns <leader>cs
            };
          };

          servers = {
            nixd = {
              # `vim.lsp.servers.<name>` is fed straight into `vim.lsp.config()`,
              # so nixd's own configuration has to live under `settings.nixd`.
              settings.nixd = {
                nixpkgs.expr = "import (${flake}).inputs.nixpkgs { }";

                options =
                  {
                    home_manager.expr = "(${flake}).homeConfigurations.\"${user.userName}\".options";

                    flake-parts.expr = ''
                      let
                        f = ${flake};
                        cfg = f.debug.config;
                      in
                        (builtins.removeAttrs f.debug.options ["den" "flake-file"])
                        // {
                          den = builtins.removeAttrs cfg.den ["stages"];
                          flake-file = cfg.flake-file;
                        }
                    '';

                    per-system.expr = "{ perSystem = (${flake}).allSystems.\"${system}\".options; }";
                  }
                  // (
                    if hostName == null
                    then {}
                    else {
                      nixos.expr = "(${flake}).nixosConfigurations.${hostName}.options";
                    }
                  );
              };
            };

            # Docker
            dockerls = {
              enable = true;
              cmd = ["${pkgs.dockerfile-language-server}/bin/docker-langserver" "--stdio"];
              filetypes = ["dockerfile"];
              root_markers = ["Dockerfile"];
            };

            docker_compose_language_service = {
              enable = true;
              cmd = ["${pkgs.docker-compose-language-service}/bin/docker-compose-langserver" "--stdio"];
              filetypes = ["yaml.docker-compose"];
              root_markers = ["docker-compose.yaml" "docker-compose.yml" "compose.yaml" "compose.yml"];
            };

            # JSON (+ SchemaStore)
            jsonls = {
              enable = true;
              cmd = ["${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server" "--stdio"];
              filetypes = ["json" "jsonc"];
              settings.json = {
                format.enable = true;
                validate.enable = true;
                schemas = lua ''require("schemastore").json.schemas()'';
              };
            };

            # YAML (+ SchemaStore)
            yamlls = {
              enable = true;
              cmd = ["${pkgs.yaml-language-server}/bin/yaml-language-server" "--stdio"];
              filetypes = ["yaml" "yaml.docker-compose" "yaml.gitlab"];
              settings.yaml = {
                keyOrdering = false;
                format.enable = true;
                validate = true;
                schemaStore = {
                  enable = false;
                  url = "";
                };
                schemas = lua ''require("schemastore").yaml.schemas()'';
              };
            };

            # TOML
            taplo = {
              enable = true;
              cmd = ["${pkgs.taplo}/bin/taplo" "lsp" "stdio"];
              filetypes = ["toml"];
            };

            # TailwindCSS
            tailwindcss = {
              enable = true;
              cmd = ["${pkgs.tailwindcss-language-server}/bin/tailwindcss-language-server" "--stdio"];
              filetypes = [
                "html"
                "css"
                "scss"
                "less"
                "javascript"
                "javascriptreact"
                "typescript"
                "typescriptreact"
                "vue"
                "svelte"
                "astro"
                "php"
                "markdown"
                "mdx"
              ];
              root_markers = [
                "tailwind.config.js"
                "tailwind.config.cjs"
                "tailwind.config.mjs"
                "tailwind.config.ts"
                "postcss.config.js"
                "postcss.config.ts"
                "package.json"
              ];
              settings.tailwindCSS = {
                includeLanguages = {
                  elixir = "html-eex";
                  eelixir = "html-eex";
                  heex = "html-eex";
                };
                experimental.classRegex = [
                  ["cva\\(([^)]*)\\)" "[\"'`]([^\"'`]*).*?[\"'`]"]
                  ["cx\\(([^)]*)\\)" "(?:'|\"|`)([^']*)(?:'|\"|`)"]
                ];
              };
            };

            # ESLint (LSP)
            eslint = {
              enable = true;
              cmd = ["${pkgs.vscode-langservers-extracted}/bin/vscode-eslint-language-server" "--stdio"];
              filetypes = ["javascript" "javascriptreact" "typescript" "typescriptreact" "vue" "svelte"];
              root_markers = [
                "eslint.config.js"
                "eslint.config.mjs"
                "eslint.config.cjs"
                "eslint.config.ts"
                ".eslintrc"
                ".eslintrc.js"
                ".eslintrc.cjs"
                ".eslintrc.json"
                "package.json"
              ];
              settings = {
                validate = "on";
                useESLintClass = false;
                experimental.useFlatConfig = false;
                codeActionOnSave = {
                  enable = false;
                  mode = "all";
                };
                format = true;
                quiet = false;
                onIgnoredFiles = "off";
                rulesCustomizations = [];
                run = "onType";
                problems.shortenToSingleLine = false;
                nodePath = "";
                workingDirectory.mode = "auto";
              };
            };
          };
        };
      };
    };
  };
}
