# VPS host

Operating the server: trust boundaries, install, deploys, containers, monitoring,
backups, and recovery.

Part of the [nixconfig](../README.md) documentation. See also
[OpenClaw](openclaw.md) for the assistant running on this host and
[`infra/dns/README.md`](../infra/dns/README.md) for DNS.

---

## What this host is

`vps` is a single x86_64 virtual machine (4 vCPU, 8 GB RAM, 75 GB disk).
It boots in **BIOS/GRUB** mode from `/dev/sda` with a **GPT + ext4** layout
(`disko-bios`), and it is a QEMU/virtio guest. These facts come from the checked
in `disko-bios` and hardware configuration; do not assume UEFI or btrfs.

A single node provides no high availability. There is no cluster, no replication,
and no failover.

## Architecture and trust boundaries

```text
                     public 80/443 (+443/udp)
                              │
                        ┌─────▼─────┐
                        │   Caddy   │  only public ingress, TLS via DNS-01
                        └─────┬─────┘
             tailnet guard: not remote_ip 100.64.0.0/10 fd7a:...
                    ┌─────────┼─────────┐
               127.0.0.1:3000   :9090     :18789
                Grafana    Prometheus   OpenClaw
                                             │
                                             │ HTTPS (Bearer key from SOPS)
                                             ▼
                                  Command Code Provider API
                                        (external)

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

## Desktop vs server aspects

The desktop host `crazy` and the server host `vps` share only generic aspects
(user accounts, SOPS plumbing, firewall, locale). Server-only aspects
(`web`, `quadlet`, `monitoring`, `backups`, `private-app`, `network-vps`,
`openclaw`) are included from `modules/hosts/vps.nix` only. Adding a server
aspect to `crazy` is a bug, not a convenience.

## Served hostnames

Every site is an explicit `web.sites.<name>` entry. The `*.{$WEB_DOMAIN}` block
in the generated Caddyfile is a catch-all that ends in `abort` — unknown
subdomains get nothing, so a new site is never picked up implicitly.

| Site                     | Backend               | `access`  |
| ------------------------ | --------------------- | --------- |
| `{$WEB_DOMAIN}` (apex)   | static `example-site` | `public`  |
| `openclaw.{$WEB_DOMAIN}` | `127.0.0.1:18789`     | `tailnet` |
| `grafana.{$WEB_DOMAIN}`  | `127.0.0.1:3000`      | `tailnet` |
| `metrics.{$WEB_DOMAIN}`  | `127.0.0.1:9090`      | `tailnet` |

Sources: `modules/sites/example.nix` (apex), `modules/aspects/server/openclaw.nix`,
and `modules/aspects/server/monitoring.nix` (grafana, metrics). The `private-app`
aspect adds an `app-<name>` site per configured app; none are defined today.

Add a site by declaring `web.sites.<name>` in the aspect that owns the service,
not by relying on the wildcard.

## Network address handling

The static WAN IPv6 address and its gateway are infrastructure identifiers and
are **not** committed. `modules/aspects/server/network.nix` declares
`network.v6.{address,gateway}` with `REDACTED_IPV6*` placeholders.

This is a **documented exception** to the runtime-secret rule: systemd-networkd
needs the address at boot, before SOPS has decrypted anything, so it cannot be
rendered into `/run`. Set the real values locally (or from a private overlay) and
never commit them.

## First install (destructive — owner approval required)

> Do not run this from an automated agent. It erases the target disk.

```bash
 Requires etc/ssh/ssh_host_ed25519_key{,.pub} in an --extra-files tree,
 generated outside the repository and backed up separately.
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

## Deploying updates

```bash
 Build locally first — this is the same closure CI builds.
nix build .#nixosConfigurations.vps.config.system.build.toplevel --no-link

 Then switch over the tailnet. `restartIfChanged = false` on tailscaled keeps
 the tunnel (and this SSH session) up across the switch.
nixos-rebuild switch --flake .#vps \
  --target-host ops@VPS_SSH_ALIAS \
  --build-host ops@VPS_SSH_ALIAS \
  --elevate=sudo
```

Kernel and initrd changes are **not** applied by `switch`. Use
`nixos-rebuild boot` and reboot at a chosen time.

## Containers: Quadlet only

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

No container runs on the VPS today — do not add one just to have an example.
`den.aspects.private-app` (`modules/aspects/server/private-app.nix`) is the
declared container path and carries this hardening baseline.

## Private application images

A private image reference must never appear in the Nix store. Quadlet does **not**
expand environment variables in `Image=`, so the image cannot be injected through
an `EnvironmentFile`.

Instead, `modules/aspects/server/private-app.nix` uses Quadlet's runtime search
path. The image reference lives in SOPS; a oneshot renders the real unit into
`/run/containers/systemd/<name>.container` (which takes precedence over `/etc` and
`/usr/share`) and then runs `systemctl daemon-reload`.

```nix
 modules/hosts/vps.nix
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

## Monitoring

Proportionate for one node: node exporter + Prometheus + Grafana, all on
loopback and exposed only through tailnet-guarded Caddy routes
(`metrics`, `grafana`).

- Prometheus retains 14 days with a 2 GB cap (`MemoryMax=768M`).
- Grafana is capped at `MemoryMax=512M`; anonymous access and sign-up are off.
- No Loki and no alerting backend. Add them only when measurements justify it.

## Backups and restore

`modules/aspects/server/backups.nix` configures restic for application state.
Both the repository location and password are read at **runtime** from
SOPS-rendered files, so neither enters the store. The job is **disabled by
default** and stays inert until the required secrets exist.

Restore drill — run this on a schedule, not just once:

```bash
 1. List snapshots (as root; uses the same env as the timer).
systemctl start restic-backups-appdata.service
restic-appdata snapshots

 2. Restore into a scratch dir.
restic-appdata restore latest --target /var/tmp/restore-test

 3. Verify the important trees exist and are non-empty.
du -sh /var/tmp/restore-test/home/claw/.openclaw
du -sh /var/tmp/restore-test/var/lib/grafana

 4. Remove the scratch copy.
rm -rf /var/tmp/restore-test
```

A backup that has never been restore-tested is not a backup.

## What survives a reboot

`vps` uses a **persistent ext4 root**, unlike `crazy`, which uses Impermanence.
Everything under `/` survives. The `systemPersistence` entry in
`modules/aspects/server/tailscale.nix` therefore has no effect on this host — it
only matters on `crazy`. Each stateful service still declares its data directory
explicitly so ownership is correct on a fresh install:

| Service      | Path                   | Owner        |
| ------------ | ---------------------- | ------------ |
| OpenClaw     | `/home/claw/.openclaw` | `claw`       |
| Prometheus   | `/var/lib/prometheus`  | `prometheus` |
| Grafana      | `/var/lib/grafana`     | `grafana`    |
| Tailscale    | `/var/lib/tailscale`   | root         |
| private apps | `/var/lib/<app>`       | per app      |

## DNS as code

`infra/dns/` holds the Cloudflare configuration. Every private value (zone name,
records, addresses, token) is a variable with no committed default, and state
lives outside the repository. See `infra/dns/README.md`.

`tofu fmt -check` and `tofu validate` are safe. Never paste plan output anywhere
public, and never `apply` without owner approval.

### Which record list a name belongs in

A site's `access` decides its record list. There is no automatic link between
the two, so this is the one place where a mistake is possible:

| `web.sites.<name>.access` | Record list       | Proxy     |
| ------------------------- | ----------------- | --------- |
| `public`                  | `public_records`  | allowed   |
| `tailnet` (the default)   | `tailnet_records` | forbidden |

`tailnet_records` forces `proxied = false` in `infra/dns/main.tf`, so the
provider will not let you proxy one. The failure mode is the reverse: putting a
tailnet-only name in `public_records` with `proxied = true`.

That case produces **HTTP 520 from Cloudflare** and looks like a broken service,
but the service is fine. A proxied record terminates the connection at
Cloudflare, so Caddy sees a Cloudflare address instead of the tailnet one, and
the `remote_ip` guard aborts the request. The guard is working exactly as
intended; the record is what is wrong.

Diagnose it with one command against each name:

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://<name>.<domain>/
```

520 on a tailnet site means the record is proxied. Fix the record, not the
Caddyfile. Names reachable only over the tailnet gain nothing from public DNS,
so an alternative is to drop such records entirely and resolve them by IP.

## Rollback and recovery

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

## Owner actions

These secret **names** must exist in `secrets/hosts/vps.yaml` before the features
that use them are enabled. Do not paste values anywhere; add them with `sops`.

| Secret                    | Used by            | Notes                                                                 |
| ------------------------- | ------------------ | --------------------------------------------------------------------- |
| `web-domain`              | Caddy, Grafana     | Base domain (placeholder in source).                                  |
| `acme-email`              | Caddy              | ACME contact address.                                                 |
| `tailscale-auth-key`      | Tailscale          | Already present.                                                      |
| `cloudflare-api-token`    | Caddy DNS-01       | Separate from the OpenTofu token.                                     |
| `openclaw-gateway-token`  | OpenClaw           | Already present.                                                      |
| `openclaw-telegram-token` | OpenClaw           | Already present.                                                      |
| `grafana-admin-password`  | Grafana            |                                                                       |
| `grafana-secret-key`      | Grafana            | Random hex, e.g. `openssl rand -hex 32`.                              |
| `git-email`               | `ops` git identity | Host-scoped, not a user file.                                         |
| `restic-password`         | Backups            | Enables the backup job.                                               |
| `restic-repository`       | Backups            | Private destination.                                                  |
| `cmdc/api-key`            | Command Code       | Host-scoped, for OpenClaw; desktop keeps its own in `secrets/users/`. |
| `omniroute/*`             | —                  | Legacy, unused since OmniRoute was removed; safe to prune.            |

Manual steps:

1. Set the real IPv6 address/gateway in `modules/hosts/vps.nix` locally.
2. Create the `VPS_SSH_ALIAS` entry in your private `~/.ssh/config`.
3. Export `TF_VAR_*` for OpenTofu in a protected shell.
4. Rotate the historical items listed in the audit report if you decide the
   exposure matters.
