# My NixOS Configuration

Flake-parts + Den NixOS configuration for the `crazy` host.

**Host:** `crazy` · **Disk:** Btrfs via Disko · **Root:** ephemeral (Impermanence)
**Stack:** Flakes, flake-parts, Den, Home Manager · **Secrets:** SOPS-Nix + age
**Users:** `mohamed`, `koko`, `kids`

This repository is public. Encrypted SOPS files are safe to commit as long as **no private decryption keys are ever committed**.

More details: https://github.com/elkebirmed/nixconfig

---

## Contents

1. [Architecture](#1-architecture)
2. [Secrets and keys](#2-secrets-and-keys)
3. [Repository structure](#3-repository-structure)
4. [Requirements](#4-requirements)
5. [Installation](#5-installation)
6. [Key recovery and provisioning](#6-key-recovery-and-provisioning)
7. [Install NixOS](#7-install-nixos)
8. [First boot](#8-first-boot)
9. [Backup and recovery](#9-backup-and-recovery)
10. [Adding users](#10-adding-users)
11. [Rotating keys](#11-rotating-keys)

---

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

Only explicitly preserved data survives reboot (SSH host identity, user homes, SOPS age identity, user SSH keys, required system state). New application state must be added to the Impermanence configuration.

---

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

---

## 3. Repository structure

Organized around Den and import-tree. The host config is `modules/hosts/crazy.nix`. The hardware config is named `_hardware-configuration.nix` so import-tree does not treat it as a standalone aspect.

---

## 4. Requirements

- UEFI NixOS installer USB and network access.
- This repository.
- Backup of both root keys (if restoring).

The Disko config targets `disk.device = "/dev/sda";`. **This disk will be destroyed.** Verify first:

```bash
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS
```

---

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

---

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

---

## 7. Install NixOS

If the hardware differs, regenerate and stage the hardware config (flakes ignore untracked files):

```bash
nixos-generate-config --no-filesystems --show-hardware-config > modules/hosts/_hardware-configuration.nix
git add modules/hosts/_hardware-configuration.nix
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

---

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
gh auth status                      # GitHub token is for Mohamed only

```

---

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

---

## 10. Adding users

1. Create the user aspect including `den.aspects.user-ssh-key`, `den.aspects.sops-home`, and `den.aspects.user-age-key` (if an age identity is needed).
2. Generate the SSH key and optional age identity.
3. Add recipient anchors and a dedicated creation rule for `secrets/users/<user>.yaml` in `.sops.yaml`.
4. Create the encrypted file with the password hash and key entries; verify host decryption.
5. Rebuild, then verify ownership and Home Manager activation.

Never authorize one user's key to decrypt another user's file.

---

## 11. Rotating keys

**User SSH key / age identity:** generate a new key, update its recipient in `.sops.yaml`, replace the encrypted private key in the user's file, run `sops updatekeys`, verify host decryption, rebuild, and verify deployment.

**Root key:** update the recipient policy and re-encrypt all affected files. Keep the old key until the new one and its backups are verified.

---

## License

Personal infrastructure. Use as a reference, but review the Disko, Impermanence, and SOPS settings carefully before adapting it to another machine.
