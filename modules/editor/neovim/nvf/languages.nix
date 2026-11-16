# ============================================================================
# NVF Languages Configuration
# ============================================================================
_: {
  den.aspects.nvf.languages = {
    homeManager = {
      pkgs,
      lib,
      ...
    }: let
      prettier = lib.getExe pkgs.prettier;
    in {
      programs.nvf.settings.vim = {
        languages = {
          enableTreesitter = true;
          enableFormat = true;
          enableExtraDiagnostics = true;

          # Nix
          nix = {
            enable = true;
            treesitter.enable = true;
            lsp = {
              enable = true;
              servers = ["nixd"];
            };
            format = {
              enable = true;
              type = ["alejandra"];
            };
            extraDiagnostics = {
              enable = true;
              types = ["statix" "deadnix"];
            };
          };

          # Lua
          lua = {
            enable = true;
            extensions.lazydev.enable = true;
          };

          # Bash
          bash.enable = true;

          # HTML
          html = {
            enable = true;
            treesitter.autotagHtml = true;
          };

          # Markdown
          markdown = {
            enable = true;
            format.enable = false;
            extensions.render-markdown-nvim.enable = true;
          };

          # Yaml
          yaml = {
            enable = true;
            lsp.enable = false;
          };

          # GoLang
          go = {
            enable = true;
            lsp.enable = true;
            dap.enable = true;
            format.type = ["gofumpt"];
          };

          # Rust
          rust = {
            enable = true;
            lsp.enable = true;
            dap.enable = true;
            extensions.crates-nvim.enable = true;
          };

          # Python
          python = {
            enable = true;
            lsp.servers = ["basedpyright"];
            format.type = ["ruff"];

            dap.enable = true;
          };

          # PHP
          php = {
            enable = true;
            lsp.servers = ["phpactor"];
          };

          # TypeScript
          typescript = {
            enable = true;
            lsp.servers = ["typescript-language-server"];

            format.type = ["prettier"];
            extraDiagnostics = {
              enable = true;
              types = ["eslint_d"];
            };
            extensions.ts-error-translator.enable = true;
          };

          # Terraform
          terraform = {
            enable = true;
            lsp.enable = true;
          };

          # SQL
          sql = {
            enable = true;
            lsp.enable = false;
            format.enable = true;
            extraDiagnostics.enable = true;
          };
        };

        # Formatting
        formatter.conform-nvim = {
          enable = true;
          setupOpts = {
            formatters.prettier.command = prettier;
            formatters_by_ft = {
              markdown = ["prettier"];
              "markdown.mdx" = ["prettier"];
              yaml = ["prettier"];
              json = ["prettier"];
              jsonc = ["prettier"];
              css = ["prettier"];
              scss = ["prettier"];
              html = ["prettier"];
              graphql = ["prettier"];
              toml = [];
            };
          };
        };

        # Linting
        diagnostics.nvim-lint = {
          enable = true;
          linters_by_ft = {
            dockerfile = ["hadolint"];
            markdown = ["markdownlint-cli2"];
          };
        };

        # Required packages
        extraPackages = [
          pkgs.hadolint
          pkgs.markdownlint-cli2
          pkgs.prettier
          pkgs.taplo
          pkgs.ripgrep
          pkgs.fd
          pkgs.lazygit
        ];
      };
    };
  };
}
