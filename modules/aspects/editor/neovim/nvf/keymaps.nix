# ============================================================================
# NVF Keymaps
# Normal, visual, insert, terminal, and plugin keymaps.
# ============================================================================
_: let
  # --------------------------------------------------------------------------
  # Keymap helpers
  # --------------------------------------------------------------------------
  # Normal-mode Lua function
  n = key: body: desc: {
    inherit key desc;
    mode = "n";
    lua = true;
    action = "function() ${body} end";
  };

  # Normal and visual Lua function
  nx = key: body: desc: {
    inherit key desc;
    mode = ["n" "x"];
    lua = true;
    action = "function() ${body} end";
  };

  # Normal-mode command
  c = key: cmd: desc: {
    inherit key desc;
    mode = "n";
    action = "<cmd>${cmd}<cr>";
  };

  # Snacks picker
  pick = key: name: desc: n key "Snacks.picker.${name}()" desc;

  # Raw mapping with an explicit mode and action
  raw = mode: key: action: desc: {inherit mode key action desc;};

  # Expr mapping
  expr = mode: key: action: desc: {
    inherit mode key action desc;
    expr = true;
  };
in {
  den.aspects.nvf.keymaps = {
    homeManager.programs.nvf.settings.vim = {
      # ----------------------------------------------------------------------
      # Keymaps
      # ----------------------------------------------------------------------
      keymaps = [
        # Better Up/Down
        (expr ["n" "x"] "j" "v:count == 0 ? 'gj' : 'j'" "Down")
        (expr ["n" "x"] "<Down>" "v:count == 0 ? 'gj' : 'j'" "Down")
        (expr ["n" "x"] "k" "v:count == 0 ? 'gk' : 'k'" "Up")
        (expr ["n" "x"] "<Up>" "v:count == 0 ? 'gk' : 'k'" "Up")

        # Windows
        (c "<C-h>" "wincmd h" "Go to Left Window")
        (c "<C-j>" "wincmd j" "Go to Lower Window")
        (c "<C-k>" "wincmd k" "Go to Upper Window")
        (c "<C-l>" "wincmd l" "Go to Right Window")
        (c "<C-Up>" "resize +2" "Increase Window Height")
        (c "<C-Down>" "resize -2" "Decrease Window Height")
        (c "<C-Left>" "vertical resize -2" "Decrease Window Width")
        (c "<C-Right>" "vertical resize +2" "Increase Window Width")
        (raw "n" "<leader>-" "<C-W>s" "Split Window Below")
        (raw "n" "<leader>|" "<C-W>v" "Split Window Right")
        (raw "n" "<leader>wd" "<C-W>c" "Delete Window")
        (raw "n" "<leader>ww" "<C-W>p" "Other Window")
        (raw "n" "<leader>w-" "<C-W>s" "Split Window Below")
        (raw "n" "<leader>w|" "<C-W>v" "Split Window Right")
        (n "<leader>wm" "Snacks.toggle.zoom():toggle()" "Toggle Zoom")
        (n "<leader>uZ" "Snacks.toggle.zoom():toggle()" "Toggle Zoom")

        # Move Lines
        (raw "n" "<A-j>" ''<cmd>execute 'move .+' . v:count1<cr>=='' "Move Down")
        (raw "n" "<A-k>" ''<cmd>execute 'move .-' . (v:count1 + 1)<cr>=='' "Move Up")
        (raw "i" "<A-j>" "<esc><cmd>m .+1<cr>==gi" "Move Down")
        (raw "i" "<A-k>" "<esc><cmd>m .-2<cr>==gi" "Move Up")
        (raw "v" "<A-j>" ''<cmd>execute "'<,'>move '>+" . v:count1<cr>gv=gv'' "Move Down")
        (raw "v" "<A-k>" ''<cmd>execute "'<,'>move '<-" . (v:count1 + 1)<cr>gv=gv'' "Move Up")

        # Buffers
        (c "<S-h>" "bprevious" "Prev Buffer")
        (c "<S-l>" "bnext" "Next Buffer")
        (c "[b" "bprevious" "Prev Buffer")
        (c "]b" "bnext" "Next Buffer")
        (c "<leader>bb" "e #" "Switch to Other Buffer")
        (c "<leader>`" "e #" "Switch to Other Buffer")
        (n "<leader>bd" "Snacks.bufdelete()" "Delete Buffer")
        (n "<leader>bo" "Snacks.bufdelete.other()" "Delete Other Buffers")
        (c "<leader>bD" "bd" "Delete Buffer and Window")
        (c "<leader>bp" "BufferLineTogglePin" "Toggle Pin")
        (c "<leader>bP" "BufferLineGroupClose ungrouped" "Delete Non-Pinned Buffers")
        (c "<leader>br" "BufferLineCloseRight" "Delete Buffers to the Right")
        (c "<leader>bl" "BufferLineCloseLeft" "Delete Buffers to the Left")
        (c "[B" "BufferLineMovePrev" "Move Buffer Prev")

        (c "]B" "BufferLineMoveNext" "Move Buffer Next")

        # Misc Editing
        (raw ["n" "i"] "<esc>" "<cmd>noh<cr><esc>" "Escape and Clear hlsearch")
        (raw "n" "<leader>ur" "<cmd>nohlsearch<bar>diffupdate<bar>normal! <C-L><cr>" "Redraw / Clear hlsearch / Diff Update")
        (expr "n" "n" "'Nn'[v:searchforward].'zv'" "Next Search Result")
        (expr ["x" "o"] "n" "'Nn'[v:searchforward]" "Next Search Result")
        (expr "n" "N" "'nN'[v:searchforward].'zv'" "Prev Search Result")
        (expr ["x" "o"] "N" "'nN'[v:searchforward]" "Prev Search Result")
        (raw "i" "," ",<c-g>u" "Undo breakpoint")
        (raw "i" "." ".<c-g>u" "Undo breakpoint")
        (raw "i" ";" ";<c-g>u" "Undo breakpoint")
        (raw ["i" "x" "n" "s"] "<C-s>" "<cmd>w<cr><esc>" "Save File")
        (raw "n" "<leader>K" "<cmd>norm! K<cr>" "Keywordprg")
        (raw "x" "<" "<gv" "Indent left")
        (raw "x" ">" ">gv" "Indent right")
        {
          key = "gco";
          mode = "n";
          noremap = false;
          action = "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>";
          desc = "Add Comment Below";
        }
        {
          key = "gcO";
          mode = "n";
          noremap = false;
          action = "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>";
          desc = "Add Comment Above";
        }
        (c "<leader>fn" "enew" "New File")
        (raw "n" "<leader>xl" "<cmd>lua local ok = pcall(function() local w = vim.fn.getloclist(0, { winid = 0 }).winid; if w ~= 0 then vim.cmd.lclose() else vim.cmd.lopen() end end)<cr>" "Location List")
        (raw "n" "<leader>xq" "<cmd>lua local w = vim.fn.getqflist({ winid = 0 }).winid; if w ~= 0 then vim.cmd.cclose() else vim.cmd.copen() end<cr>" "Quickfix List")
        (c "[q" "cprev" "Previous Quickfix")
        (c "]q" "cnext" "Next Quickfix")

        (c "<leader>qq" "qa" "Quit All")

        # Tabs
        (c "<leader><tab>l" "tablast" "Last Tab")
        (c "<leader><tab>o" "tabonly" "Close Other Tabs")
        (c "<leader><tab>f" "tabfirst" "First Tab")
        (c "<leader><tab><tab>" "tabnew" "New Tab")
        (c "<leader><tab>]" "tabnext" "Next Tab")
        (c "<leader><tab>d" "tabclose" "Close Tab")
        (c "<leader><tab>[" "tabprevious" "Previous Tab")

        # Diagnostics
        (n "<leader>cd" "vim.diagnostic.open_float()" "Line Diagnostics")
        (n "]d" "vim.diagnostic.jump({ count = 1, float = true })" "Next Diagnostic")
        (n "[d" "vim.diagnostic.jump({ count = -1, float = true })" "Prev Diagnostic")
        (n "]e" "vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })" "Next Error")
        (n "[e" "vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })" "Prev Error")
        (n "]w" "vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.WARN, float = true })" "Next Warning")
        (n "[w" "vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.WARN, float = true })" "Prev Warning")

        # LSP
        (n "gd" "Snacks.picker.lsp_definitions()" "Goto Definition")
        (n "gr" "Snacks.picker.lsp_references()" "References")
        (n "gI" "Snacks.picker.lsp_implementations()" "Goto Implementation")
        (n "gy" "Snacks.picker.lsp_type_definitions()" "Goto T[y]pe Definition")
        (n "gD" "vim.lsp.buf.declaration()" "Goto Declaration")
        (n "gK" "vim.lsp.buf.signature_help()" "Signature Help")
        (raw "i" "<c-k>" "<cmd>lua vim.lsp.buf.signature_help()<cr>" "Signature Help")
        (nx "<leader>ca" "vim.lsp.buf.code_action()" "Code Action")
        (nx "<leader>cc" "vim.lsp.codelens.run()" "Run Codelens")
        (n "<leader>cC" "vim.lsp.codelens.refresh()" "Refresh & Display Codelens")
        (n "<leader>cA" "vim.lsp.buf.code_action({ context = { only = { 'source' }, diagnostics = {} } })" "Source Action")
        (n "<leader>cR" "Snacks.rename.rename_file()" "Rename File")
        (nx "<leader>cf" ''require("conform").format({ async = true, lsp_format = "fallback" })'' "Format")
        (n "]]" "Snacks.words.jump(vim.v.count1)" "Next Reference")
        (n "[[" "Snacks.words.jump(-vim.v.count1)" "Prev Reference")
        (n "<leader>uh" "vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }))" "Toggle Inlay Hints")

        # IncRename
        {
          key = "<leader>cr";
          mode = "n";
          expr = true;
          lua = true;
          action = ''function() return ":IncRename " .. vim.fn.expand("<cword>") end'';
          desc = "Rename (inc-rename.nvim)";
        }

        # Aerial
        (c "<leader>cs" "AerialToggle" "Aerial (Symbols)")
        (c "{" "AerialPrev" "Aerial Prev")
        (c "}" "AerialNext" "Aerial Next")
        (pick "<leader>ss" "lsp_symbols" "LSP Symbols")
        (pick "<leader>sS" "lsp_workspace_symbols" "LSP Workspace Symbols")

        # Snacks pickers
        (n "<leader><space>" "Snacks.picker.files({ hidden = true, cwd = Root() })" "Find Files (Root Dir)")
        (n "<leader>," "Snacks.picker.buffers()" "Buffers")
        (n "<leader>/" "Snacks.picker.grep({ hidden = true, cwd = Root() })" "Grep (Root Dir)")
        (pick "<leader>:" "command_history" "Command History")
        (pick "<leader>n" "notifications" "Notification History")

        # Explorer
        (n "<leader>e" "Snacks.explorer({ hidden = true })" "Explorer Snacks (cwd)")
        (n "<leader>E" "Snacks.explorer({ hidden = true, cwd = Root() })" "Explorer Snacks (root dir)")
        (n "<leader>fe" "Snacks.explorer({ hidden = true })" "Explorer Snacks (cwd)")
        (n "<leader>fE" "Snacks.explorer({ hidden = true, cwd = Root() })" "Explorer Snacks (root dir)")

        # Find
        (pick "<leader>fb" "buffers" "Buffers")
        (n "<leader>fB" "Snacks.picker.buffers({ hidden = true, nofile = true })" "Buffers (all)")
        (n "<leader>fc" "Snacks.picker.files({ hidden = true, cwd = vim.fn.stdpath('config') })" "Find Config File")
        (n "<leader>ff" "Snacks.picker.files({ hidden = true, cwd = Root() })" "Find Files (Root Dir)")
        (pick "<leader>fF" "files" "Find Files (cwd)")
        (pick "<leader>fg" "git_files" "Find Files (git-files)")
        (pick "<leader>fr" "recent" "Recent")
        (n "<leader>fR" "Snacks.picker.recent({ hidden = true, filter = { cwd = true } })" "Recent (cwd)")
        (pick "<leader>fp" "projects" "Projects")

        # Git
        (pick "<leader>gd" "git_diff" "Git Diff (hunks)")
        (pick "<leader>gs" "git_status" "Git Status")
        (pick "<leader>gS" "git_stash" "Git Stash")
        (pick "<leader>gl" "git_log" "Git Log")
        (pick "<leader>gL" "git_log_line" "Git Log Line")
        (pick "<leader>gf" "git_log_file" "Git Current File History")
        (n "<leader>gi" ''Snacks.picker.gh_issue()'' "GitHub Issues (open)")
        (n "<leader>gI" ''Snacks.picker.gh_issue({ state = "all" })'' "GitHub Issues (all)")
        (n "<leader>gp" ''Snacks.picker.gh_pr()'' "GitHub Pull Requests (open)")
        (n "<leader>gP" ''Snacks.picker.gh_pr({ state = "all" })'' "GitHub Pull Requests (all)")
        (n "<leader>gg" "Snacks.lazygit({ cwd = Snacks.git.get_root() })" "Lazygit (Root Dir)")
        (n "<leader>gG" "Snacks.lazygit()" "Lazygit (cwd)")
        (n "<leader>gb" "Snacks.git.blame_line()" "Git Blame Line")
        (nx "<leader>gB" "Snacks.gitbrowse()" "Git Browse (open)")
        (nx "<leader>gY" "Snacks.gitbrowse({ open = function(url) vim.fn.setreg('+', url) end, notify = false })" "Git Browse (copy)")

        # GitSigns Hunks
        (n "]h" ''if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else require("gitsigns").nav_hunk("next") end'' "Next Hunk")
        (n "[h" ''if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else require("gitsigns").nav_hunk("prev") end'' "Prev Hunk")
        (n "]H" ''require("gitsigns").nav_hunk("last")'' "Last Hunk")
        (n "[H" ''require("gitsigns").nav_hunk("first")'' "First Hunk")
        (raw ["n" "x"] "<leader>ghs" "<cmd>Gitsigns stage_hunk<cr>" "Stage Hunk")
        (raw ["n" "x"] "<leader>ghr" "<cmd>Gitsigns reset_hunk<cr>" "Reset Hunk")
        (c "<leader>ghS" "Gitsigns stage_buffer" "Stage Buffer")
        (c "<leader>ghu" "Gitsigns undo_stage_hunk" "Undo Stage Hunk")
        (c "<leader>ghR" "Gitsigns reset_buffer" "Reset Buffer")
        (c "<leader>ghp" "Gitsigns preview_hunk_inline" "Preview Hunk Inline")
        (n "<leader>ghb" ''require("gitsigns").blame_line({ full = true })'' "Blame Line")
        (c "<leader>ghB" "Gitsigns blame" "Blame Buffer")
        (c "<leader>ghd" "Gitsigns diffthis" "Diff This")
        (n "<leader>ghD" ''require("gitsigns").diffthis("~")'' "Diff This ~")
        (raw ["o" "x"] "ih" "<cmd><C-U>Gitsigns select_hunk<cr>" "GitSigns Select Hunk")

        # Mini Diff
        (n "<leader>go" "require('mini.diff').toggle_overlay(0)" "Toggle mini.diff overlay")

        # Search
        (pick ''<leader>s"'' "registers" "Registers")
        (pick "<leader>s/" "search_history" "Search History")
        (pick "<leader>sa" "autocmds" "Autocmds")
        (pick "<leader>sb" "lines" "Buffer Lines")
        (pick "<leader>sB" "grep_buffers" "Grep Open Buffers")
        (pick "<leader>sc" "command_history" "Command History")

        (pick "<leader>sC" "commands" "Commands")
        (pick "<leader>sd" "diagnostics" "Diagnostics")
        (pick "<leader>sD" "diagnostics_buffer" "Buffer Diagnostics")
        (n "<leader>sg" "Snacks.picker.grep({ cwd = Root() })" "Grep (Root Dir)")
        (pick "<leader>sG" "grep" "Grep (cwd)")
        (pick "<leader>sh" "help" "Help Pages")
        (pick "<leader>sH" "highlights" "Highlights")
        (pick "<leader>si" "icons" "Icons")
        (pick "<leader>sj" "jumps" "Jumps")
        (pick "<leader>sk" "keymaps" "Keymaps")
        (pick "<leader>sl" "loclist" "Location List")
        (pick "<leader>sM" "man" "Man Pages")
        (pick "<leader>sm" "marks" "Marks")
        (pick "<leader>sq" "qflist" "Quickfix List")
        (pick "<leader>sR" "resume" "Resume")

        (pick "<leader>su" "undo" "Undo History")
        (pick "<leader>uC" "colorschemes" "Colorscheme with Preview")
        (nx "<leader>sw" "Snacks.picker.grep_word({ cwd = Root() })" "Visual selection or word (Root Dir)")
        (nx "<leader>sW" "Snacks.picker.grep_word()" "Visual selection or word (cwd)")
        (pick "<leader>st" "todo_comments" "Todo")
        (n "<leader>sT" ''Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })'' "Todo/Fix/Fixme")
        (n "]t" ''require("todo-comments").jump_next()'' "Next Todo Comment")
        (n "[t" ''require("todo-comments").jump_prev()'' "Previous Todo Comment")

        (c "<leader>xt" "Trouble todo toggle" "Todo (Trouble)")
        (c "<leader>xT" "Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}" "Todo/Fix/Fixme (Trouble)")

        # Grug-far
        (nx "<leader>sr" ''
          local grug = require("grug-far")
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          grug.open({ transient = true, prefills = { filesFilter = ext and ext ~= "" and "*." .. ext or nil } })
        '' "Search and Replace")

        # Scratch, Notifications, and Misc Snacks
        (n "<leader>." "Snacks.scratch()" "Toggle Scratch Buffer")
        (n "<leader>S" "Snacks.scratch.select()" "Select Scratch Buffer")
        (n "<leader>un" "Snacks.notifier.hide()" "Dismiss All Notifications")
        (n "<leader>dps" "Snacks.profiler.scratch()" "Profiler Scratch Buffer")
        (n "<leader>ui" "vim.show_pos()" "Inspect Pos")
        (n "<leader>uI" "vim.treesitter.inspect_tree(); vim.api.nvim_input('I')" "Inspect Tree")

        # Terminal
        (n "<leader>ft" "Snacks.terminal(nil, { cwd = Root() })" "Terminal (Root Dir)")
        (n "<leader>fT" "Snacks.terminal()" "Terminal (cwd)")
        (n "<c-/>" "Snacks.terminal(nil, { cwd = Root() })" "Terminal (Root Dir)")
        (n "<c-_>" "Snacks.terminal(nil, { cwd = Root() })" "which_key_ignore")
        (raw "t" "<c-/>" "<cmd>close<cr>" "Hide Terminal")
        (raw "t" "<c-_>" "<cmd>close<cr>" "which_key_ignore")
        (raw "t" "<esc><esc>" "<c-\\><c-n>" "Enter Normal Mode")

        # Sessions (persistence)
        (n "<leader>qs" ''require("persistence").load()'' "Restore Session")
        (n "<leader>qS" ''require("persistence").select()'' "Select Session")
        (n "<leader>ql" ''require("persistence").load({ last = true })'' "Restore Last Session")
        (n "<leader>qd" ''require("persistence").stop()'' "Don't Save Current Session")

        # Yanky
        (n "<leader>p" "Snacks.picker.yanky()" "Open Yank History")
        {
          key = "y";
          mode = ["n" "x"];
          noremap = false;
          action = "<Plug>(YankyYank)";
          desc = "Yank Text";
        }
        {
          key = "p";
          mode = ["n" "x"];
          noremap = false;
          action = "<Plug>(YankyPutAfter)";
          desc = "Put Text After Cursor";
        }
        {
          key = "P";
          mode = ["n" "x"];
          noremap = false;
          action = "<Plug>(YankyPutBefore)";
          desc = "Put Text Before Cursor";
        }
        {
          key = "gp";
          mode = ["n" "x"];
          noremap = false;
          action = "<Plug>(YankyGPutAfter)";
          desc = "Put Text After Selection";
        }
        {
          key = "gP";
          mode = ["n" "x"];
          noremap = false;
          action = "<Plug>(YankyGPutBefore)";
          desc = "Put Text Before Selection";
        }
        {
          key = "[y";
          mode = "n";
          noremap = false;
          action = "<Plug>(YankyCycleForward)";
          desc = "Cycle Forward Through Yank History";
        }
        {
          key = "]y";
          mode = "n";
          noremap = false;
          action = "<Plug>(YankyCycleBackward)";
          desc = "Cycle Backward Through Yank History";
        }
        {
          key = "]p";
          mode = "n";
          noremap = false;
          action = "<Plug>(YankyPutIndentAfterLinewise)";
          desc = "Put Indented After Cursor (Linewise)";
        }
        {
          key = "[p";
          mode = "n";
          noremap = false;
          action = "<Plug>(YankyPutIndentBeforeLinewise)";
          desc = "Put Indented Before Cursor (Linewise)";
        }
        {
          key = "]P";
          mode = "n";
          noremap = false;
          action = "<Plug>(YankyPutIndentAfterLinewise)";
          desc = "Put Indented After Cursor (Linewise)";
        }
        {
          key = "[P";
          mode = "n";
          noremap = false;
          action = "<Plug>(YankyPutIndentBeforeLinewise)";
          desc = "Put Indented Before Cursor (Linewise)";
        }
        {
          key = ">p";
          mode = "n";
          noremap = false;
          action = "<Plug>(YankyPutIndentAfterShiftRight)";
          desc = "Put and Indent Right";
        }
        {
          key = "<p";
          mode = "n";
          noremap = false;
          action = "<Plug>(YankyPutIndentAfterShiftLeft)";
          desc = "Put and Indent Left";
        }
        {
          key = ">P";
          mode = "n";
          noremap = false;
          action = "<Plug>(YankyPutIndentBeforeShiftRight)";
          desc = "Put Before and Indent Right";
        }
        {
          key = "<P";
          mode = "n";
          noremap = false;
          action = "<Plug>(YankyPutIndentBeforeShiftLeft)";
          desc = "Put Before and Indent Left";
        }
        {
          key = "=p";
          mode = "n";
          noremap = false;
          action = "<Plug>(YankyPutAfterFilter)";
          desc = "Put After Applying a Filter";
        }
        {
          key = "=P";
          mode = "n";
          noremap = false;
          action = "<Plug>(YankyPutBeforeFilter)";
          desc = "Put Before Applying a Filter";
        }

        # Dial
        {
          key = "<C-a>";
          mode = "n";
          expr = true;
          lua = true;
          action = ''function() return require("dial.map").inc_normal() end'';
          desc = "Increment";
        }
        {
          key = "<C-x>";
          mode = "n";
          expr = true;
          lua = true;
          action = ''function() return require("dial.map").dec_normal() end'';
          desc = "Decrement";
        }
        {
          key = "<C-a>";
          mode = "v";
          expr = true;
          lua = true;
          action = ''function() return require("dial.map").inc_visual() end'';
          desc = "Increment";
        }
        {
          key = "<C-x>";
          mode = "v";
          expr = true;
          lua = true;
          action = ''function() return require("dial.map").dec_visual() end'';
          desc = "Decrement";
        }
        {
          key = "g<C-a>";
          mode = "v";
          expr = true;
          lua = true;
          action = ''function() return require("dial.map").inc_gvisual() end'';
          desc = "Increment";
        }
        {
          key = "g<C-x>";
          mode = "v";
          expr = true;
          lua = true;
          action = ''function() return require("dial.map").dec_gvisual() end'';
          desc = "Decrement";
        }

        # Refactoring
        (nx "<leader>rs" ''require("refactoring").select_refactor()'' "Refactor")
        (raw ["n" "x"] "<leader>ri" "<cmd>Refactor inline_var<cr>" "Inline Variable")
        (raw "n" "<leader>rI" "<cmd>Refactor inline_func<cr>" "Inline Function")
        (raw "n" "<leader>rb" "<cmd>Refactor extract_block<cr>" "Extract Block")
        (raw "n" "<leader>rf" "<cmd>Refactor extract_block_to_file<cr>" "Extract Block To File")
        (raw "x" "<leader>re" "<cmd>Refactor extract<cr>" "Extract Function")
        (raw "x" "<leader>rF" "<cmd>Refactor extract_to_file<cr>" "Extract Function To File")
        (raw "x" "<leader>rx" "<cmd>Refactor extract_var<cr>" "Extract Variable")
        (n "<leader>rp" ''require("refactoring").debug.print_var({ normal = true })'' "Debug Print Variable")
        (n "<leader>rP" ''require("refactoring").debug.printf({ below = false })'' "Debug Print")
        (n "<leader>rc" ''require("refactoring").debug.cleanup({})'' "Debug Cleanup")

        # DAP
        (n "<leader>dB" ''require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))'' "Breakpoint Condition")
        (n "<leader>db" ''require("dap").toggle_breakpoint()'' "Toggle Breakpoint")
        (n "<leader>dc" ''require("dap").continue()'' "Run/Continue")
        (n "<leader>dC" ''require("dap").run_to_cursor()'' "Run to Cursor")

        (n "<leader>dg" ''require("dap").goto_()'' "Go to Line (No Execute)")
        (n "<leader>di" ''require("dap").step_into()'' "Step Into")
        (n "<leader>dj" ''require("dap").down()'' "Down")
        (n "<leader>dk" ''require("dap").up()'' "Up")
        (n "<leader>dl" ''require("dap").run_last()'' "Run Last")
        (n "<leader>do" ''require("dap").step_out()'' "Step Out")
        (n "<leader>dO" ''require("dap").step_over()'' "Step Over")
        (n "<leader>dP" ''require("dap").pause()'' "Pause")
        (n "<leader>dr" ''require("dap").repl.toggle()'' "Toggle REPL")
        (n "<leader>ds" ''require("dap").session()'' "Session")
        (n "<leader>dt" ''require("dap").terminate()'' "Terminate")
        (n "<leader>dw" ''require("dap.ui.widgets").hover()'' "Widgets")
        (n "<leader>du" ''require("dapui").toggle({})'' "Dap UI")
        (nx "<leader>de" ''require("dapui").eval()'' "Eval")

        # Neotest
        (n "<leader>tt" ''require("neotest").run.run(vim.fn.expand("%"))'' "Run File")
        (n "<leader>tT" ''require("neotest").run.run(vim.uv.cwd())'' "Run All Test Files")
        (n "<leader>tr" ''require("neotest").run.run()'' "Run Nearest")
        (n "<leader>tl" ''require("neotest").run.run_last()'' "Run Last")
        (n "<leader>ts" ''require("neotest").summary.toggle()'' "Toggle Summary")
        (n "<leader>to" ''require("neotest").output.open({ enter = true, auto_close = true })'' "Show Output")
        (n "<leader>tO" ''require("neotest").output_panel.toggle()'' "Toggle Output Panel")
        (n "<leader>tS" ''require("neotest").run.stop()'' "Stop")
        (n "<leader>tw" ''require("neotest").watch.toggle(vim.fn.expand("%"))'' "Toggle Watch")
        (n "<leader>td" ''require("neotest").run.run({ strategy = "dap" })'' "Debug Nearest")

        # CodeCompanion
        (raw ["n" "v"] "<leader>ac" "<cmd>CodeCompanionChat Toggle<cr>" "CodeCompanion Chat")
        (raw ["n" "v"] "<leader>an" "<cmd>CodeCompanionChat<cr>" "New CodeCompanion Chat")
        (raw "v" "<leader>ai" "<cmd>CodeCompanion<cr>" "CodeCompanion Inline")
        (raw ["n" "v"] "<leader>ao" "<cmd>CodeCompanionActions<cr>" "CodeCompanion Actions")
        (raw "v" "<leader>ae" "<cmd>CodeCompanionChat Add<cr>" "Add to CodeCompanion Chat")

        # Edgy
        (n "<leader>ue" ''require("edgy").toggle()'' "Edgy Toggle")
        (n "<leader>uE" ''require("edgy").select()'' "Edgy Select Window")

        # SQL / Markdown
        (c "<leader>D" "DBUIToggle" "Toggle DBUI")
        (c "<leader>cp" "MarkdownPreviewToggle" "Markdown Preview")
      ];
    };
  };
}
