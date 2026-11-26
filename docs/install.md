# Installation

Bare-metal install from the NixOS ISO: requirements, disko, key recovery, install, first boot.

Part of the [nixconfig](../README.md) documentation.

---

## Requirements

- UEFI NixOS installer USB and network access.
- This repository.
- Backup of both root keys (if restoring).

The Disko config targets `disk.device = "/dev/sda";`. **This disk will be destroyed.** Verify first:

```bash
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS
```

## Installation

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

## Key recovery and provisioning

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

Nothing in the repository needs editing. Continue at [Install NixOS](#install-nixos).

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

## Install NixOS

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

## First boot

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
