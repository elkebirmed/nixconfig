# ============================================================================
# NVF Treesitter
# Treesitter grammars, highlighting, folding, and context.
# ============================================================================
_: {
  den.aspects.nvf.treesitter = {
    homeManager = {
      pkgs,
      lib,
      ...
    }: {
      programs.nvf.settings.vim = {
        treesitter = {
          enable = true;
          highlight.enable = true;
          indent.enable = true;
          fold = true;
          # Names missing from nixpkgs' grammar set (or not plain packages) are skipped.
          grammars = let
            available = pkgs.vimPlugins.nvim-treesitter.builtGrammars;
            names = [
              "bash"
              "c"
              "diff"
              "html"
              "javascript"
              "jsdoc"
              "json"
              "json5"
              "lua"
              "luadoc"
              "luap"
              "markdown"
              "markdown_inline"
              "printf"
              "python"
              "query"
              "regex"
              "toml"
              "tsx"
              "typescript"
              "vim"
              "vimdoc"
              "xml"
              "yaml"
              # lang.git
              "git_config"
              "gitcommit"
              "git_rebase"
              "gitignore"
              "gitattributes"
              # lang.docker / sql / terraform
              "dockerfile"
              "sql"
              "hcl"
              "terraform"
            ];
          in
            lib.filter lib.isDerivation (map (name: available.${name} or null) names);

          # extras.treesitter-context
          context = {
            enable = true;
            setupOpts = {
              mode = "cursor";
              max_lines = 3;
            };
          };
        };
      };
    };
  };
}
