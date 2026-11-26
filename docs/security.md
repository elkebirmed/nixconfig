# Security and secrets

The two root keys, the SOPS recipient policy, backups, adding users, and rotation.

Part of the [nixconfig](../README.md) documentation.

---

## Secrets and keys

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

## Backup and recovery

Back up (offline, two separate locations, e.g. password manager or encrypted USB):

```text
/persist/etc/ssh/ssh_host_ed25519_key
/persist/etc/ssh/ssh_host_ed25519_key.pub
/persist/home/mohamed/.config/sops/age/keys.txt
```

Never keep the only copy on the machine. Test backups by restoring to a temp directory and comparing `ssh-to-age < ssh_host_ed25519_key.pub` and `age-keygen -y keys.txt` with `.sops.yaml`.

**Disk failure:** obtain the repo, restore both root keys, verify recipients, partition/mount the new disk, follow Path A, install, verify, reboot.

**Both root keys lost:** generate new root and user keys, update `.sops.yaml`, recreate all secrets, verify, and install via Path B.

## Adding users

1. Create the user aspect including `den.aspects.user-ssh-key`, `den.aspects.sops-home`, and `den.aspects.user-age-key` (if an age identity is needed).
2. Generate the SSH key and optional age identity.
3. Add recipient anchors and a dedicated creation rule for `secrets/users/<user>.yaml` in `.sops.yaml`.
4. Create the encrypted file with the password hash and key entries; verify host decryption.
5. Rebuild, then verify ownership and Home Manager activation.

Never authorize one user's key to decrypt another user's file.

## Rotating keys

**User SSH key / age identity:** generate a new key, update its recipient in `.sops.yaml`, replace the encrypted private key in the user's file, run `sops updatekeys`, verify host decryption, rebuild, and verify deployment.

**Root key:** update the recipient policy and re-encrypt all affected files. Keep the old key until the new one and its backups are verified.
