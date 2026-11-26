# ============================================================================
# Web
# Caddy is the only front door. Sites are declared with `web.sites` and share
# one wildcard certificate; a site whose host equals `web.domain` gets its own
# apex vhost.
#
# Cloudflare DNS-01 keeps ACME working while public names stay proxied. The API
# token needs Zone:DNS:Edit for the zone and is stored in SOPS.
#
# The base domain and the ACME contact address are never literals here: the
# Caddyfile contains only `{$WEB_DOMAIN}` / `{$ACME_EMAIL}`, and the real values
# are rendered into /run/caddy.env from SOPS at activation time.
# ============================================================================
_: {
  den.aspects.web.nixos = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.web;

    # One handler per site. Tailnet sites abort requests that do not come from
    # the tailnet; the backend itself stays bound to loopback.
    mkHandler = site: ''
      @${site.name} host ${site.host}
      handle @${site.name} {
        ${lib.optionalString (site.access == "tailnet") ''
        @outside not remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48
        abort @outside
      ''}
        ${site.extraConfig}
        ${lib.optionalString (site.upstream != null) ''
        reverse_proxy ${site.upstream} {
          lb_try_duration 30s
          lb_try_interval 250ms
        }
      ''}
        ${lib.optionalString (site.root != null) ''
        root * ${site.root}
        encode zstd gzip
        file_server
      ''}
      }
    '';

    sites = lib.mapAttrsToList (name: site: site // {inherit name;}) cfg.sites;
    subdomains = builtins.filter (site: site.host != cfg.domain) sites;
    apex = builtins.filter (site: site.host == cfg.domain) sites;
  in {
    options.web = {
      domain = lib.mkOption {
        type = lib.types.str;
        default = "{$WEB_DOMAIN}";
        description = ''
          Base domain for generated site hostnames.

          The default is a Caddy environment placeholder, not a literal domain:
          the real value is rendered into `/run/caddy.env` by sops-nix and never
          enters the Nix store. Set this option only to a placeholder or to
          `web.domain`-relative form; never to a real domain name.
        '';
      };

      sites = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
          options = {
            host = lib.mkOption {
              type = lib.types.str;
              default = "${name}.${cfg.domain}";
              description = "Hostname served for this site.";
            };

            access = lib.mkOption {
              type = lib.types.enum ["public" "tailnet"];
              default = "tailnet";
              description = "Whether the site is public or reachable only from the tailnet.";
            };

            root = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = "Static document root.";
            };

            upstream = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "HTTP upstream to reverse proxy.";
            };

            extraConfig = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = "Extra Caddy directives for this site's handler.";
            };
          };
        }));
        default = {};
        description = "Websites served by Caddy.";
      };
    };

    config = {
      assertions =
        lib.mapAttrsToList (name: site: {
          assertion = (site.root != null) != (site.upstream != null);
          message = "web.sites.${name}: set exactly one of `root` or `upstream`";
        })
        cfg.sites;

      services.caddy = {
        enable = true;
        enableReload = true;
        openFirewall = true;

        # `email` is deliberately left null: the ACME contact address is a
        # personal identifier, so it is rendered into the environment file from
        # SOPS below and referenced as `{$ACME_EMAIL}`. Setting this option
        # would serialise the address into the world-readable Nix store.
        # `{$ENV:default}` is substituted before the Caddyfile is parsed, so the
        # placeholder must carry a parseable fallback.
        globalConfig = lib.mkAfter ''
          email {$ACME_EMAIL:admin@example.invalid}
          acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        '';

        # caddy-dns/cloudflare is a versioned module, pinned by pseudo-version.
        package = pkgs.caddy.withPlugins {
          plugins = ["github.com/caddy-dns/cloudflare@v0.2.4"];
          hash = "sha256-QSiwKqKvSxhksWBF4/MlBOpyXba5xOQ2sRwA0R7399E=";
        };

        # The token, domain, and ACME email are rendered into this file with
        # owner `caddy`.
        environmentFile = "/run/caddy.env";

        virtualHosts =
          lib.optionalAttrs (subdomains != []) {
            "*.${cfg.domain}".extraConfig =
              lib.concatMapStringsSep "\n" mkHandler subdomains
              + ''
                # Unknown subdomains get nothing.
                handle {
                  abort
                }
              '';
          }
          // lib.optionalAttrs (apex != []) {
            "${cfg.domain}".extraConfig = lib.concatMapStringsSep "\n" mkHandler apex;
          };
      };

      # HTTP/3 uses UDP; `openFirewall` only covers the TCP ports.
      networking.firewall.allowedUDPPorts = [443];

      sops.secrets."cloudflare-api-token" = {
        sopsFile = ../../../secrets/hosts/vps.yaml;
      };

      # The domain and ACME contact address are personal identifiers. They are
      # read at activation time and rendered only into this 0400 runtime file,
      # so neither appears in the Nix store or the world-readable Caddyfile.
      sops.secrets."web-domain" = {
        sopsFile = ../../../secrets/hosts/vps.yaml;
      };

      sops.secrets."acme-email" = {
        sopsFile = ../../../secrets/hosts/vps.yaml;
      };

      sops.templates."caddy.env" = {
        path = "/run/caddy.env";
        content = ''
          CLOUDFLARE_API_TOKEN=${config.sops.placeholder."cloudflare-api-token"}
          WEB_DOMAIN=${config.sops.placeholder."web-domain"}
          ACME_EMAIL=${config.sops.placeholder."acme-email"}
        '';
        owner = "caddy";
        mode = "0400";

        # A rotated token, domain, or email is only visible after a restart; a
        # config reload keeps the old environment.
        restartUnits = ["caddy.service"];
      };
    };
  };
}
