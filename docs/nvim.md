# Neovim (nvf)

Neovim is configured declaratively through [nvf](https://github.com/NotAShelf/nvf)
and wired into the rest of the flake with `den`. Every option below lives in Nix;
nothing is hand-edited inside `~/.config/nvim`.

- Leader is `<Space>`, local leader is `\`.
- `v` is aliased to `nvim` in fish.
- `defaultEditor = true`, so `$EDITOR`/`$VISUAL` point at Neovim.
- Undo history and Neovim state persist to `~/.local/state/nvf`.

Part of the [nixconfig](../README.md) documentation.

Apply with your usual flake rebuild (see the root [`README.md`](../README.md)). The
aspect is included by the `mohamed` user only (`modules/users/mohamed.nix`); `koko` and
`kids` do not load Neovim.

## File map

Paths are relative to `modules/aspects/editor/neovim/`:

| File                 | Purpose                                                                              |
| -------------------- | ------------------------------------------------------------------------------------ |
| `nvf.nix`            | Declares the `nvf` flake input, the `den.aspects.nvf` aspect, and the include order. |
| `nvf/core.nix`       | Globals, editor options, clipboard, undo, Kanagawa theme.                            |
| `nvf/lsp.nix`        | LSP servers, inlay hints, Trouble, per-server settings.                              |
| `nvf/languages.nix`  | Per-language support, formatters (conform), linters (nvim-lint).                     |
| `nvf/treesitter.nix` | Parsers, highlighting, indent, folding, treesitter-context.                          |
| `nvf/completion.nix` | blink.cmp sources, cmdline completion, snippets.                                     |
| `nvf/ai.nix`         | Command Code provider helper, CodeCompanion, Minuet ghost text.                      |
| `nvf/snacks.nix`     | Snacks dashboard/picker/explorer/notifier and friends.                               |
| `nvf/ui.nix`         | Lualine, bufferline, mini.\*, Flash, Aerial, DAP, Noice, WhichKey.                   |
| `nvf/plugins.nix`    | Plugins wired directly through `extraPlugins`.                                       |
| `nvf/extras.nix`     | Newer plugin additions plus the language toolchains.                                 |
| `nvf/keymaps.nix`    | Every mapping, defined with small helper functions.                                  |
| `nvf/autocmds.nix`   | Autocommands: reload, yank highlight, last position, wrap/spell.                     |
| `nvf/lua.nix`        | Raw Lua: root-dir helper, filetype detection, Snacks toggles.                        |

Aspects are composed in `nvf.nix`; adding a feature means adding a file and
listing its aspect there.

## Core

- Kanagawa (`wave`) theme, `termguicolors`, true-color throughout.
- `number` + `relativenumber`, `cursorline`, `signcolumn=yes`, `laststatus=3`,
  `splitbelow`/`splitright`, `scrolloff=4`, `sidescrolloff=8`.
- 2-space indent (`tabstop`/`shiftwidth`), `expandtab`, `smartindent`.
- `ignorecase` + `smartcase`, `incsearch`, `hlsearch`, `inccommand=nosplit`.
- `undofile` with `undolevels=10000`, no swap/backup files.
- Clipboard uses `unnamedplus`; the actual `wl-copy`/`wl-paste` provider comes
  from `wl-clipboard`, installed by the Niri aspect rather than this one.
- `grep` uses ripgrep (`grepprg = "rg --vimgrep"`).

> `timeoutlen` and `tm`: nvf renders `options` alphabetically and Neovim aliases
> `tm` to `timeoutlen`, so nvf's `tm = 500` default would otherwise win. Both are
> pinned to `300` in `core.nix` — keep them in sync.

## LSP

Enabled with format-on-save, inlay hints, `K` for hover, and folding-range aware
Trouble on the right.

| Server                                        | Filetypes                                                                    |
| --------------------------------------------- | ---------------------------------------------------------------------------- |
| `nixd`                                        | Nix — evaluates the flake for options, packages, `flake-parts`, and the host |
| `gopls`                                       | Go (via `languages.go`)                                                      |
| `rust-analyzer`                               | Rust (via `languages.rust`)                                                  |
| `basedpyright`                                | Python                                                                       |
| `phpactor`                                    | PHP                                                                          |
| `typescript-language-server`                  | TypeScript / TSX                                                             |
| `tailwindcss`                                 | HTML/CSS/JS/TS/Vue/Svelte/Astro/PHP/Markdown                                 |
| `eslint`                                      | JS/TS/Vue/Svelte                                                             |
| `jsonls`, `yamlls`                            | JSON/JSONC, YAML — both use SchemaStore schemas                              |
| `taplo`                                       | TOML                                                                         |
| `dockerls`, `docker_compose_language_service` | Dockerfile, compose YAML                                                     |

Trouble keys: `<leader>xx` workspace diagnostics, `<leader>xX` buffer
diagnostics, `<leader>cS` LSP references, `<leader>xQ` quickfix,
`<leader>xL` loclist.

## Languages, formatters, linters

`enableTreesitter`, `enableFormat`, and `enableExtraDiagnostics` are on globally.

| Language                         | Formatter      | Linter / extra diagnostics     |
| -------------------------------- | -------------- | ------------------------------ |
| Nix                              | `alejandra`    | `statix`, `deadnix`            |
| Lua                              | `stylua`       | `luacheck`                     |
| Bash / sh                        | `shfmt`        | `shellcheck`                   |
| Go                               | `gofumpt`      | `golangci-lint`                |
| Rust                             | `rustfmt`      | —                              |
| Python                           | `ruff`         | `mypy`                         |
| PHP                              | `php-cs-fixer` | `phpstan`                      |
| TypeScript                       | `prettier`     | `eslint_d`                     |
| SQL                              | `sqlfluff`     | `sqlfluff`                     |
| Terraform                        | `opentofu`     | —                              |
| Dockerfile                       | —              | `hadolint`                     |
| Markdown                         | `prettier`     | `markdownlint-cli2` (from nvf) |
| HTML                             | `prettier`     | `htmlhint`                     |
| YAML/JSON/JSONC/CSS/SCSS/GraphQL | `prettier`     | —                              |

> Formatting is **disabled by default by nvf when an LSP is enabled**. Go and
> Rust therefore set `format.enable = true` explicitly; without it `gofumpt`
> and `rustfmt` silently never run.

> `markdown = ["markdownlint-cli2"]` is registered by nvf's own markdown module.
> Do not add it to `diagnostics.nvim-lint.linters_by_ft` again or it runs twice.

`conform` also exposes `:ConformInfo` and the `<leader>cf` mapping.

## Treesitter

Grammars are filtered against `pkgs.vimPlugins.nvim-treesitter.builtGrammars`, so
names missing from nixpkgs are skipped instead of failing the build.

- Enabled: bash, c, css, diff, html, javascript, jsdoc, json, json5, latex, lua,
  luadoc, luap, markdown, markdown_inline, printf, python, query, regex, scss,
  toml, tsx, typescript, vim, vimdoc, xml, yaml, git\* (config/commit/rebase/
  ignore/attributes), dockerfile, sql, hcl, terraform.
- Highlighting, indent, and folding are all on.
- `treesitter-context` is enabled (`mode = "cursor"`, max 3 lines); toggle with
  `<leader>ut`.

## Completion (blink.cmp)

- Sources: `lsp`, `path`, `snippets`, `buffer`, plus emoji/ripgrep/spell
  providers. SQL gets `dadbod`; CodeCompanion buffers get its own source.
- Documentation auto-shows after 200 ms; signature help on; ghost text off in
  insert mode (Minuet owns that space).
- Command-line completion is on with a `cmdline` preset and ghost text, menus
  only open for `:` — search `/` is left alone.

## AI (Command Code)

`ai.nix` defines a shared `require("commandcode")` helper pointed at the
Command Code Provider API (`https://api.commandcode.ai/provider`), reading its
key from the SOPS-backed `cmdc/api-key` on every call (so rotated keys need no
restart). There is no local gateway container — requests go straight out over
HTTPS. Models come from `modules/aspects/ai/_commandcode-lib.nix`, where every
ID has been verified as available on this account's plan; the default chat model
is `deepseek/deepseek-v4.1-flash` and inline completion uses
`deepseek/deepseek-v4.1-flash-fast`.

- **CodeCompanion** uses Command Code for chat and inline interactions.
- **Minuet** provides inline ghost-text completion with small, infrequent
  requests (`request_timeout = 4`, `throttle = 1500`). Accept line with `<A-a>`,
  accept all with `<A-A>`, dismiss `<A-e>`, cycle `<A-p>`/`<A-n>`.
  A seeded `FileType`/`BufEnter` autocmd makes the first buffer auto-trigger,
  since Minuet's own hook lands after `InsertEnter`.

Needs a Command Code API key with **Provider API access** (GOAT, Pro, Max,
Team; or a Go plan with credits). No local service to run.

## Snacks

Replaces Telescope and neo-tree entirely (`telescope.enable = false`,
`filetree.neo-tree.enable = false`).

- Dashboard with the NEOVIM banner and keys: `f` files, `n` new, `r` recent,
  `g` grep, `c` config, `s` restore session, `p` projects, `q` quit.
- Picker (with `explorer.replace_netrw`), explorer, input, notifier (3 s),
  quickfile, scope, scroll, statuscolumn, words, bufdelete, git, gitbrowse,
  lazygit, rename, scratch, terminal, toggle, zen, dim, profiler, bigfile,
  indent.
- `<leader>e`/`<leader>E` explorer at cwd/root; `<leader>,` buffers;
  `<leader><space>` files; `<leader>/` live grep root dir.

Toggles from `lua.nix`: `us` spell, `uw` wrap, `uL` relativenumber,
`ud` diagnostics, `ul` line numbers, `uc` conceal, `uA` tabline, `uT`
treesitter, `ub` background, `uD` dim, `ua` animate, `ug` indent, `uS` scroll,
`uz` zen, `ut` treesitter-context, `dpp` profiler, `dph` profiler highlights.

## UI

- **Lualine** with global status, hidden on dashboards.
- **Bufferline** with LSP diagnostics, click-to-close through `Snacks.bufdelete`,
  and an offset for Snacks layout boxes.
- **mini.\***: pairs, icons, ai, comment, surround (`gsa`/`gsd`/`gsf`/`gsF`/
  `gsh`/`gsr`/`gsn`), diff (signs), hipatterns.
- **Flash**: `s` jump, `S` treesitter, `r` remote, `R` treesitter search,
  `<C-s>` toggle.
- **Aerial** for symbols (`<leader>cs`, `{`/`}`), **todo-comments**,
  **project.nvim**, **nvim-dap** + dap-ui, **nvim-notify**, **Noice**
  (command palette, LSP handler, inc-rename), **edgy** (left/right/bottom
  layouts), and **nvim-web-devicons**.
- **WhichKey** (`helix` preset) with groups: `<tab>` Tabs, `b` Buffer, `c` Code,
  `d` Debug, `dp` Profiler, `f` File/Find, `g` Git, `G` Diff/History,
  `gh` Hunks, `h` Harpoon, `m` Multicursor, `q` Quit/Session, `r` Refactor,
  `s` Search, `t` Test, `u` UI, `w` Windows, `x` Diagnostics, `gs` Surround,
  `[`/`]` Prev/Next, `g` Goto, `z` Fold.
- **dropbar** breadcrumbs, **illuminate** (120 ms delay), and **colorizer**
  (hex/rgb/hsl/tailwind, background mode).

## Extra plugins (`plugins.nix`)

| Plugin                       | Behavior                                                                                                                       |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| persistence.nvim             | `qs` restore, `qS` select, `ql` last, `qd` don't save                                                                          |
| grug-far                     | `<leader>sr` search & replace                                                                                                  |
| SchemaStore                  | JSON/YAML schemas for `jsonls`/`yamlls`                                                                                        |
| yanky                        | yank history with cycle/indent put variants, `<leader>p` picker                                                                |
| dial.nvim                    | `<C-a>`/`<C-x>` with per-filetype augends (semver, dates, bools…); entry point is `require("dial.map")`, not `require("dial")` |
| inc-rename                   | `<leader>cr` incremental LSP rename                                                                                            |
| refactoring.nvim             | `rs` select, `ri`/`rI` inline, `rb`/`rf` block, `re`/`rF`/`rx` extract, `rp`/`rP`/`rc` debug print                             |
| edgy                         | window layouts for terminal, trouble, quickfix, help, neotest, grug-far                                                        |
| neotest                      | adapters: python, go, jest, rustaceanvim; `t*` mappings                                                                        |
| vim-dadbod (+ui, completion) | `<leader>D` DBUI, SQL completion                                                                                               |
| markdown-preview             | `<leader>cp` toggle preview (command is `-buffer` scoped, so it only exists in markdown buffers)                               |

> `neotest-golang` is patched to drop its redundant `nvim-dap-go` dependency,
> which nvf already manages — keeping both broke `mnw`'s plugin layout.

## Extras (`extras.nix`)

**Editing**

- `mini.bracketed` — new `[ ]` motions. The `buffer`, `diagnostic`, `quickfix`,
  `treesitter`, `window`, and `yank` targets are disabled because
  `keymaps.nix` owns those keys; `comment`, `conflict`, `file`, `indent`,
  `jump`, `location`, and `oldfile` remain. (The `multicursor` target is inert
  here — it requires Neovim 0.13 and this config runs 0.12, so `[m`/`]m` do
  not exist; use the `MC*` mappings below instead.)
- `mini.operators` — evaluate/exchange/multiply/replace/sort, remapped from the
  stock `g=`/`gx`/`gm`/`gr`/`gs` to `gz=`, `gzx`, `gzm`, `gzr`, `gzs` because
  `gr` (references), `gs` (surround), and `gx` were taken.
- `mini.align` — `ga` / `gA` interactive alignment.
- `multicursors` — `MCstart`/`MCpattern` (`<leader>mcs`/`<leader>mcp`),
  `<leader>mu` word under cursor, `<leader>mq` clear.
- `csvview` — auto-renders CSV/TSV as aligned tables, `<leader>um` toggles.

**Git**

- `diffview` — `<leader>Go` open, `<leader>Gc` close, `<leader>Gf` file history,
  `<leader>GF` repo history. Uses `<leader>G` because `<leader>g*` is dense.
- `harpoon` — `<leader>ha` mark, `<leader>hh` menu, `<leader>h1`–`h4` jump.
  Moved off the stock `<leader>a`/`<C-j|k|l>` which collide with CodeCompanion
  and window navigation.
- `octo` — GitHub issues `<leader>oi`, PRs `<leader>op`, discussions
  `<leader>od`, notifications `<leader>ol`, search `<leader>os`; all use the
  Snacks picker.
- `gitlinker` — `<leader>gu` open permalink, `<leader>gU` copy it (n and x).

**Tools**

- `undotree` — `<leader>uu`.
- `direnv` — loads `.envrc`, surfaces allow/deny prompts.
- `nix-develop` — in-editor `nix develop` / `nix shell` for this flake.

**Toolchains**

LSP servers, formatters, linters, and test adapters are referenced by absolute
store path, but several still shell out to plain binaries on `PATH`:

`glib` (`gio trash` for non-permanent deletes), `go`, `gofumpt`, `cargo`,
`rustc`, `python3`, `direnv`, `gcc`.

Without these, `neotest-golang`/Rust tests, `gopls` imports, `rust-analyzer`,
and `direnv` fail even though the servers themselves launch.

## Keymaps

`keymaps.nix` defines six helpers: `n` (normal Lua fn), `nx` (normal+visual),
`c` (normal command), `pick` (Snacks picker), `raw` (explicit mode/action), and
`expr` (expression mapping).

### Windows, buffers, tabs

| Key                                                 | Action                                        |
| --------------------------------------------------- | --------------------------------------------- |
| `<C-h>` `<C-j>` `<C-k>` `<C-l>`                     | Move between windows                          |
| `<C-Up>` `<C-Down>` `<C-Left>` `<C-Right>`          | Resize                                        |
| `<leader>-` / `<leader>\|`                          | Split below / right (`w` variants too)        |
| `<leader>wd` `<leader>ww` `<leader>wm`              | Close, other, zoom                            |
| `<S-h>` `<S-l>`, `[b` `]b`                          | Prev/next buffer                              |
| `<leader>bb`, `<leader>\``                          | Switch to other buffer                        |
| `<leader>bd` `<leader>bo` `<leader>bD`              | Delete, delete others, delete + window        |
| `<leader>bp` `<leader>bP` `<leader>br` `<leader>bl` | Pin, unpinned, close right, close left        |
| `[B` `]B`                                           | Move buffer                                   |
| `<leader><tab>l/o/f/<tab>/]/d/[`                    | Last, only, first, new, next, close, prev tab |

### Editing

| Key                                     | Action                                 |
| --------------------------------------- | -------------------------------------- |
| `j`/`k`                                 | `gj`/`gk` unless prefixed with a count |
| `<A-j>` / `<A-k>`                       | Move line/selection down/up (n, i, v)  |
| `n` / `N`                               | Next/prev search result                |
| `<esc>`                                 | Clear search highlight                 |
| `<leader>ur`                            | Redraw, clear hlsearch, diff update    |
| `<C-s>`                                 | Save                                   |
| `<leader>K`                             | Keywordprg                             |
| `<` / `>`                               | Indent and keep selection              |
| `gco` / `gcO`                           | Add comment below / above              |
| `<leader>fn`                            | New file                               |
| `<leader>xl` / `<leader>xq` / `]q` `[q` | Location list, quickfix, next/prev     |
| `<leader>qq`                            | Quit all                               |

### Files, search, sessions

| Key                                                                                                                               | Action                                                                  |
| --------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| `<leader><space>` / `<leader>/`                                                                                                   | Files / grep in root dir                                                |
| `<leader>,`                                                                                                                       | Buffers                                                                 |
| `<leader>ff` `fF` `fg` `fr` `fR` `fp` `fc` `fb` `fB`                                                                              | Find variants (root, cwd, git files, recent, projects, config, buffers) |
| `<leader>e` / `<leader>E`                                                                                                         | Explorer at cwd / root                                                  |
| `<leader>ft` / `<leader>fT`                                                                                                       | Terminal at root / cwd (`<C-/>` too)                                    |
| `s"` `s/` `sa` `sb` `sc` `sC` `sd` `sD` `sg` `sG` `sh` `sH` `si` `sj` `sk` `sl` `sM` `sm` `sq` `sR` `su` `uC` `sw` `sW` `st` `sT` | Search pickers                                                          |
| `<leader>sr`                                                                                                                      | Grug-far search & replace                                               |
| `<leader>qs` `qS` `ql` `qd`                                                                                                       | Sessions                                                                |
| `]t` / `[t`, `<leader>xt`                                                                                                         | Todo comments (jump / Trouble)                                          |

### Code intelligence

| Key                           | Action                                                                    |
| ----------------------------- | ------------------------------------------------------------------------- |
| `gd` `gr` `gI` `gy` `gD` `gK` | Definition, references, implementations, type def, declaration, signature |
| `<leader>ca` `<leader>cA`     | Code action, source action                                                |
| `<leader>cc` `<leader>cC`     | Run / refresh codelens                                                    |
| `<leader>cr` `<leader>cR`     | Incremental rename, rename file                                           |
| `<leader>cf` `<leader>cd`     | Format, line diagnostics                                                  |
| `]d` `[d` `]e` `[e` `]w` `[w` | Diagnostics, errors, warnings                                             |
| `]]` `[[`                     | Next/prev reference (Snacks words)                                        |
| `<leader>uh`                  | Toggle inlay hints                                                        |
| `<leader>cs`, `{` `}`         | Aerial symbols                                                            |
| `<leader>ss` `<leader>sS`     | LSP / workspace symbols                                                   |

### Git

| Key                                                                 | Action                                                                                 |
| ------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `<leader>gg` / `<leader>gG`                                         | Lazygit at root / cwd                                                                  |
| `gd` `gs` `gS` `gl` `gL` `gf`                                       | Diff, status, stash, log, log line, file history (pickers)                             |
| `<leader>gi` `gI` `gp` `gP`                                         | GitHub issues/PRs (open / all)                                                         |
| `<leader>gb` `<leader>gB` `<leader>gY`                              | Blame, browse open, browse copy                                                        |
| `]h` `[h` `]H` `[H`                                                 | Hunk navigation                                                                        |
| `<leader>ghs` `ghr` `ghS` `ghu` `ghR` `ghp` `ghb` `ghB` `ghd` `ghD` | Stage, reset, stage buffer, undo stage, reset buffer, preview, blame line/buffer, diff |
| `ih`                                                                | Select hunk                                                                            |
| `<leader>go`                                                        | mini.diff overlay                                                                      |
| `<leader>Go` `Gc` `Gf` `GF`                                         | Diffview open/close/file history/repo history                                          |
| `<leader>gu` `gU`                                                   | Gitlinker open/copy                                                                    |
| `<leader>ha` `hh` `h1`–`h4`                                         | Harpoon                                                                                |

### Debug, test, AI, misc

| Key                                                                                               | Action                                                                  |
| ------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| `<leader>db` `dB` `dc` `dC` `di` `do` `dO` `dP` `dg` `dj` `dk` `dl` `dr` `ds` `dt` `dw` `du` `de` | DAP: breakpoints, continue, step, REPL, UI, eval                        |
| `<leader>tt` `tT` `tr` `tl` `ts` `to` `tO` `tS` `tw` `td`                                         | Neotest: run file/all/nearest/last, summary, output, stop, watch, debug |
| `<leader>ac` `an` `ai` `ao` `ae`                                                                  | CodeCompanion: toggle chat, new chat, inline, actions, add to chat      |
| `<leader>rs` `ri` `rI` `rb` `rf` `re` `rF` `rx` `rp` `rP` `rc`                                    | Refactoring                                                             |
| `<C-a>` / `<C-x>` (`g<C-a>`/`g<C-x>` visual)                                                      | Dial increment/decrement                                                |
| `<leader>p`, `y` `p` `P` `gp` `gP` `[y` `]y`, `]p` `[p` `]P` `[P`, `>p` `<p` `>P` `<P`, `=p` `=P` | Yanky history and put variants                                          |
| `<leader>.` / `<leader>S` / `<leader>un`                                                          | Scratch, select scratch, dismiss notifications                          |
| `<leader>ui` / `<leader>uI`                                                                       | Inspect position / treesitter tree                                      |
| `<leader>dps` / `<leader>dpp` / `<leader>dph`                                                     | Profiler scratch, toggle, highlights                                    |
| `<leader>ue` / `<leader>uE`                                                                       | Edgy toggle / select                                                    |
| `<leader>D` / `<leader>cp`                                                                        | DBUI / Markdown preview                                                 |
| `<leader>mu` / `<leader>mq`                                                                       | Multicursor word / clear                                                |
| `<leader>um`                                                                                      | CSV view toggle                                                         |
| `<leader>uu`                                                                                      | Undotree                                                                |

`ga`/`gA` (mini.align), `gz=`/`gzx`/`gzm`/`gzr`/`gzs` (mini.operators), and the
`[c`/`]c`, `[x`/`]x`, `[f`/`]f`, `[i`/`]i`, `[j`/`]j`, `[l`/`]l`, `[o`/`]o`
mini.bracketed motions round out the set.

> Most plugins are lazy-loaded, so a mapping only exists after its plugin has
> loaded — e.g. `<leader>us`…`<leader>ut` register once Snacks loads, and
> `<leader>ol` after Octo. `:map <leader>u` right after startup may look empty
> until then.

## Autocmds

- `checktime` on focus/terminal close so externally changed files reload.
- Highlight on yank (`vim.hl.on_yank`).
- Equalize splits on `VimResized`.
- Restore last cursor position on `BufReadPost` (except `gitcommit`).
- `q` closes help, quickfix, notify, neotest, trouble, and other transient
  buffers.
- Wrap + spell for text, markdown, typst, gitcommit; conceal off for JSON.
- Create missing parent directories on `BufWritePre`.
- ESLint `LspEslintFixAll` on save for JS/TS.

## Lua helpers

- `_G.Root()` — git root, falling back to `cwd`; used by all picker mappings.
- Filetype detection for dotfiles (`.env`, `tsconfig.json`, docker-compose,
  waybar, mako, kitty, hypr, ghostty, alacritty, fish).
- Snacks toggle registrations (listed under Snacks above).

## Design notes and pitfalls

- **Formatting needs an explicit enable** when an LSP is configured (Go, Rust).
- **`tm` vs `timeoutlen`** must match; see Core.
- **`markdownlint-cli2`** is already registered by nvf's markdown module.
- **`nvim-treesitter-textobjects`** was removed: nvf's module calls an API this
  plugin version no longer exposes, so it only added weight.
- **`nvim-ufo` is not used.** It calls `require("async")(...)`, but
  `refactoring.nvim` depends on `async.nvim`, which ships a non-callable table at
  `lua/async.lua`; `promise-async` ships a different callable under the same
  name. `refactoring` needs `async.wrap`, ufo needs `async(...)` — the two
  cannot coexist. Treesitter provides folding instead.
- **Keymap prefixes are deliberately collision-free**: `g*` is saturated, hence
  `<leader>G` for Diffview and `gz*` for mini.operators. Check WhichKey groups
  before claiming a new prefix.
- Headless `checkhealth` reports Snacks `vim.ui.*`/dashboard errors because those
  are wired on `UIEnter`; they do not occur in a real session.

## Verifying changes

```sh
# Build the configured Neovim derivation (exits non-zero on eval/build errors)
drv=$(nix eval --raw .#homeConfigurations.mohamed.config.home.packages \
  --apply 'xs: (builtins.head (builtins.filter (x: (x.name or "") == "nvf-with-helpers") xs)).drvPath')
nix build --no-link "$drv"

# After switching, smoke-test startup and health
nvim --headless "+lua print('ok')" +qa
nvim --headless "+checkhealth" +qa

# Lint/format only what you touched; `nix fmt` currently rewrites the secrets
# YAML and the generated flake.nix, so scope it or revert those files.
statix check modules/aspects/editor/neovim
deadnix modules/aspects/editor/neovim
alejandra --check modules/aspects/editor/neovim
```
