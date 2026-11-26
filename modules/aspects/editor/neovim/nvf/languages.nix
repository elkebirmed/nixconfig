# ============================================================================
# NVF Languages
# Language support, formatters, and linters for each filetype.
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

          # YAML
          yaml = {
            enable = true;
            lsp.enable = false;
          };

          # Go
          go = {
            enable = true;
            lsp.enable = true;
            dap.enable = true;
            # nvf disables language formatting by default when the LSP is on,
            # so this has to be explicit or gofumpt never runs.
            format = {
              enable = true;
              type = ["gofumpt"];
            };
          };

          # Rust
          rust = {
            enable = true;
            lsp.enable = true;
            dap.enable = true;
            # Same nvf default as Go: formatting is off while the LSP is on.
            format = {
              enable = true;
              type = ["rustfmt"];
            };
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
        # nvf's markdown module already registers markdownlint-cli2 through
        # `languages.markdown.extraDiagnostics`, so only Dockerfile is added
        # here. Listing markdown again runs the linter twice.
        diagnostics.nvim-lint = {
          enable = true;
          linters_by_ft = {
            dockerfile = ["hadolint"];
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
