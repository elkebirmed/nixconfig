# My NixOS Configuration

Flake-parts + Den NixOS configuration.

- **Host:**
  - **Crazy:** Toshiba Satellite C50-A559, 8GB RAM, 110GB SSD, Intel i3-4005U, Intel HD Graphics 4400 & Nvidia GF 720M
  - **VPS1:** OVH VPS, 4vCPU, 8GB RAM, 75GB SSD
- **Stack:** Flakes, flake-parts, Den, Home Manager · **Secrets:** SOPS-Nix + age
- **Users:** `mohamed` (primary), `koko`, `kids`

This repository is public. Encrypted SOPS files are safe to commit as long as **no private decryption keys are ever committed**.

## Documentation

| Document                                         | Covers                                                                   |
| ------------------------------------------------ | ------------------------------------------------------------------------ |
| [`docs/install.md`](docs/install.md)             | Requirements, disko, key recovery, `nixos-install`, first boot.          |
| [`docs/security.md`](docs/security.md)           | Root keys, SOPS recipient policy, backups, adding users, key rotation.   |
| [`docs/configuration.md`](docs/configuration.md) | Module layout, desktop profiles, theming, git and the shell.             |
| [`docs/deploy.md`](docs/deploy.md)               | Build, switch, rollback, and what a deploy does not cover.               |
| [`docs/vps.md`](docs/vps.md)                     | The server: trust boundaries, deploys, containers, monitoring, recovery. |
| [`docs/openclaw.md`](docs/openclaw.md)           | The assistant on the VPS: sandbox boundary, GitHub publishing, models.   |
| [`docs/nvim.md`](docs/nvim.md)                   | Neovim via nvf: plugins, LSP, languages, keymaps.                        |
| [`docs/web-resources.md`](docs/web-resources.md) | Where the Nix lives, plus every external host the config reaches.        |
| [`infra/dns/README.md`](infra/dns/README.md)     | Cloudflare DNS as OpenTofu, decoupled from deploys.                      |

`docs/vps.md` and `docs/openclaw.md` describe the server; everything else applies to both hosts unless a section says otherwise.

## Architecture

- **flake-parts:** organizes flake outputs.
- **import-tree:** auto-imports the module tree.
- **Den:** composes hosts, users, and reusable aspects.
- **Home Manager:** user-level configuration.
- **Disko:** declarative partitioning.
- **Impermanence:** preserves selected state while root is wiped.
- **SOPS-Nix:** decrypts secrets at activation or user service startup.

| Mount      | Purpose                   | Persistence      |
| ---------- | ------------------------- | ---------------- |
| `/`        | System root               | Wiped every boot |
| `/boot`    | EFI system partition      | Persistent       |
| `/nix`     | Nix store and profiles    | Persistent       |
| `/persist` | Explicitly preserved data | Persistent       |
| `/var/log` | System logs               | Persistent       |

Only explicitly preserved data survives reboot. New application state must be added to the Impermanence configuration.

## Repository layout

```text
modules/
├── flake/     # flake-parts outputs: devshell, nh, treefmt, vm
├── den/       # den wiring: defaults, dendritic, host declarations
├── hosts/     # one file per host, plus each host's _nixos/ internals
├── users/     # one file per user
└── aspects/   # reusable features, one aspect per file
```

Naming rules:

- One aspect per file, named after the aspect (`den.aspects.sops` → `aspects/security/sops.nix`).
- Directories group domains, not aspects, and use singular names (`network`, `storage`, `system`).
- `<entity>.nix` plus `<entity>/` for internals (`hosts/crazy.nix` + `hosts/crazy/`).
- Generated and class-scoped directories are `_`-prefixed so import-tree ignores them (`_nixos/`).
- kebab-case filenames, lowercase directories, no repeated path segments.

The full aspect tree, desktop profiles, and theming pipeline are in
[`docs/configuration.md`](docs/configuration.md).

## Quick start

```bash
git clone https://github.com/elkebirmed/nixconfig nixconfig
cd nixconfig
nix develop          # tools shell
nix build .#nixosConfigurations.crazy.config.system.build.toplevel --no-link
```

**Installing from scratch, or recovering a lost key?** Follow
[`docs/install.md`](docs/install.md). `disko` destroys the target disk; verify the
device with `lsblk` first.

Two root keys form the root of trust — the host SSH key and the admin age
identity. Back both up offline before the first install; see
[`docs/security.md`](docs/security.md).

## License

Personal infrastructure. Use as a reference, but review the Disko, Impermanence, and SOPS settings carefully before adapting it to another machine.
