# My NixOS Configuration

Flake-parts + Den NixOS configuration.

- **Host:**
  - **Crazy:** Toshiba Satellite C50-A559, 8GB RAM, 110GB SSD, Intel i3-4005U, Intel HD Graphics 4400 & Nvidia GF 720M
  - **VPS1:** OVH VPS, 4vCPU, 8GB RAM, 75GB SSD
- **Stack:** Flakes, flake-parts, Den, Home Manager · **Secrets:** SOPS-Nix + age
- **Users:** `mohamed` (primary), `koko`, `kids`

This repository is public. Encrypted SOPS files are safe to commit as long as **no private decryption keys are ever committed**.

## Contents

- [My NixOS Configuration](#my-nixos-configuration)
  - [Contents](#contents)
  - [1. Architecture](#1-architecture)
  - [2. Secrets and keys](#2-secrets-and-keys)
    - [Recipient policy (`.sops.yaml`)](#recipient-policy-sopsyaml)
    - [Recovery scenarios](#recovery-scenarios)
  - [3. Repository structure](#3-repository-structure)
    - [Desktop profiles](#desktop-profiles)
    - [Theming](#theming)
    - [Git, signing, and the shell](#git-signing-and-the-shell)
    - [Firewall and session](#firewall-and-session)
  - [4. Requirements](#4-requirements)
  - [5. Installation](#5-installation)
  - [6. Key recovery and provisioning](#6-key-recovery-and-provisioning)
    - [Path A — Restore existing keys](#path-a--restore-existing-keys)
    - [Path B — Generate new keys](#path-b--generate-new-keys)
  - [7. Install NixOS](#7-install-nixos)
  - [8. First boot](#8-first-boot)
  - [9. Backup and recovery](#9-backup-and-recovery)
  - [10. Adding users](#10-adding-users)
  - [11. Rotating keys](#11-rotating-keys)
  - [12. VPS](#12-vps)
  - [License](#license)

## 1. Architecture

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

## 2. Secrets and keys

Two root keys form the root of trust. They are never stored in SOPS and must be backed up independently.

| Key                  | Location                                          | Backup      |
| -------------------- | ------------------------------------------------- | ----------- |
| Host SSH private key | `/persist/etc/ssh/ssh_host_ed25519_key`           | Mandatory   |
| Host SSH public key  | `/persist/etc/ssh/ssh_host_ed25519_key.pub`       | Recommended |
| Admin age identity   | `/persist/home/mohamed/.config/sops/age/keys.txt` | Mandatory   |

User private keys live encrypted in `secrets/users/<user>.yaml` and are deployed into persistent homes. Each user has a separate SSH key and, except Mohamed (who uses the admin identity), a separate age identity.

The host SSH key is converted to an age identity by SOPS-Nix; the admin age identity edits secrets outside the installed machine.

### Recipient policy (`.sops.yaml`)

| File                         | Recipients                      |
| ---------------------------- | ------------------------------- |
| `secrets/hosts/crazy.yaml`   | Admin, host                     |
| `secrets/users/mohamed.yaml` | Admin, host, Mohamed SSH        |
| `secrets/users/koko.yaml`    | Admin, host, Koko age, Koko SSH |
| `secrets/users/kids.yaml`    | Admin, host, Kids age, Kids SSH |

**Never combine user rules into one shared rule.** One user must not be able to decrypt another's file.

### Recovery scenarios

| Lost key       | Consequence                                                     |
| -------------- | --------------------------------------------------------------- |
| Host key       | Admin key can decrypt and re-encrypt                            |
| Admin key      | Host can still decrypt on the machine; external editing is lost |
| User key       | Admin or host can recover the encrypted copy                    |
| Both root keys | Secrets are unrecoverable unless another recipient exists       |

## 3. Repository structure

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
    ├── ai/                 # commandcode, omniroute, opencode
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

## 4. Requirements

- UEFI NixOS installer USB and network access.
- This repository.
- Backup of both root keys (if restoring).

The Disko config targets `disk.device = "/dev/sda";`. **This disk will be destroyed.** Verify first:

```bash
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS
```

## 5. Installation

```bash

sudo -i
export NIX_CONFIG="experimental-features = nix-command flakes"
nix shell nixpkgs#git -c git clone https://github.com/elkebirmed/nixconfig nixconfig
cd nixconfig
```

Partition and mount (**destroys the target disk**):

```bash
nix run github:nix-community/disko/latest -- \
  --mode destroy,format,mount --flake .#crazy
findmnt -R /mnt
```

Enter the tools shell:

```bash
nix develop
```

## 6. Key recovery and provisioning

Do you have a backup of **both** root keys? Yes → Path A. No → Path B.

### Path A — Restore existing keys

```bash
install -d -m 0755 /mnt/persist/etc/ssh
install -m 0600 /path/to/backup/ssh_host_ed25519_key     /mnt/persist/etc/ssh/ssh_host_ed25519_key
install -m 0644 /path/to/backup/ssh_host_ed25519_key.pub /mnt/persist/etc/ssh/ssh_host_ed25519_key.pub

install -d -m 0700 /mnt/persist/home/mohamed/.config/sops/age
install -m 0600 /path/to/backup/keys.txt /mnt/persist/home/mohamed/.config/sops/age/keys.txt
```

Verify (**do not continue on mismatch**):

```bash
ssh-to-age < /mnt/persist/etc/ssh/ssh_host_ed25519_key.pub   # must match &host_crazy
age-keygen -y /mnt/persist/home/mohamed/.config/sops/age/keys.txt   # must match &admin_mohamed
```

Nothing in the repository needs editing. Continue at [7](#7-install-nixos).

### Path B — Generate new keys

**B1. Host SSH key**

```bash
install -d -m 0755 /mnt/persist/etc/ssh
ssh-keygen -t ed25519 -N "" -C crazy -f /mnt/persist/etc/ssh/ssh_host_ed25519_key
ssh-to-age < /mnt/persist/etc/ssh/ssh_host_ed25519_key.pub
```

Replace `&host_crazy` in `.sops.yaml` with the output.

**B2. Admin age identity**

```bash
install -d -m 0700 /mnt/persist/home/mohamed/.config/sops/age
age-keygen -o /mnt/persist/home/mohamed/.config/sops/age/keys.txt
age-keygen -y /mnt/persist/home/mohamed/.config/sops/age/keys.txt
```

Replace `&admin_mohamed` in `.sops.yaml`. **Back up both root keys now**, outside the machine.

**B3. Per-user keys** (from the repo root)

```bash
for u in koko kids; do
  age-keygen -o "$u-age.txt" 2>/dev/null
  ssh-keygen -q -t ed25519 -N "" -C "$u@crazy" -f "$u-ssh"
  echo "age_$u: $(age-keygen -y "$u-age.txt")"
  echo "ssh_$u: $(ssh-to-age < "$u-ssh.pub")"
done

ssh-keygen -q -t ed25519 -N "" -C "mohamed@crazy" -f mohamed-ssh
echo "ssh_mohamed: $(ssh-to-age < mohamed-ssh.pub)"
```

**B4. Update `.sops.yaml`**

Replace the anchors `&admin_mohamed`, `&host_crazy`, `&ssh_mohamed`, `&age_koko`, `&ssh_koko`, `&age_kids`, `&ssh_kids`. Leave `creation_rules` unchanged.

**B5. Set the admin identity**

```bash
export SOPS_AGE_KEY_FILE=/mnt/persist/home/mohamed/.config/sops/age/keys.txt
```

**B6a. Old secrets still decryptable**

Use the old admin key (`SOPS_AGE_KEY_FILE=/path/to/OLD/keys.txt`) or old host key
(`SOPS_AGE_KEY=$(ssh-to-age -private-key -i /path/to/old/ssh_host_ed25519_key)`), then:

```bash
for f in secrets/hosts/crazy.yaml secrets/users/*.yaml; do sops updatekeys -y "$f"; done
```

Replace any regenerated user private keys.

**B6b. No old secrets decryptable**

```bash
rm -f secrets/hosts/crazy.yaml secrets/users/*.yaml
mkdir -p secrets/hosts secrets/users
printf 'initialized: true\n' > secrets/hosts/crazy.yaml

sops encrypt -i secrets/hosts/crazy.yaml

jqs() { jq -Rs . < "$1"; }

for u in mohamed koko kids; do
  HASH=$(mkpasswd -m yescrypt)
  printf 'passwords:\n  %s: "%s"\n' "$u" "$HASH" > "secrets/users/$u.yaml"
  sops encrypt -i "secrets/users/$u.yaml"
  sops set "secrets/users/$u.yaml" "[\"email\"][\"$u\"]" "\"you@example.com\""
  sops set "secrets/users/$u.yaml" "[\"ssh\"][\"$u\"]" "$(jqs "$u-ssh")"
done

for u in koko kids; do
  sops set "secrets/users/$u.yaml" "[\"age\"][\"$u\"]" "$(jqs "$u-age.txt")"
done

sops set secrets/users/mohamed.yaml '["github"]["mohamed"]' '"ghp_xxx"'
```

Replace placeholder emails and the token. Secret names must match the Nix config: `passwords/<user>`, `email/<user>`, `ssh/<user>`, `age/<user>`, `github/<user>`.

**B7. Verify and clean up**

```bash
export SOPS_AGE_KEY=$(ssh-to-age -private-key -i /mnt/persist/etc/ssh/ssh_host_ed25519_key)
for u in mohamed koko kids; do
  sops decrypt --extract "[\"passwords\"][\"$u\"]" "secrets/users/$u.yaml" >/dev/null && echo "$u: OK"
done
unset SOPS_AGE_KEY
```

All three must succeed. Then remove temporary plaintext keys once backups are safe:

```bash
shred -u koko-age.txt kids-age.txt koko-ssh kids-ssh mohamed-ssh *.pub 2>/dev/null
```

`shred` is unreliable on SSDs, copy-on-write, and journaled filesystems. Confirm no private keys are staged (`git status`), then:

```bash
git add .sops.yaml secrets
git commit -m "Rotate keys and initialize secrets"
```

## 7. Install NixOS

If the hardware differs, regenerate and stage the hardware config (flakes ignore untracked files):

```bash
nixos-generate-config --no-filesystems --show-hardware-config > modules/hosts/crazy/_nixos/hardware-configuration.nix
git add modules/hosts/crazy/_nixos/hardware-configuration.nix
```

Safety check: the host key must decrypt Mohamed's hash (typically starts with `$y$`). **If it fails, do not install.**

```bash
SOPS_AGE_KEY=$(ssh-to-age -private-key -i /mnt/persist/etc/ssh/ssh_host_ed25519_key) \
  sops decrypt --extract '["passwords"]["mohamed"]' secrets/users/mohamed.yaml
```

Install, keep a copy of the repo on persistent storage, and reboot:

```bash
nixos-install --flake .#crazy --no-root-password

mkdir -p /mnt/persist/home/mohamed/Projects
cp -a /root/nixconfig /mnt/persist/home/mohamed/Projects/nixconfig
reboot
```

## 8. First boot

Log in as `mohamed` with the password stored in SOPS.

Fix persistent home ownership if needed (activation may create root-owned directories):

```bash
for u in mohamed koko kids; do sudo chown -R "$u": "/persist/home/$u"; done
```

Verify:

```bash
ls -l ~/.ssh/id_ed25519 ~/.config/sops/age/keys.txt
systemctl --user restart sops-nix   # if it started before ownership was fixed
git config user.email
git config --get gpg.format          # must print: ssh
gh auth status                      # GitHub token is for Mohamed only

# rustup ships without a toolchain; install it once, then it persists.
rustup toolchain install stable --profile minimal
rustup default stable

# Apply the palette to every configured application.
noctalia msg templates-apply
noctalia-theme list
```

## 9. Backup and recovery

Back up (offline, two separate locations, e.g. password manager or encrypted USB):

```text
/persist/etc/ssh/ssh_host_ed25519_key
/persist/etc/ssh/ssh_host_ed25519_key.pub
/persist/home/mohamed/.config/sops/age/keys.txt
```

Never keep the only copy on the machine. Test backups by restoring to a temp directory and comparing `ssh-to-age < ssh_host_ed25519_key.pub` and `age-keygen -y keys.txt` with `.sops.yaml`.

**Disk failure:** obtain the repo, restore both root keys, verify recipients, partition/mount the new disk, follow Path A, install, verify, reboot.

**Both root keys lost:** generate new root and user keys, update `.sops.yaml`, recreate all secrets, verify, and install via Path B.

## 10. Adding users

1. Create the user aspect including `den.aspects.user-ssh-key`, `den.aspects.sops-home`, and `den.aspects.user-age-key` (if an age identity is needed).
2. Generate the SSH key and optional age identity.
3. Add recipient anchors and a dedicated creation rule for `secrets/users/<user>.yaml` in `.sops.yaml`.
4. Create the encrypted file with the password hash and key entries; verify host decryption.
5. Rebuild, then verify ownership and Home Manager activation.

Never authorize one user's key to decrypt another user's file.

## 11. Rotating keys

**User SSH key / age identity:** generate a new key, update its recipient in `.sops.yaml`, replace the encrypted private key in the user's file, run `sops updatekeys`, verify host decryption, rebuild, and verify deployment.

**Root key:** update the recipient policy and re-encrypt all affected files. Keep the old key until the new one and its backups are verified.

## 12. VPS

### What this host is

`vps` is a single x86_64 virtual machine (4 vCPU, 8 GB RAM, 75 GB disk).
It boots in **BIOS/GRUB** mode from `/dev/sda` with a **GPT + ext4** layout
(`disko-bios`), and it is a QEMU/virtio guest. These facts come from the checked
in `disko-bios` and hardware configuration; do not assume UEFI or btrfs.

A single node provides no high availability. There is no cluster, no replication,
and no failover.

### Architecture and trust boundaries

```text
                     public 80/443 (+443/udp)
                              │
                        ┌─────▼─────┐
                        │   Caddy   │  only public ingress, TLS via DNS-01
                        └─────┬─────┘
             tailnet guard: not remote_ip 100.64.0.0/10 fd7a:...
                    ┌─────────┼──────────┬───────────┐
             127.0.0.1:20128    :3000     :9090     :18789
              OmniRoute        Grafana   Prometheus  OpenClaw
              (Quadlet)                              (user service)

  SSH: port 22 only on tailscale0 — never on the public interface.
```

- **Caddy** is the only public entry point. Backends bind to `127.0.0.1` and are
  never published on a public interface.
- **Tailnet-only sites** (the default) abort any request whose `remote_ip` is not
  in the tailnet ranges. Only `access = "public"` skips that guard.
- **SSH** is reachable only on `tailscale0` (`den.hosts.…ssh.interfaces`). Root
  SSH is disabled and password auth is off.
- **Two accounts**: `ops` (uid 1001, `wheel`, passwordless sudo) is the only
  administrative account. `claw` (uid 1002) is unprivileged: no groups, no sudo,
  no SSH keys.

### Desktop vs server aspects

The desktop host `crazy` and the server host `vps` share only generic aspects
(user accounts, SOPS plumbing, firewall, locale). Server-only aspects
(`web`, `quadlet`, `monitoring`, `backups`, `private-app`, `network-vps`,
`openclaw`) are included from `modules/hosts/vps.nix` only. Adding a server
aspect to `crazy` is a bug, not a convenience.

### Network address handling

The static WAN IPv6 address and its gateway are infrastructure identifiers and
are **not** committed. `modules/aspects/server/network.nix` declares
`network.v6.{address,gateway}` with `REDACTED_IPV6*` placeholders.

This is a **documented exception** to the runtime-secret rule: systemd-networkd
needs the address at boot, before SOPS has decrypted anything, so it cannot be
rendered into `/run`. Set the real values locally (or from a private overlay) and
never commit them.

### First install (destructive — owner approval required)

> Do not run this from an automated agent. It erases the target disk.

```bash
# Requires etc/ssh/ssh_host_ed25519_key{,.pub} in an --extra-files tree,
# generated outside the repository and backed up separately.
nix run github:nix-community/nixos-anywhere -- \
  --flake .#vps \
  --target-host ops@VPS_SSH_ALIAS \
  --extra-files ~/.config/nixconfig-vps/extra-files \
  --build-on remote
```

`VPS_SSH_ALIAS` is a **local SSH alias**. Its real `HostName` lives only in your
private `~/.ssh/config`, so no address ever enters this repository:

```sshconfig
Host VPS_SSH_ALIAS
  HostName REDACTED_IP
  User ops
  IdentityFile ~/.ssh/id_ed25519
```

### Deploying updates

```bash
# Build locally first — this is the same closure CI builds.
nix build .#nixosConfigurations.vps.config.system.build.toplevel --no-link

# Then switch over the tailnet. `restartIfChanged = false` on tailscaled keeps
# the tunnel (and this SSH session) up across the switch.
sudo nixos-rebuild switch --flake .#vps \
  --target-host ops@VPS_SSH_ALIAS \
  --build-host ops@VPS_SSH_ALIAS \
  --use-remote-sudo
```

Kernel and initrd changes are **not** applied by `switch`. Use
`nixos-rebuild boot` and reboot at a chosen time.

### Containers: Quadlet only

`quadlet-nix` is the single declarative container interface
(`virtualisation.quadlet`). Do not add a second container framework, and do not
introduce Komodo, Kubernetes, k3s, Argo CD, or Helm for a single VPS.

Rules for every container:

- Images are pinned **by digest**. A `:latest` reference fails an assertion in
  `modules/aspects/virtualisation/quadlet.nix`.
- Loopback-only `PublishPort`, no `Privileged`, no host networking, no host PID.
- `NoNewPrivileges`, `DropCapability=all`, `ReadOnly` with a small `Tmpfs`, plus
  `MemoryMax`/`CPUQuota`.
- One explicit persistent data directory per stateful app.

OmniRoute (`modules/aspects/ai/_omniroute-lib.nix`) is the reference example.

### Private application images

A private image reference must never appear in the Nix store. Quadlet does **not**
expand environment variables in `Image=`, so the image cannot be injected through
an `EnvironmentFile`.

Instead, `modules/aspects/server/private-app.nix` uses Quadlet's runtime search
path. The image reference lives in SOPS; a oneshot renders the real unit into
`/run/containers/systemd/<name>.container` (which takes precedence over `/etc` and
`/usr/share`) and then runs `systemctl daemon-reload`.

```nix
# modules/hosts/vps.nix
vps.privateApps.app-a = {
  description = "App A";
  secretName = "app-image-a";   # SOPS key holding the real image ref
  port = 8081;                  # loopback host port
  containerPort = 8080;
  dataDir = "/var/lib/app-a";
  containerPath = "/data";
  access = "tailnet";
};
```

Trade-offs: the unit is regenerated on every activation and on secret rotation,
and a `daemon-reload` is required before the unit can start.

### OpenClaw boundary

OpenClaw is an **assistant**, not an operator. It runs as `claw` with:

- no shell toolchain — `programs.openclaw.toolNames = []` removes the upstream
  default `git`/`curl`/`jq`/`python3`/`node`/`pnpm` PATH;
- no host terminal (`gateway.terminal.enabled = false`; upstream defaults it on);
- no browser control UI (`gateway.controlUi.enabled = false`), which also keeps a
  hostname out of the generated config;
- uploads disabled, no runtime packages, no Podman/Nix socket, no SOPS identity,
  no SSH key, no deployment credentials;
- a hardened systemd user unit: empty `CapabilityBoundingSet`,
  `SystemCallFilter=@system-service`, `ProtectSystem=strict`,
  `ProtectHome=read-only`, `NoNewPrivileges`, `RestrictAddressFamilies` limited to
  inet/inet6/unix.

Residual risk (not a control we have): the gateway needs **outbound** HTTPS for
OmniRoute and Telegram, so egress is broad. It cannot be restricted to Telegram
CIDRs without pinning them, which would be brittle.

### Monitoring

Proportionate for one node: node exporter + Prometheus + Grafana, all on
loopback and exposed only through tailnet-guarded Caddy routes
(`metrics`, `grafana`).

- Prometheus retains 14 days with a 2 GB cap (`MemoryMax=768M`).
- Grafana is capped at `MemoryMax=512M`; anonymous access and sign-up are off.
- No Loki and no alerting backend. Add them only when measurements justify it.

### Backups and restore

`modules/aspects/server/backups.nix` configures restic for application state.
Both the repository location and password are read at **runtime** from
SOPS-rendered files, so neither enters the store. The job is **disabled by
default** and stays inert until the required secrets exist.

Restore drill — run this on a schedule, not just once:

```bash
# 1. List snapshots (as root; uses the same env as the timer).
systemctl start restic-backups-appdata.service
restic-appdata snapshots

# 2. Restore into a scratch dir.
restic-appdata restore latest --target /var/tmp/restore-test

# 3. Verify the important trees exist and are non-empty.
du -sh /var/tmp/restore-test/var/lib/omniroute
du -sh /var/tmp/restore-test/home/claw/.openclaw

# 4. Remove the scratch copy.
rm -rf /var/tmp/restore-test
```

A backup that has never been restore-tested is not a backup.

### What survives a reboot

`vps` uses a **persistent ext4 root**, unlike `crazy`, which uses Impermanence.
Everything under `/` survives. The `systemPersistence` entry in
`modules/aspects/server/tailscale.nix` therefore has no effect on this host — it
only matters on `crazy`. Each stateful service still declares its data directory
explicitly so ownership is correct on a fresh install:

| Service       | Path                           | Owner         |
| ------------- | ------------------------------ | ------------- |
| OmniRoute     | `/var/lib/omniroute`           | `10001:10001` |
| OmniRoute key | `/var/lib/omniroute-bootstrap` | `claw`        |
| OpenClaw      | `/home/claw/.openclaw`         | `claw`        |
| Prometheus    | `/var/lib/prometheus`          | `prometheus`  |
| Grafana       | `/var/lib/grafana`             | `grafana`     |
| Tailscale     | `/var/lib/tailscale`           | root          |
| private apps  | `/var/lib/<app>`               | per app       |

### DNS as code

`infra/dns/` holds the Cloudflare configuration. Every private value (zone name,
records, addresses, token) is a variable with no committed default, and state
lives outside the repository. See `infra/dns/README.md`.

`tofu fmt -check` and `tofu validate` are safe. Never paste plan output anywhere
public, and never `apply` without owner approval.

### Rollback and recovery

- **NixOS**: pick a previous generation in the boot menu, or
  `sudo nixos-rebuild switch --rollback`.
- **OpenClaw**: `home-manager generations` then
  `home-manager switch --rollback` as `claw` (via `machinectl shell claw@`). This
  restores config and packages, not OpenClaw's mutable state.
- **Out of band**: the provider's KVM console and rescue mode.
- **Lockout safety**: if a firewall change would cut SSH, keep the KVM console
  open before switching. Because SSH is tailnet-only, a broken `tailscaled` is a
  lockout — `tailscaled.restartIfChanged = false` and the console are the
  recovery path.

### Owner actions

These secret **names** must exist in `secrets/hosts/vps.yaml` before the features
that use them are enabled. Do not paste values anywhere; add them with `sops`.

| Secret                    | Used by            | Notes                                    |
| ------------------------- | ------------------ | ---------------------------------------- |
| `web-domain`              | Caddy, Grafana     | Base domain (placeholder in source).     |
| `acme-email`              | Caddy              | ACME contact address.                    |
| `tailscale-auth-key`      | Tailscale          | Already present.                         |
| `cloudflare-api-token`    | Caddy DNS-01       | Separate from the OpenTofu token.        |
| `openclaw-gateway-token`  | OpenClaw           | Already present.                         |
| `openclaw-telegram-token` | OpenClaw           | Already present.                         |
| `grafana-admin-password`  | Grafana            |                                          |
| `grafana-secret-key`      | Grafana            | Random hex, e.g. `openssl rand -hex 32`. |
| `git-email`               | `ops` git identity | Host-scoped, not a user file.            |
| `restic-password`         | Backups            | Enables the backup job.                  |
| `restic-repository`       | Backups            | Private destination.                     |
| `omniroute/*`             | OmniRoute          | Already present.                         |

Manual steps:

1. Set the real IPv6 address/gateway in `modules/hosts/vps.nix` locally.
2. Create the `VPS_SSH_ALIAS` entry in your private `~/.ssh/config`.
3. Export `TF_VAR_*` for OpenTofu in a protected shell.
4. Rotate the historical items listed in the audit report if you decide the
   exposure matters.

## License

Personal infrastructure. Use as a reference, but review the Disko, Impermanence, and SOPS settings carefully before adapting it to another machine.
