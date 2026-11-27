# Deploying

How a change gets from this repository onto a running machine, and what has to be
true before it does.

There is **no automatic deploy**. No `system.autoUpgrade`, no CI deploy job, no
timer that rebuilds on merge. Merging is not shipping — someone runs a command.
That is deliberate: the machines are the only place the real secrets are, and an
unattended rebuild that pulls `main` would make every merge a root change on the
host.

---

## 1. The model

Two hosts, one flake, and a hard direction of travel:

```text
commit ──▶ CI (builds both toplevels) ──▶ merge to main ──▶ you run rebuild
```

CI proves the closure builds. It never touches a machine. A green check means
"this evaluates and builds", not "this is deployed".

| Host    | Purpose | Reachable over SSH |
| ------- | ------- | ------------------ |
| `vps`   | server  | `tailscale0` only  |
| `crazy` | desktop | `enp9s0`, `wlp8s0` |

Public SSH is closed on `vps`. Port 22 exists on the tailnet interface and
nowhere else, so a rebuild from outside the tailnet cannot work — that is the
intended posture, not an obstacle to route around.

## 2. Before you deploy

Three checks, in order. Each one catches a different class of mistake.

```bash
git log --oneline -1            # what you think you are deploying
nix flake check                 # does everything evaluate
nix run .#vps                   # build the closure via nh, no switch
```

`nix run .#vps` builds without activating. It is the cheapest place to find a
broken module, and it leaves the running system alone. For the desktop host use
`nix run .#crazy`.

These wrappers bundle their own `nh`, so they work even on a machine where `nh`
is not installed. `programs.nh` is set only by the `nix-daemon` aspect, which
`crazy` includes; `vps` uses `server-nix` instead and has no `nh` on PATH. That
is why the build step here is `nix run .#vps` and not `nh os build`.

If the change touches only a home-manager user, `nh home switch` on `crazy` is
enough and skips the system rebuild. `vps` has no `nh`, so `home-manager` is the
fallback there.

## 3. Deploying the VPS

From a machine on the tailnet with the repo checked out:

```bash
sudo nixos-rebuild switch \
  --flake .#vps \
  --target-host ops@VPS_SSH_ALIAS \
  --build-host ops@VPS_SSH_ALIAS \
  --elevate=sudo
```

Or straight from the remote repository, which is what you want when the local
checkout is behind:

```bash
sudo nixos-rebuild switch \
  --flake github:elkebirmed/nixconfig#vps \
  --target-host ops@VPS_SSH_ALIAS \
  --build-host ops@VPS_SSH_ALIAS \
  --elevate=sudo
```

**`--build-host` is not optional on a small box.** Without it the closure is
built locally and copied over. With it, the target builds its own system using
its own memory and its own store — which matters when the caller is a container
or a laptop, and it avoids re-downloading everything the target already has.

`VPS_SSH_ALIAS` is your own SSH config alias for the host's tailnet address. The
address itself is an infrastructure identifier and is not in this repository.

### Why `switch` does not drop your session

`systemd.services.tailscaled.restartIfChanged = false` in
`modules/aspects/server/tailscale.nix`. A switch that bounced the tunnel would
kill the SSH session carrying it, and every tailnet-only service with it.

### Kernel and initrd

`switch` cannot apply those to a running kernel. When the change touches boot,
kernel, initrd, or hardware:

```bash
sudo nixos-rebuild boot --flake .#vps --target-host ... --build-host ...
sudo reboot
```

Choose the moment; do not let a switch decide it for you.

## 4. Deploying the desktop

`crazy` has an impermanent root: `/` is wiped on boot and only persisted paths
survive. So the rebuild and the reboot are a pair — a switch that writes outside
`/persist` is undone at the next boot.

```bash
sudo nixos-rebuild switch --flake .#crazy
```

Test a desktop change without touching the real system:

```bash
nix run .#vm
```

That boots the evaluated `crazy` configuration in a VM. It is the right first
move for anything involving the compositor, the display manager, or a session
change, because a broken session on a headless-adjacent machine is expensive to
fix.

## 5. Rollback

Every rebuild creates a generation. Rollback is picking an earlier one.

| Situation                | Command                                                      |
| ------------------------ | ------------------------------------------------------------ |
| System is up             | `sudo nixos-rebuild switch --rollback`                       |
| System will not boot     | Pick the previous generation in the boot menu                |
| Only your user broke     | `home-manager generations`, then activate one                |
| You need to see the diff | `nix profile diff-closures /run/current-system /nix/store/…` |

The last one uses a stock Nix command on purpose: `nvd diff` is the nicer form,
but `nvd` is not installed on either host — `nh` mentions it in a comment in
`modules/aspects/system/nix-daemon.nix` without providing it.
`nix profile diff-closures` gives the same generation-to-generation view without
adding a package.

Garbage collection differs per host, and the two settings are not interchangeable.

`crazy` runs `programs.nh.clean` weekly, keeping 5 generations or 7 days of them
(`--keep 5 --keep-since 7d`). That aspect sets `programs.nh` itself, so on `vps`
there is no `nh` and no `nh clean` — the reason `nix run .#vps` bundles its own.

`vps` uses `nix.gc` instead: weekly, `--delete-older-than 14d`. The `nix-daemon`
aspect declines to add `nix.gc` on `crazy` precisely because `nh clean` would
duplicate the timer.

Either way a rollback target older than the window is gone. On `vps` that window
is 14 days; on `crazy` it is effectively the newest 5 generations.

## 6. What a deploy does not cover

- **DNS records.** `infra/dns/` is applied separately with OpenTofu, on purpose.
  A site whose record does not exist yet will build and start and then be
  unreachable. Create the record first — see
  [`infra/dns/README.md`](../infra/dns/README.md).
- **Secrets.** SOPS files are in the repository, but the age keys are not. A
  deploy to a host without its key decrypts nothing. See
  [`docs/security.md`](security.md).
- **Container images.** `private-app` reads the image reference from a SOPS
  secret at runtime, so changing an image is a secret change, not a rebuild.
- **The bootloader config on a new disk.** First install is a different
  procedure — see [`docs/install.md`](install.md).

## 7. If it goes wrong

Order of operations, cheapest first:

1. **Read the error.** `nixos-rebuild` prints the failing unit and its journal.
2. **Roll back** with the command in section 5. Do not debug a broken system in
   place if a working generation is one command away.
3. **Reproduce locally** with `nix run .#vps` or `nix run .#vm`. Most failures
   are evaluation errors and reproduce without touching a host.
4. **Check what changed** with `nix profile diff-closures` between the two
   generations before assuming the cause is your change.

The gateway on `vps` runs as `claw` with `NoNewPrivs`, an empty
`CapabilityBoundingSet`, and `ProtectSystem=strict`. It cannot rebuild the host,
by design — a prompt-injected assistant reaching an exec path still cannot turn
itself into root. See [`docs/openclaw.md`](openclaw.md).
