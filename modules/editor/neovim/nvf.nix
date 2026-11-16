# ============================================================================
# NVF - Neovim Configuration
# ============================================================================
{
  inputs,
  den,
  ...
}: {
  # Add NVF input
  flake-file.inputs.nvf = {
    url = "github:NotAShelf/nvf";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Configure Neovim through nvf
  den.aspects.nvf = {
    includes = [
      den.aspects.nvf.core
      den.aspects.nvf.treesitter
      den.aspects.nvf.lsp
      den.aspects.nvf.languages
      den.aspects.nvf.completion
      den.aspects.nvf.snacks
      den.aspects.nvf.plugins
      den.aspects.nvf.ui
      den.aspects.nvf.keymaps
      den.aspects.nvf.autocmds
      den.aspects.nvf.lua
    ];

    homeManager = {
      # NVF module
      imports = [inputs.nvf.homeModules.default];

      # NVIM aliase
      programs.fish.shellAliases = {
        v = "nvim";
      };

      programs.nvf = {
        enable = true; # Enable NVF
        defaultEditor = true; # Make it the default editor
      };
    };
  };
}
