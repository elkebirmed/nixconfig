# ============================================================================
# NVF
# Configure Neovim through nvf and include every NVF aspect.
# ============================================================================
{
  inputs,
  den,
  ...
}: {
  # Add the nvf input.
  flake-file.inputs.nvf = {
    url = "github:NotAShelf/nvf";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Configure Neovim through nvf.
  den.aspects.nvf = {user, ...}: {
    homePersistence = {
      inherit (user) userName;
      directories = [".local/state/nvf"];
    };

    includes = [
      den.aspects.nvf.core
      den.aspects.nvf.treesitter
      den.aspects.nvf.lsp
      den.aspects.nvf.languages
      den.aspects.nvf.completion
      den.aspects.nvf.ai
      den.aspects.nvf.snacks
      den.aspects.nvf.plugins
      den.aspects.nvf.ui
      den.aspects.nvf.keymaps
      den.aspects.nvf.autocmds
      den.aspects.nvf.lua
      den.aspects.nvf.extras
    ];

    homeManager = {pkgs, ...}: {
      # NVF module
      imports = [inputs.nvf.homeModules.default];

      # NVIM alias.
      programs.fish.shellAliases = {
        v = "nvim";
      };

      programs.nvf = {
        enable = true; # Enable NVF
        defaultEditor = true; # Make it the default editor
      };

      home.packages = with pkgs; [
        sqlfluff
        tree-sitter
      ];
    };
  };
}
