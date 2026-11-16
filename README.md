# My NixOS Configuration

Flake-parts + Den NixOS configuration for the `crazy` host.

- **Hosts:** `crazy`
- **Disk layout:** Btrfs with Disko
- **Root filesystem:** ephemeral; reset on every boot using Impermanence
- **Configuration:** Flakes, flake-parts, Den, Home Manager
- **Secrets:** SOPS-Nix + age
- **Users:** `mohamed`, `koko`, `kids`

This repository is public. Encrypted SOPS files are safe to commit, provided their encryption is correct and **no private decryption keys are ever committed**.

---

## Contents

- [1. Architecture](#1-architecture)
- [2. Secrets and keys](#2-secrets-and-keys)
- [3. Repository structure](#3-repository-structure)
- [4. Requirements](#4-requirements)
- [5. Installation](#5-installation)
- [6. Key recovery and provisioning](#6-key-recovery-and-provisioning)
  - [Path A — Restore existing keys](#path-a--restore-existing-keys)
  - [Path B — Generate new keys](#path-b--generate-new-keys)
- [7. Install NixOS](#7-install-nixos)
- [8. First boot](#8-first-boot)
- [9. Backup and recovery](#9-backup-and-recovery)
- [10. Day-to-day operations](#10-day-to-day-operations)
- [11. Adding users](#11-adding-users)
- [12. Rotating keys](#12-rotating-keys)
- [13. Troubleshooting](#13-troubleshooting)
- [14. Security checklist](#14-security-checklist)

---

## 1. Architecture

### Configuration architecture

The configuration uses Den aspects to compose reusable system and user configurations.

- **flake-parts:** organizes flake outputs.
- **import-tree:** automatically imports the module tree.
- **Den:** composes hosts, users, and reusable aspects.
- **Home Manager:** manages user-level configuration.
- **Disko:** declaratively partitions and mounts disks.
- **Impermanence:** preserves selected state while allowing the root filesystem to be wiped.
- **SOPS-Nix:** decrypts encrypted secrets during system activation or user service startup.

### Filesystem model

The root filesystem is intentionally ephemeral.

| Mount      | Purpose                                   | Persistence      |
| ---------- | ----------------------------------------- | ---------------- |
| `/`        | System root                               | Wiped every boot |
| `/boot`    | EFI system partition                      | Persistent       |
| `/nix`     | Nix store and profiles                    | Persistent       |
| `/persist` | Explicitly preserved system and user data | Persistent       |
| `/var/log` | System logs                               | Persistent       |

The exact Btrfs subvolume layout is defined by Disko in the host configuration.

### Impermanence

The system is designed around the principle that **only explicitly preserved data survives reboot**.

Important persistent paths include:

- SSH host identity.
- User home directories.
- SOPS age identity.
- User SSH keys.
- Required system state.

If a new application needs persistent state, its directories must be added to the appropriate Impermanence configuration.

---

## 2. Secrets and keys

There are two recovery keys that form the roots of trust.

They are never stored in SOPS and must be backed up independently.

### Root keys

| Key                  | Location                                          | In SOPS | Backup    |
| -------------------- | ------------------------------------------------- | ------- | --------- |
| Host SSH private key | `/persist/etc/ssh/ssh_host_ed25519_key`           | No      | Mandatory |
| Admin age identity   | `/persist/home/mohamed/.config/sops/age/keys.txt` | No      | Mandatory |

These keys allow recovery of the encrypted repository.

### User keys

| User      | SSH private key                           | Age identity                           |
| --------- | ----------------------------------------- | -------------------------------------- |
| `mohamed` | Encrypted in `secrets/users/mohamed.yaml` | Admin age identity                     |
| `koko`    | Encrypted in `secrets/users/koko.yaml`    | Encrypted in `secrets/users/koko.yaml` |
| `kids`    | Encrypted in `secrets/users/kids.yaml`    | Encrypted in `secrets/users/kids.yaml` |

Each user has a separate SSH key and, except for Mohamed, a separate age identity.

User private keys are deployed from SOPS into persistent home directories.

### Other secrets

The following values are encrypted in the repository:

- Password hashes.
- SSH private keys.
- User age identities.
- Email addresses.
- API tokens.

### Secret decryption flow

```text
                       ROOT OF TRUST

Host SSH private key ── ssh-to-age ──┐
                                    │
Admin age identity ─────────────────┤
                                    ▼
                            SOPS encrypted files
                                    │
                   ┌────────────────┴─────────────────┐
                   ▼                                  ▼
              NixOS SOPS                       User SOPS
                   │                                  │
       Password hashes + user keys          Email + GitHub token
                   │                                  │
                   ▼                                  ▼
           Persistent homes                    User runtime secrets
```

The host SSH private key is converted to an age identity by SOPS-Nix.

The admin age identity is used to edit secrets outside the installed machine.

### SOPS recipient policy

See `.sops.yaml`.

| File                         | Authorized recipients           |
| ---------------------------- | ------------------------------- |
| `secrets/hosts/crazy.yaml`   | Admin, host                     |
| `secrets/users/mohamed.yaml` | Admin, host, Mohamed SSH        |
| `secrets/users/koko.yaml`    | Admin, host, Koko age, Koko SSH |
| `secrets/users/kids.yaml`    | Admin, host, Kids age, Kids SSH |

Every user has an independent rule.

**Never combine user rules into a single shared rule.** Each user file contains that user's private keys, and one user must not be able to decrypt another user's file.

### Recovery scenarios

| Lost key       | Consequence                                                                                  |
| -------------- | -------------------------------------------------------------------------------------------- |
| Host key       | Admin age key can decrypt and re-encrypt the repository                                      |
| Admin age key  | Host can decrypt on the installed machine; external secret editing is lost                   |
| User SSH key   | Admin or host can recover the encrypted copy and provision a replacement                     |
| User age key   | Admin or host can recover the encrypted copy and provision a replacement                     |
| Both root keys | Existing encrypted files become unrecoverable unless another recipient identity is available |

The last case requires recreating the secrets and identities from scratch.

---

## 3. Repository structure

The repository is organized around Den and import-tree.

The exact module tree may contain additional aspects.

The host-specific configuration is `modules/hosts/crazy.nix`.

The hardware configuration is intentionally named `_hardware-configuration.nix` so it can be imported explicitly without being treated as a standalone aspect by import-tree.

---

## 4. Requirements

Before installing, prepare:

- A UEFI-compatible NixOS installer USB.
- Network connectivity.
- This Git repository.
- A backup of both root keys if restoring an existing installation.
- A separate backup location for newly generated keys.
- Basic familiarity with Linux shell commands.

### Target disk

The Disko configuration currently targets:

```nix
disk.device = "/dev/sda";
```

**This disk will be destroyed.**

Always verify the actual device before running Disko:

```bash
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS
```

If the hardware changes, update the Disko device and regenerate the hardware configuration.

---

## 5. Installation

### 5.1 Boot the installer

Boot the NixOS installer in UEFI mode.

Switch to root:

```bash
sudo -i
```

Enable flakes:

```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
```

### 5.2 Clone the repository

```bash
nix shell nixpkgs#git -c git clone https://github.com/elkebirmed/nixconfig nixconfig
cd nixconfig
```

### 5.3 Partition and mount

**Warning: this operation destroys the configured target disk.**

```bash
nix run github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  --flake .#crazy
```

Verify mounts:

```bash
findmnt -R /mnt
```

Expected mountpoints include:

```text
/mnt
/mnt/boot
/mnt/nix
/mnt/persist
/mnt/var/log
```

Confirm the actual filesystem layout against the host's Disko configuration.

### 5.4 Enter the installation environment

Install the tools required for secret provisioning:

```bash
nix develop
```

The commands in the following sections assume these tools are available.

---

## 6. Key recovery and provisioning

Choose one of two paths.

```text
Do you have a backup of BOTH root keys?

├── Yes → Path A: restore existing keys
│
└── No  → Path B: generate new keys
```

### Path A — Restore existing keys

This is the preferred path when reinstalling the same machine.

#### A1. Restore the host SSH key

```bash
install -d -m 0755 /mnt/persist/etc/ssh

install -m 0600 \
  /path/to/backup/ssh_host_ed25519_key \
  /mnt/persist/etc/ssh/ssh_host_ed25519_key

install -m 0644 \
  /path/to/backup/ssh_host_ed25519_key.pub \
  /mnt/persist/etc/ssh/ssh_host_ed25519_key.pub
```

#### A2. Restore the admin age identity

```bash
install -d -m 0700 \
  /mnt/persist/home/mohamed/.config/sops/age

install -m 0600 \
  /path/to/backup/keys.txt \
  /mnt/persist/home/mohamed/.config/sops/age/keys.txt
```

#### A3. Verify the keys

```bash
ssh-to-age < \
  /mnt/persist/etc/ssh/ssh_host_ed25519_key.pub
```

The result must match `&host_crazy` in `.sops.yaml`.

```bash
age-keygen -y \
  /mnt/persist/home/mohamed/.config/sops/age/keys.txt
```

The result must match `&admin_mohamed` in `.sops.yaml`.

**Do not continue if either key does not match.**

Nothing in the repository needs editing.

Continue at [7. Install NixOS](#7-install-nixos).

---

### Path B — Generate new keys

Use this path when the original root keys are unavailable or intentionally being rotated.

#### B1. Generate a new host SSH key

```bash
install -d -m 0755 /mnt/persist/etc/ssh

ssh-keygen -t ed25519 \
  -N "" \
  -C crazy \
  -f /mnt/persist/etc/ssh/ssh_host_ed25519_key
```

Get the age recipient:

```bash
ssh-to-age < \
  /mnt/persist/etc/ssh/ssh_host_ed25519_key.pub
```

Replace `&host_crazy` in `.sops.yaml` with the new recipient.

#### B2. Generate a new admin age identity

```bash
install -d -m 0700 \
  /mnt/persist/home/mohamed/.config/sops/age

age-keygen -o \
  /mnt/persist/home/mohamed/.config/sops/age/keys.txt
```

Get its public recipient:

```bash
age-keygen -y \
  /mnt/persist/home/mohamed/.config/sops/age/keys.txt
```

Replace `&admin_mohamed` in `.sops.yaml`.

**Back up both root keys immediately.**

Do not proceed until the backup is safely stored outside the machine.

#### B3. Generate per-user keys

Run this from the repository root.

For `koko` and `kids`:

```bash
for u in koko kids; do
  age-keygen -o "$u-age.txt" 2>/dev/null

  ssh-keygen -q -t ed25519 \
    -N "" \
    -C "$u@crazy" \
    -f "$u-ssh"

  echo "age_$u: $(age-keygen -y "$u-age.txt")"
  echo "ssh_$u: $(ssh-to-age < "$u-ssh.pub")"
done
```

Mohamed needs an SSH key but uses the admin age identity:

```bash
ssh-keygen -q -t ed25519 \
  -N "" \
  -C "mohamed@crazy" \
  -f mohamed-ssh

echo "ssh_mohamed: $(ssh-to-age < mohamed-ssh.pub)"
```

Record the generated recipients securely.

If an existing user key is being kept, do not regenerate it.

#### B4. Update `.sops.yaml`

Replace the following recipients:

```yaml
&admin_mohamed
&host_crazy
&ssh_mohamed
&age_koko
&ssh_koko
&age_kids
&ssh_kids
```

Leave the `creation_rules` unchanged.

Verify the YAML before proceeding:

```bash
cat .sops.yaml
```

#### B5. Configure the admin age identity

```bash
export SOPS_AGE_KEY_FILE=\
/mnt/persist/home/mohamed/.config/sops/age/keys.txt
```

#### B6. Create or re-encrypt secret files

There are two possibilities.

##### B6a. Existing secrets are still decryptable

If the old admin key or old host key is available, reuse the existing secrets.

With the old admin identity:

```bash
export SOPS_AGE_KEY_FILE=/path/to/OLD/keys.txt
```

Alternatively, with the old host private key:

```bash
export SOPS_AGE_KEY=$(
  ssh-to-age -private-key \
    -i /path/to/old/ssh_host_ed25519_key
)
```

Update recipients:

```bash
for f in secrets/hosts/crazy.yaml secrets/users/*.yaml; do
  sops updatekeys -y "$f"
done
```

Replace any user private keys that were regenerated.

Continue at B7.

##### B6b. No existing secrets are decryptable

Create fresh encrypted files.

Remove the old files:

```bash
rm -f secrets/hosts/crazy.yaml
rm -f secrets/users/*.yaml
```

Initialize the host secret:

```bash
mkdir -p secrets/hosts

printf 'initialized: true\n' \
  > secrets/hosts/crazy.yaml

sops encrypt -i secrets/hosts/crazy.yaml
```

Create the user secret files:

```bash
mkdir -p secrets/users
```

Helper for preserving the exact private-key contents as JSON strings:

```bash
jqs() {
  jq -Rs . < "$1"
}
```

Create password hashes:

```bash
for u in mohamed koko kids; do
  HASH=$(mkpasswd -m yescrypt)

  printf 'passwords:\n  %s: "%s"\n' \
    "$u" "$HASH" > "secrets/users/$u.yaml"

  sops encrypt -i "secrets/users/$u.yaml"

  sops set "secrets/users/$u.yaml" \
    "[\"email\"][\"$u\"]" \
    "\"you@example.com\""

  sops set "secrets/users/$u.yaml" \
    "[\"ssh\"][\"$u\"]" \
    "$(jqs "$u-ssh")"
done
```

Replace each placeholder email with the real address.

Store the age identities for `koko` and `kids`:

```bash
for u in koko kids; do
  sops set "secrets/users/$u.yaml" \
    "[\"age\"][\"$u\"]" \
    "$(jqs "$u-age.txt")"
done
```

Mohamed's GitHub token:

```bash
sops set secrets/users/mohamed.yaml \
  '["github"]["mohamed"]' \
  '"ghp_xxx"'
```

Replace the token with the actual token.

The secret names must match the names used by the Nix configuration:

```text
passwords/<user>
email/<user>
ssh/<user>
age/<user>
github/<user>
```

#### B7. Verify and clean up

Verify that the new host key can decrypt every password hash:

```bash
export SOPS_AGE_KEY=$(
  ssh-to-age -private-key \
    -i /mnt/persist/etc/ssh/ssh_host_ed25519_key
)

for u in mohamed koko kids; do
  sops decrypt \
    --extract "[\"passwords\"][\"$u\"]" \
    "secrets/users/$u.yaml" >/dev/null \
    && echo "$u: OK"
done

unset SOPS_AGE_KEY
```

All three users must succeed.

Remove temporary plaintext private keys after verifying that their encrypted copies exist and your backups are safe:

```bash
shred -u \
  koko-age.txt kids-age.txt \
  koko-ssh kids-ssh mohamed-ssh \
  *.pub 2>/dev/null
```

`shred` is not guaranteed to securely erase data on SSDs, copy-on-write filesystems, or journaled filesystems. Avoid storing temporary private keys on persistent or shared storage in the first place.

Check Git:

```bash
git status
```

Confirm no private keys or plaintext secrets are staged.

Commit the encrypted changes:

```bash
git add .sops.yaml secrets
git commit -m "Rotate keys and initialize secrets"
```

Continue at [7. Install NixOS](#7-install-nixos).

---

## 7. Install NixOS

### 7.1 Hardware configuration

If installing on different hardware, regenerate the hardware configuration:

```bash
nixos-generate-config \
  --no-filesystems \
  --show-hardware-config \
  > modules/hosts/_hardware-configuration.nix
```

Stage it:

```bash
git add modules/hosts/_hardware-configuration.nix
```

This is important because flakes ignore untracked files.

### 7.2 Final safety check

Verify that the host key can decrypt Mohamed's password hash:

```bash
SOPS_AGE_KEY=$(
  ssh-to-age -private-key \
    -i /mnt/persist/etc/ssh/ssh_host_ed25519_key
) sops decrypt \
  --extract '["passwords"]["mohamed"]' \
  secrets/users/mohamed.yaml
```

The result must be a valid password hash, typically beginning with `$y$` for yescrypt.

If this fails, **stop**. Do not install.

### 7.3 Install

```bash
nixos-install --flake .#crazy --no-root-password
```

Keep a copy of the repository on persistent storage:

```bash
mkdir -p /mnt/persist/home/mohamed/Projects

cp -a /root/nixconfig \
  /mnt/persist/home/mohamed/Projects/nixconfig
```

Reboot:

```bash
reboot
```

---

## 8. First boot

Log in as `mohamed` using the password created in the SOPS file.

### 8.1 Fix persistent home ownership

Directories created during activation may initially be owned by root.

Inspect:

```bash
ls -ld \
  /persist/home/*/.config \
  /persist/home/*/.ssh \
  /persist/home/*/.config/sops/age
```

If required:

```bash
for u in mohamed koko kids; do
  sudo chown -R "$u": "/persist/home/$u"
done
```

### 8.2 Verify key provisioning

```bash
ls -l \
  ~/.ssh/id_ed25519 \
  ~/.config/sops/age/keys.txt
```

Mohamed should have:

- SSH private key.
- Admin age identity.

Other users should receive their own configured keys.

### 8.3 Verify Home Manager secrets

```bash
systemctl --user status sops-nix
```

If the service started before ownership was corrected:

```bash
systemctl --user restart sops-nix
```

Verify email:

```bash
git config user.email
```

Verify GitHub authentication:

```bash
gh auth status
```

The GitHub token is configured for Mohamed only.

---

## 9. Backup and recovery

### Mandatory backups

Back up these files:

```text
/persist/etc/ssh/ssh_host_ed25519_key
/persist/etc/ssh/ssh_host_ed25519_key.pub

/persist/home/mohamed/.config/sops/age/keys.txt
```

Recommended backup locations:

- Password manager attachment.
- Encrypted USB.
- Offline encrypted storage.
- Two geographically separate copies.

Never store the only backup on the machine itself.

### Test the backup

Restore the backup copies into a temporary directory and verify their public recipients:

```bash
ssh-to-age < ssh_host_ed25519_key.pub

age-keygen -y keys.txt
```

Compare them with `.sops.yaml`.

A backup that has never been tested is not a reliable backup.

### Recovery after disk failure

1. Obtain the repository.
2. Restore the host SSH private key.
3. Restore the admin age identity.
4. Verify both public recipients.
5. Partition and mount the new disk.
6. Follow Path A.
7. Install NixOS.
8. Verify all user keys and secrets.
9. Reboot and test.

### Recovery after losing both root keys

If both root keys are lost and no other authorized identity can decrypt the files:

1. Generate new root keys.
2. Generate replacement user keys.
3. Update `.sops.yaml`.
4. Recreate the host and user secrets.
5. Recreate password hashes and tokens.
6. Verify encryption and host decryption.
7. Install using Path B.

---

## 10. Day-to-day operations

### Rebuild the system

From the repository:

```bash
nixos-rebuild switch --flake .#crazy
```

### Edit a secret

```bash
sops secrets/users/mohamed.yaml
```

This uses the admin age identity.

### Update recipients

After changing `.sops.yaml`:

```bash
sops updatekeys secrets/hosts/crazy.yaml

for f in secrets/users/*.yaml; do
  sops updatekeys "$f"
done
```

Always verify that the intended recipients can decrypt the updated files.

### Validate the flake

```bash
nix flake check
```

This is the same validation used by CI.

### Format the repository

Use the formatter configured by the flake.

### Update inputs

```bash
nix flake update
```

Review changes carefully before rebuilding.

---

## 11. Adding users

To add a user:

1. Create the user aspect.
2. Include `den.aspects.user-ssh-key`.
3. Include `den.aspects.user-age-key` if the user needs an age identity.
4. Include `den.aspects.sops-home`.
5. Generate the user's SSH key and optional age identity.
6. Add the recipient anchors to `.sops.yaml`.
7. Add a dedicated creation rule for `secrets/users/<user>.yaml`.
8. Create the encrypted user file.
9. Add the password hash and required key entries.
10. Verify the file can be decrypted by the host.
11. Rebuild the system.
12. Verify ownership and Home Manager activation.

Never authorize one user's key to decrypt another user's private-key file.

---

## 12. Rotating keys

### Rotate a user SSH key

1. Generate a new SSH key.
2. Update its age recipient in `.sops.yaml`.
3. Replace the encrypted private key in the user's SOPS file.
4. Run `sops updatekeys` on that user's file.
5. Verify host decryption.
6. Rebuild the system.
7. Verify the deployed SSH key.

### Rotate a user age identity

1. Generate a new age identity.
2. Update its public recipient in `.sops.yaml`.
3. Replace the encrypted age identity in the user's SOPS file.
4. Run `sops updatekeys`.
5. Verify host decryption.
6. Rebuild the system.
7. Verify ownership and user SOPS activation.

### Rotate a root key

Root-key rotation requires updating the recipient policy and re-encrypting all affected secrets.

Do not remove the old recipient until the new key has been tested and every relevant encrypted file has been updated.

Keep the old root key until the new installation and backups have been verified.

---

## 13. Troubleshooting

| Symptom                                            | Cause                                                           | Resolution                                              |
| -------------------------------------------------- | --------------------------------------------------------------- | ------------------------------------------------------- |
| `attribute 'sops' missing`                         | User aspect does not include `den.aspects.sops-home`            | Include the SOPS Home Manager aspect                    |
| Activation: `secret ssh/<user> not found`          | Missing SSH key entry                                           | Add the key to the user's YAML                          |
| Activation: `secret age/<user> not found`          | Missing age identity entry                                      | Add the identity to the user's YAML                     |
| Cannot log in after installation                   | Host recipient mismatch or invalid password hash                | Verify host key and password hash                       |
| `sops-nix` fails with `failed to get the data key` | Missing identity, unreadable key, or stale recipients           | Check ownership and run `sops updatekeys`               |
| `~/.config` owned by root                          | Directory created before the user existed                       | Run the ownership correction                            |
| `nix flake check` cannot see a file                | File is untracked                                               | `git add` the file                                      |
| User SOPS service fails                            | Wrong ownership or missing age identity                         | Correct ownership and verify the age key                |
| Rebuild asks to build many packages                | Cache unavailable, unsupported platform, or missing substituter | Check cache configuration, trusted keys, and build logs |
| Disko targets the wrong device                     | Incorrect `disk.device`                                         | Stop immediately and correct the host configuration     |

Useful diagnostics:

```bash
lsblk -f
findmnt -R /
systemctl status sops-nix
journalctl -b -u sops-nix
journalctl -b
nix flake check
```

---

## 14. Security checklist

Before committing:

- [ ] No private SSH keys are tracked.
- [ ] No plaintext age identities are tracked.
- [ ] No plaintext passwords or tokens are tracked.
- [ ] `.gitignore` excludes temporary provisioning files.
- [ ] Every SOPS file is encrypted.
- [ ] Every user has an independent SOPS rule.
- [ ] Root keys are backed up offline.
- [ ] Backups have been tested.
- [ ] Host key decrypts every required user secret.
- [ ] `.sops.yaml` contains only public age recipients.
- [ ] Git history has been checked for accidental key exposure.

Before installation:

- [ ] Target disk has been verified.
- [ ] Disko configuration points to the correct device.
- [ ] Existing root keys have been restored or new keys generated.
- [ ] Root keys match `.sops.yaml`.
- [ ] Mohamed's password hash decrypts.
- [ ] Hardware configuration is correct.
- [ ] Required files are staged in Git.

After installation:

- [ ] Mohamed can log in.
- [ ] Persistent home ownership is correct.
- [ ] User SSH keys are deployed.
- [ ] Age identities are deployed.
- [ ] User SOPS services work.
- [ ] Git email is configured.
- [ ] GitHub authentication works.
- [ ] Root-key backups are stored offline.

---

## License

This configuration is personal infrastructure. Use it as a reference, but review the Disko, Impermanence, and SOPS settings carefully before adapting it to another machine.
