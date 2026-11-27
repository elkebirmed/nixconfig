# Web resources

Every external host this configuration talks to, grouped by why it is there.
"External" means reachable off the machine: flake inputs, binary caches, API
endpoints, ACME, and the served hostnames. Ports that only bind to loopback are
listed separately at the end because they never leave the box.

Three rules this document follows:

- **Nothing here is a secret.** Hostnames, repository URLs, and ports are public.
  Tokens, keys, and record values are not listed and never should be — see
  [`docs/security.md`](security.md).
- **Direct versus transitive is stated.** A repo pulled in by another flake is
  not something you chose directly, and pinning it yourself would be wrong.
- **The `github:` shorthand resolves to HTTPS.** `github:owner/repo` means
  `https://github.com/owner/repo`, so no separate HTTPS row is needed.

---

## 1. Flake inputs (direct)

Declared in `flake.nix`, 21 in total. Each is pinned in `flake.lock`.

### Core plumbing

| Input         | URL                              | Role                         |
| ------------- | -------------------------------- | ---------------------------- |
| `nixpkgs`     | nixpkgs-unstable channel tarball | Package set for both hosts   |
| `flake-parts` | `github:hercules-ci/flake-parts` | Flake output organization    |
| `flake-file`  | `github:vic/flake-file`          | Generates `flake.nix`        |
| `import-tree` | `github:denful/import-tree`      | Auto-imports the module tree |
| `den`         | `github:denful/den`              | Aspect/module framework      |
| `treefmt-nix` | `github:numtide/treefmt-nix`     | `nix fmt` wiring             |

### System integration

| Input                | URL                                       | Role                            |
| -------------------- | ----------------------------------------- | ------------------------------- |
| `home-manager`       | `github:nix-community/home-manager`       | User-level configuration        |
| `sops-nix`           | `github:Mic92/sops-nix`                   | Secret decryption at boot       |
| `disko`              | `github:nix-community/disko`              | Declarative partitioning        |
| `impermanence`       | `github:nix-community/impermanence`       | Ephemeral root, persisted state |
| `nix-index-database` | `github:nix-community/nix-index-database` | Prebuilt index for `comma`      |
| `quadlet-nix`        | `github:mirkolenz/quadlet-nix`            | Podman Quadlet units            |

### Desktop

| Input                        | URL                                     | Role                        |
| ---------------------------- | --------------------------------------- | --------------------------- |
| `niri`                       | `github:epireyn/niri-flake`             | Niri session and HM modules |
| `noctalia`                   | `github:noctalia-dev/noctalia/cachix`   | Desktop shell               |
| `noctalia-greeter`           | `github:noctalia-dev/noctalia-greeter`  | Login greeter               |
| `noctalia-plugins`           | `github:noctalia-dev/official-plugins`  | Shell plugins               |
| `noctalia-community-plugins` | `github:noctalia-dev/community-plugins` | Extra shell plugins         |
| `zen-browser`                | `github:0xc000022070/zen-browser-flake` | Browser                     |

### Editor and AI

| Input          | URL                             | Role                      |
| -------------- | ------------------------------- | ------------------------- |
| `nvf`          | `github:NotAShelf/nvf`          | Neovim distribution       |
| `nix-openclaw` | `github:openclaw/nix-openclaw`  | OpenClaw gateway module   |
| `llm-agents`   | `github:numtide/llm-agents.nix` | Packaged Command Code CLI |

`nixpkgs` is a tarball URL, not a GitHub ref:
`https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst`.

## 2. Transitive inputs

Pulled in by the above at the versions the parent pins. Not chosen directly;
do not add these to `flake.nix`.

| Repository                           | Arrives via           |
| ------------------------------------ | --------------------- |
| `github:Mic92/bun2nix`               | `llm-agents`          |
| `github:Gerg-L/mnw`                  | `nvf`                 |
| `github:openclaw/nix-openclaw-tools` | `nix-openclaw`        |
| `github:tobi/qmd`                    | `nix-openclaw`        |
| `github:numtide/flake-utils`         | `nix-openclaw`, `qmd` |
| `github:nix-systems/default`         | `qmd` and others      |
| `github:nix-community/nixpkgs.lib`   | `flake-parts`         |

Two edge cases worth stating rather than guessing at:

- `flake-compat` comes from `https://git.lix.systems/lix-project/flake-compat.git`
  via `nvf`. It is the one non-GitHub transitive input.
- `github:Supreeeme/xwayland-satellite` is locked but records no parent edge, so
  it arrives through a `follows` indirection. It is still not declared here.

## 3. Binary caches

| Cache                         | Scope   | Trust key                             |
| ----------------------------- | ------- | ------------------------------------- |
| `https://cache.nixos.org`     | both    | `cache.nixos.org-1:…` (NixOS default) |
| `https://noctalia.cachix.org` | desktop | `noctalia.cachix.org-1:pCOR47nn…`     |

`noctalia.cachix.org` is declared in both `flake.nix` (`nixConfig`) and
`modules/aspects/desktop/cache.nix`, so `--accept-flake-config` works before the
rebuilt system's settings are live.

**Deliberately absent:** `niri-epireyn.cachix.org`. niri is built from
`pkgs.niri` instead, so no third-party substituter is trusted just to get a
session module. The trade-off is that niri releases lag until nixpkgs bumps them.

## 4. AI and model providers

| Endpoint                                        | Used by                      |
| ----------------------------------------------- | ---------------------------- |
| `https://api.commandcode.ai/provider`           | Minuet, CodeCompanion (nvf)  |
| `https://api.commandcode.ai/provider/v1`        | OpenClaw, OpenCode           |
| `https://api.commandcode.ai/provider/v1/models` | Catalog; source of model IDs |

Defined once in `modules/aspects/ai/_commandcode-lib.nix` and imported by all
three consumers. Two forms exist because clients differ: the nvf adapters append
`/v1/chat/completions` themselves and need the bare root, while OpenClaw and
OpenCode expect the base with `/v1` included.

Schema/theme references (fetched by the tools, not by Nix):
`https://opencode.ai/config.json` and `https://opencode.ai/theme.json`.

## 5. Chat and messaging

| Endpoint                   | Used by               |
| -------------------------- | --------------------- |
| `https://api.telegram.org` | OpenClaw Telegram bot |

The only messaging channel configured. The bot token lives at
`/run/secrets/openclaw-telegram-token` and is never in the store.

## 6. Served hostnames (Caddy)

Inbound, not outbound. All four are served by Caddy on the VPS; the domain
itself is a SOPS placeholder (`{$WEB_DOMAIN}`), never a literal.

| Site             | Backend           | Access    |
| ---------------- | ----------------- | --------- |
| apex             | static example    | `public`  |
| `openclaw.<dom>` | `127.0.0.1:18789` | `tailnet` |
| `grafana.<dom>`  | `127.0.0.1:3000`  | `tailnet` |
| `metrics.<dom>`  | `127.0.0.1:9090`  | `tailnet` |

Unknown subdomains are aborted — see `docs/vps.md` → "Served hostnames".

## 7. TLS and DNS automation

| Service                                 | Role                                                  |
| --------------------------------------- | ----------------------------------------------------- |
| Let's Encrypt (Caddy's default ACME CA) | Certificates via DNS-01                               |
| Cloudflare DNS API                      | ACME DNS-01 challenge (`caddy-dns/cloudflare` v0.2.4) |
| `registry.opentofu.org`                 | `cloudflare/cloudflare` provider, `4.52.10`           |

Cloudflare is the DNS provider for the zone and the ACME challenge target. The
challenge endpoint is not written out in source — it is the provider's built-in
default, reached through the socket the Caddy plugin opens. The plugin itself is
pinned by module version and hash in `modules/aspects/server/web.nix`. Two
separate tokens are used: one for Caddy's challenge, one for `infra/dns/` —
rotating either does not touch the other.

## 8. CI (GitHub Actions)

`.github/workflows/test.yml`, all pinned to commit SHAs:

| Action                                          | Purpose                |
| ----------------------------------------------- | ---------------------- |
| `actions/checkout` v7.0.1                       | Checkout               |
| `DeterminateSystems/nix-installer-action` v23   | Nix on the runner      |
| `DeterminateSystems/magic-nix-cache-action` v15 | Build cache            |
| `DeterminateSystems/update-flake-lock` v29      | Weekly `flake.lock` PR |

Runs on `ubuntu-latest`, weekly Monday 04:00 UTC plus every push and PR.

## 9. Container images

No image is hardcoded. `private-app.nix` requires each app's image reference to
come from a SOPS secret (`secretName`), so no registry path or digest is ever a
Nix literal. No apps are defined today, so there are no live registry pulls.

## 10. Loopback only

These never leave the machine and are unreachable from anywhere else:

| Port  | Service          | Bound to    |
| ----- | ---------------- | ----------- |
| 18789 | OpenClaw gateway | `127.0.0.1` |
| 3000  | Grafana          | `127.0.0.1` |
| 9090  | Prometheus       | `127.0.0.1` |
| 9100  | node_exporter    | `127.0.0.1` |

Caddy is the only public entry point, on 443/TCP and 443/UDP (HTTP/3).

## 11. Not configured

Useful to know what is absent, because absence is a decision here:

- **No web search provider.** OpenClaw has no `tools.web`; the assistant fetches
  only URLs it is given.
- **No telemetry.** Nothing sends analytics or crash reports outbound, and this
  is enforced rather than merely absent: Grafana is configured with
  `analytics.reporting_enabled = false` and `check_for_updates = false` in
  `modules/aspects/server/monitoring.nix`.
- **No third-party DNS resolvers.** No `nameservers` or `dns` override exists in
  any module, so systemd-resolved defaults are used.
- **No external object storage.** Backups go through `restic`, whose repository
  is a SOPS secret — the destination is deliberately not in this file.
