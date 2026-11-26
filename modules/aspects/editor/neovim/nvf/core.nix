# ============================================================================
# NVF Core
# Core globals, editor options, clipboard, undo, and theme.
# ============================================================================
_: {
  den.aspects.nvf.core = {
    homeManager.programs.nvf.settings.vim = {
      globals = {
        # Leader keys
        mapleader = " ";
        maplocalleader = "\\";

        # Animation
        snacks_animate = true;
      };

      # Undo history
      undoFile.enable = true;

      # Clipboard
      clipboard = {
        enable = true;
        registers = "unnamedplus";
      };

      # Options
      options = {
        autowrite = true;
        conceallevel = 2;
        confirm = true;
        cursorline = true;
        expandtab = true;

        foldlevel = 99;
        formatoptions = "jcroqlnt";
        grepformat = "%f:%l:%c:%m";
        grepprg = "rg --vimgrep";
        ignorecase = true;
        inccommand = "nosplit";
        jumpoptions = "view";
        laststatus = 3;
        linebreak = true;
        list = true;
        mouse = "a";
        number = true;
        pumblend = 10;
        pumheight = 10;
        relativenumber = true;
        scrolloff = 4;
        shiftround = true;
        shiftwidth = 2;
        showmode = false;
        sidescrolloff = 8;
        signcolumn = "yes";
        smartcase = true;
        smartindent = true;
        smoothscroll = true;
        spelllang = "en";
        splitbelow = true;
        splitkeep = "screen";
        splitright = true;
        tabstop = 2;
        termguicolors = true;
        # nvf renders `options` alphabetically, and Neovim aliases `tm` to
        # `timeoutlen`. Both must agree or `tm`'s default silently wins.
        tm = 300;
        timeoutlen = 300;
        undolevels = 10000;

        updatetime = 200;
        virtualedit = "block";
        wildmode = "longest:full,full";
        winminwidth = 5;
        wrap = false;
        completeopt = "menu,menuone,noselect";
        fillchars = "foldopen: ,foldclose: ,fold: ,foldsep: ,diff:╱,eob: ";
        listchars = "tab:» ,trail:·,nbsp:␣";
        hlsearch = true;
        incsearch = true;
        swapfile = false;
        backup = false;
        writebackup = false;
      };

      # Kanagawa theme
      theme = {
        enable = true;
        name = "kanagawa";
        style = "wave";
      };
    };
  };
}
