terraform {
  # Pin the provider so DNS changes are reproducible. Run
  # `tofu init -upgrade` deliberately when you intend to move it.
  required_version = ">= 1.6.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.40"
    }
  }

  # State deliberately lives OUTSIDE this public repository. It contains the
  # real zone name, record names, and target addresses, and `sensitive = true`
  # does NOT encrypt state. Point `-state` at a private, encrypted location and
  # back it up separately. See infra/dns/README.md.
  backend "local" {}
}

provider "cloudflare" {
  # Read from the environment (CLOUDFLARE_API_TOKEN) or a protected, ignored
  # tfvars file. Never commit the token, and never put it in Nix.
  api_token = var.cloudflare_api_token
}
