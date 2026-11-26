# DNS as code (Cloudflare)

Declarative DNS for the single VPS zone. This directory is deliberately
**decoupled** from NixOS deployment: DNS changes are reviewed and applied on
their own, never as a side effect of a system rebuild.

## What stays private

Everything that identifies the infrastructure lives in variables, not in source:

| Value                            | Where it comes from                                |
| -------------------------------- | -------------------------------------------------- |
| Cloudflare API token             | `TF_VAR_cloudflare_api_token` (protected env only) |
| Zone name                        | `TF_VAR_zone_name`                                 |
| Public record names / addresses  | `TF_VAR_public_records` (JSON)                     |
| Tailnet record names / addresses | `TF_VAR_tailnet_records` (JSON)                    |

`sensitive = true` hides these from CLI output and plan diffs. It does **not**
encrypt state — the state file contains them in clear text.

## State handling

State must live **outside this repository**, encrypted and backed up:

```bash
export TF_STATE=/path/outside/repo/dns.tfstate   # encrypted volume, private
tofu -chdir=infra/dns init
tofu -chdir=infra/dns plan  -state="$TF_STATE"
tofu -chdir=infra/dns apply -state="$TF_STATE"     # requires owner approval
```

`.terraform/`, `*.tfstate*`, and `*.tfvars` are gitignored.

## Workflow

1. Export the variables above in a protected shell.
2. `tofu fmt -check` and `tofu validate` — safe, no network mutation.
3. `tofu plan -state="$TF_STATE"` — review locally. Do not paste plan output
   into chat, issues, or logs; it can contain zone names and addresses.
4. Apply only with explicit owner approval.

## Record rules

- **Tailnet-only names** → `tailnet_records`, always **DNS-only (grey cloud)**.
  A proxied record hides the client IP and breaks Caddy's `remote_ip` guard.
- **Public names** → `public_records`. Proxying is fine; Caddy uses DNS-01.
- Create the record **before** deploying the site that uses it.

## Token scope

One token, one zone, `Zone:DNS:Edit` only. Use a **separate** token for Caddy's
DNS-01 challenge (stored in SOPS as `cloudflare-api-token`) so rotating one does
not require rotating the other.
