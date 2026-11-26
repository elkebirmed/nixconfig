# Private inputs for the Cloudflare DNS configuration.
#
# Every value here is an infrastructure identifier, so NONE of them has a
# committed default and none may appear in this repository. Supply them at
# runtime from a protected environment (TF_VAR_*) or a private, gitignored
# tfvars file, for example:
#
#   export TF_VAR_cloudflare_api_token=...     # Zone:DNS:Edit, that zone only
#   export TF_VAR_zone_name=REDACTED_DOMAIN
#   export TF_VAR_public_records='[...]'
#
# IMPORTANT: only `zone_name` and the token are marked sensitive. The record
# *lists* are not, because OpenTofu refuses to build `for_each` keys from
# sensitive values. The record names/addresses are still private inputs supplied
# at runtime; they are simply not marked sensitive so they can be iterated.
#
# `sensitive = true` keeps a value out of CLI output and plan diffs, but it does
# NOT encrypt Terraform/OpenTofu state. Treat the state file as secret.

variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zone:DNS:Edit on the single managed zone."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "zone_name" {
  description = "The DNS zone to manage. Private: never commit a real domain."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "public_records" {
  description = <<-EOT
    Public records (apex and any public site). Each entry is:
      { name = "@", type = "A", value = "<address>", proxied = true }
    `name` is relative to the zone ("@" for the apex).
  EOT
  type = list(object({
    name    = string
    type    = string
    value   = string
    proxied = optional(bool, false)
    ttl     = optional(number, 1)
  }))
  default = []
}

variable "tailnet_records" {
  description = <<-EOT
    Tailnet-only records. These must be DNS-only (grey cloud): a proxied record
    hides the client IP and breaks Caddy's `remote_ip` tailnet guard.
  EOT
  type = list(object({
    name  = string
    type  = string
    value = string
    ttl   = optional(number, 300)
  }))
  default = []
}
