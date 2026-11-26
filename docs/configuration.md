# Repository configuration

Flake wiring, Den aspects, desktop profiles, theming, git and the shell.

Part of the [nixconfig](../README.md) documentation.

---

## Repository structure

Organized around Den and import-tree, with flake wiring kept separate from reusable aspects:

```text
modules/
├── flake/                  # flake-parts outputs: devshell, nh, treefmt, vm
├── den/                    # den wiring: defaults, dendritic, host declarations
├── hosts/
│   ├── crazy.nix
│   └── crazy/_nixos/hardware-configuration.nix
├── users/                  # one file per user
└── aspects/                # reusable features, one aspect per file
    ├── ai/                 # commandcode, opencode
    ├── cli/                # bat, fd, fzf, lsd, ripgrep, tuios, yazi
    ├── desktop/            # apps, cache, display-manager, niri(+base/pro/simple),
    │                       # noctalia(+pro/simple), polkit-keyring, theming, desktop
    ├── dev/                # languages (go, node, rust, python, terraform, just)
    ├── editor/neovim/      # nvf + sub-aspects
    ├── input/              # kanata
    ├── network/            # firewall, networking, openssh
    ├── security/           # sops
    ├── shell/              # completions, fish, prompt (starship/zoxide/direnv)
    ├── storage/            # btrfs-rollback, disko-btrfs, impermanence
    ├── system/             # audio, boot, fonts, graphics, locale, maintenance,
    │                       # nix-daemon, session, zram
    ├── terminal/           # kitty
    ├── virtualisation/     # podman
    ├── vcs/                # gh, git, lazygit
    └── dev-tools.nix
```

Naming rules:

- One aspect per file; aspect files are named after the aspect (`den.aspects.sops` → `aspects/security/sops.nix`).
- Directories group domains, not aspects; use singular domain names (`network`, `storage`, `system`).
- `<entity>.nix` plus `<entity>/` for internals (`hosts/crazy.nix` + `hosts/crazy/`).
- Generated files and class-scoped directories are `_`-prefixed so import-tree ignores them (`_nixos/`).
- kebab-case filenames, lowercase directories, no repeated path segments.

### Desktop profiles

All users share one Niri session (registered by the host-level `niri` aspect) and
one Noctalia Greeter, but each user's desktop is selected by a typed
`desktopProfile` option (`modules/den/schema.nix`, declared on `user` and `home`):

| Profile  | Who            | What they get                                                                                                                                                                              |
| -------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `full`   | `mohamed`      | Named workspaces, window/layer rules with blur, overview tuning, recent-windows switcher, screenshots, recording, full bar, magnifying dock, sysmon, weather/calendar, wallpaper rotation. |
| `simple` | `koko`, `kids` | Windows-like: `Super+Space` overview, `Super+Return` terminal, `Alt+Tab`/`Alt+F4`, large bottom dock and a minimal bar.                                                                    |

`den.aspects.desktop` (`modules/aspects/desktop/desktop.nix`) reads the profile
and includes `niri-base` + `noctalia` plus the matching `niri-pro`/`noctalia-pro`
or `niri-simple`/`noctalia-simple` aspects. The Noctalia Greeter defaults to
`mohamed` and syncs its appearance from the running shell.

### Theming

Noctalia drives the palette for every application. The data lives in
`modules/aspects/desktop/theming/` and is wired through Nix options only:

| Piece        | Where                                                                             |
| ------------ | --------------------------------------------------------------------------------- |
| Palettes     | `theming/palettes/*.json` → `~/.config/noctalia/palettes/` (names kept verbatim)  |
| Templates    | `theming/templates/*` → `~/.config/noctalia/templates/` (Noctalia's inputs)       |
| Template map | `programs.noctalia.settings.theme.templates.user.*` (input/output/`post_hook`)    |
| Wallpapers   | `assets/wallpapers/` → `~/Pictures/Wallpapers/`                                   |
| Overrides    | `theming/wallpaper-sources.toml` (palette → wallpaper directory)                  |
| Theme CLI    | `noctalia-theme` package (`next`, `prev`, `random`, `mode`, `wallpaper-*`, `set`) |
| Picker       | QuickShell `theme-switcher` on `Mod+P`                                            |

Rendered per application: niri (`colors.kdl`), kitty, fish, lsd, bat, fzf,
starship, yazi, lazygit, opencode, and Zen Browser (chrome + content CSS).
Hooks (`kitty` reload, `bat cache --build`, Zen sync) are built as packages and
referenced by path, so no scripts are written into the home directory.

Because Noctalia owns the generated files, do **not** also set the matching
Home Manager option (for example `programs.yazi.theme` or
`programs.starship.settings`); the two writers would fight over a store
symlink. This is why `theme.templates.builtin_ids` only lists `gtk3`/`gtk4`.

Binds in the `full` profile: `Mod+Shift+T` next palette, `Mod+Ctrl+Shift+T`
previous, `Mod+Alt+T` random, `Mod+Shift+Y` dark/light, `Mod+Shift+W`
next wallpaper, `Mod+Ctrl+Shift+W` previous, `Mod+Alt+W` random, `Mod+P`
picker. `Mod+Return` also opens kitty, and `Ctrl+Print`/`Alt+Print` use niri's
built-in screen/window screenshot actions.

### Git, signing, and the shell

- Commits are signed with the SSH key sops-nix deploys; `gpg.format = ssh` and
  `commit.gpgsign = true` are set globally. no GPG keyring is used.
- `delta` is the pager and `zdiff3` the merge conflict style; see
  `modules/aspects/vcs/git.nix` for the full set.
- `lazygit` reads its Noctalia theme through
  `LG_CONFIG_FILE=config.yml,themes/noctalia.yml` instead of rewriting
  `config.yml` (a Home Manager store symlink) at runtime.
- `gh` keeps the HTTPS protocol and its SOPS-backed token; git remotes are not
  rewritten to SSH.
- Fish gets `starship`, `zoxide`, `direnv` (nix-direnv), an interactive
  ripgrep helper on `Ctrl-G`, and `Ctrl-E` to jump to the parent directory.
- The `us,ara` xkb layout with `caps:none,grp:alt_shift_toggle,compose:ralt`
  is configured in niri; the console keymap stays `us`.

### Firewall and session

`modules/aspects/network/firewall.nix` enables nftables with a default-deny
inbound policy and only SSH open. `modules/aspects/system/session.nix` makes
logind ignore the power key (Noctalia handles it), raises the inotify watch
limit, and enables CUPS + Avahi/mDNS.
