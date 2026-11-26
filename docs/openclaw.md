# OpenClaw

The assistant running on the VPS: its sandbox boundary, GitHub publishing, and
the Command Code model provider.

Part of the [nixconfig](../README.md) documentation. See also [VPS host](vps.md)
for the machine it runs on.

---

## Boundary

OpenClaw is an **assistant**, not an operator. It runs as `claw` with:

- no shell toolchain — `programs.openclaw.toolNames = []` removes the upstream
  default `git`/`curl`/`jq`/`python3`/`node`/`pnpm` PATH;
- one narrow, gateway-runtime-only exception: `gh` and `git` are in
  `programs.openclaw.runtimePackages`, which nix-openclaw prepends to the
  gateway wrapper PATH only — the login shell PATH is unchanged. `gh` is needed
  because the OpenClaw bundle ships the launcher, not `gh`; `git` is needed by
  the publication path;
- no host terminal (`gateway.terminal.enabled = false`; upstream defaults it on);
- the browser control UI is **enabled**, which is required: every path except
  `/health(z)` returns 404 otherwise. It therefore _does_ carry a hostname — but
  not in the Nix store. The store copy holds only `enabled = true`;
  `allowedOrigins` is injected from a SOPS-rendered file by the
  `openclaw-patch-control-ui` pre-start hook. `gateway.reload.mode = "off"` makes
  a restart mandatory, so a rebuild can never silently drop the origin;
- uploads disabled, no Podman/Nix socket, no SOPS identity, no SSH key, no host
  deployment credentials;
- a hardened systemd user unit: empty `CapabilityBoundingSet`,
  `SystemCallFilter=@system-service`, `ProtectSystem=strict`,
  `ProtectHome=read-only`, `NoNewPrivileges`, `RestrictAddressFamilies` limited to
  inet/inet6/unix.

## GitHub publishing

The gateway can push branches and open/update pull requests through OpenClaw's
built-in `github_publish` tool. That is the only reason it holds any credential:

- `programs.openclaw.environment.GH_TOKEN` points at
  `/run/secrets/openclaw-github-token`, a host-scoped SOPS secret in
  `secrets/hosts/vps.yaml` (owner `claw`, mode `0400`). The VPS host key
  decrypts it, so `claw` needs no age key and no `secrets/users/claw.yaml`.
- Identity is **native**: a `GH_TOKEN` in the gateway process takes precedence
  over any `gh` keyring, so no `gh` profile directory is created and nothing is
  written outside `~/.openclaw`.
- `tools.github` is deliberately unset. A managed identity means an OAuth
  profile with its own private credential store, and
  `kind: "app-installation"` cannot publish — upstream restricts App
  installations to foreground session reads.

Scope the token to the repositories the assistant may publish to (fine-grained
PAT, Contents + Pull requests: write, or a classic PAT with `repo`). It is not a
host credential: it confers no shell on the VPS and no access to any secret or
service outside those repositories.

Residual risk (not a control we have): the gateway needs **outbound** HTTPS for
the Command Code Provider API and Telegram, so egress is broad. It cannot be
restricted to those endpoints without pinning IPs, which would be brittle.
There is no local model gateway any more: models are reached over HTTPS with a
Bearer key from SOPS (`cmdc/api-key`, host-scoped).

## Models (Command Code)

All model access — OpenClaw, OpenCode, and Neovim — goes through the Command
Code Provider API. There is no local gateway container.

| Consumer                      | Client               | Base used                    | Key source                |
| ----------------------------- | -------------------- | ---------------------------- | ------------------------- |
| OpenClaw                      | `openai-completions` | `…/provider/v1`              | host `cmdc/api-key` → env |
| OpenCode                      | `openai-compatible`  | `…/provider/v1`              | desktop `cmdc/api-key`    |
| Neovim (CodeCompanion/Minuet) | `openai_compatible`  | `…/provider` (appends `/v1`) | desktop `cmdc/api-key`    |

The base URL, default model, and model list live in one place:
`modules/aspects/ai/_commandcode-lib.nix`. Each model ID there was verified to
return **HTTP 200** against this account, not merely present in the catalog.

Restrictions that matter:

- The catalog and **plan access** are different things. The catalog lists
  everything Command Code sells; a model outside your plan returns
  `403 MODEL_NOT_IN_PLAN` (every GPT model and `gemini-4-carbon` do on GOAT).
  Only IDs that actually returned 200 are listed — re-probe if the plan changes.
- Only models advertising `/chat/completions` are listed. **Claude models are
  `/messages`-only** — sending one to `/chat/completions` returns a 400, so they
  are deliberately excluded from this OpenAI-shaped integration.
- Every remaining ID is vendor-prefixed (`deepseek/…`, `Qwen/…`), so
  `provider/model` must be parsed on the **first** slash only (model becomes
  `deepseek/deepseek-v4.1-flash`). Confirm the gateway log line
  `agent model: <provider>/<model>` after changing `defaultModel`.
- Provider API access requires GOAT, Pro, Max or Team — or a **Go plan with
  credits**. A Go plan with no credits returns `403 upgrade_required`.

## Token use

Every turn re-sends the whole conversation, so the recurring cost is
`turns × context size`, not `turns × message length`. Measured on this gateway
before any tuning: **23.3M tokens over 281 requests in a day (~83k per
request)**, on a session 1d9h old and 89k of 128k full, against an **~11k
floor** for a fresh session. A turn's cost therefore grew from 40k to 102k over
twelve messages in one session.

Three things drive that, and all three are configured here:

**1. Session length (the big one).** Cost grows linearly with turns, because
the prompt grows linearly. A task-scoped session — `/new` per task, not one
eternal chat — starts at the floor. Memory files survive a reset, so nothing
durable is lost. This is a usage habit, not a setting.

**2. Context pruning** — `agents.defaults.contextPruning` in
`modules/aspects/server/openclaw.nix`. Upstream leaves pruning **off** for
non-Anthropic providers, and old tool results (exec output, file reads) were
what filled the context. `mode = "cache-ttl"` with `ttl = "10m"` soft-trims and
then hard-clears old tool results, keeping a stable projection between rounds so
the provider prompt cache still hits.

Pruning on a custom route requires `compat.supportsPromptCacheKey = true` on the
model entries; without it upstream installs no cache-TTL job and the block is
silently inert. That flag and `compat.supportsUsageInStreaming` were verified
against this endpoint — `prompt_cache_key` is accepted (HTTP 200) and repeating
a 12k-token prompt returned `cached_tokens: 11904`.

**3. Compaction** — `agents.defaults.compaction`. Both halves of a compaction
are replayed on later turns, so both are a recurring cost. `keepRecentTokens`
(8000, upstream 20000) shortens the verbatim tail; `maxSummaryChars` (6000,
upstream 16000) caps the summary; `thinkingLevel = "off"` stops paying reasoning
tokens for a summary; `model` runs summarisation on the fast model, since
summary quality is bounded by the transcript, not model depth.

Tool schemas are also re-sent every request, so `tools.deny` drops the ones this
deployment cannot use at all — node/desktop tools with no paired device, media
generation, meeting capture, speech. Nothing used for chat, files, exec, memory
or publishing is denied.

### What not to change

- **Do not raise the context window.** A larger window means each turn carries
  _more_ tokens before compaction. The model advertises 1M, the gateway caps it
  at 128k and compacts at ~113k; that cap is a cost control, not a limitation.
- **Do not disable compaction.** It looks like overhead, but without it prompts
  overflow and are retried whole — which costs more than the summary.
- **Do not `sleep`-poll `exec`.** Wakeups triggered this way re-send the entire
  context to read one line of output; on the measured day they accounted for
  **28% of all usage** (5 turns, 388k tokens, ~78k average). Use a single
  blocking command with `yieldMs`, or take the result at turn end.
