# Declarative DNS for the single VPS zone.
#
# This file contains NO real zone name, record name, or address: every value
# comes from a private variable (see variables.tf). Do not run `tofu apply`
# without owner approval, and never print a plan that contains private values.

data "cloudflare_zone" "this" {
  name = var.zone_name
}

# Public records (apex / public sites). Proxying is allowed because Caddy
# obtains certificates with DNS-01, so no HTTP-01 challenge is needed.
resource "cloudflare_record" "public" {
  for_each = { for r in var.public_records : "${r.type}-${r.name}" => r }

  zone_id = data.cloudflare_zone.this.id
  name    = each.value.name
  type    = each.value.type
  value   = each.value.value

  # `proxied` only applies to A/AAAA/CNAME.
  proxied = contains(["A", "AAAA", "CNAME"], each.value.type) ? each.value.proxied : null
  ttl     = each.value.proxied ? 1 : each.value.ttl
}

# Tailnet-only records must stay DNS-only (grey cloud). A proxied record hides
# the client IP, which breaks the `remote_ip` tailnet guard in the Caddyfile.
resource "cloudflare_record" "tailnet" {
  for_each = { for r in var.tailnet_records : "${r.type}-${r.name}" => r }

  zone_id = data.cloudflare_zone.this.id
  name    = each.value.name
  type    = each.value.type
  value   = each.value.value
  proxied = false
  ttl     = each.value.ttl
}
