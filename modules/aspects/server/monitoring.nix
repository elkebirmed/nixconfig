# ============================================================================
# Monitoring
# Small, single-node observability: node exporter, Prometheus, Grafana.
#
# Sized for the actual VPS (4 vCPU / 8 GB RAM / 75 GB disk). Deliberately
# minimal:
#   * no Loki / log aggregation stack;
#   * no alerting backend (no Alertmanager, no external paging);
#   * 14-day TSDB retention with a hard size cap.
#
# Everything binds loopback and is reachable only through Caddy's tailnet
# guard. No dashboard, metric label, or job name may contain a real domain,
# address, or private application name: use generic logical names.
#
# Secrets: the Grafana admin password, its config secret key, and the public
# base URL are all rendered into /run at activation time from SOPS. Grafana
# expands `$__env{...}` in its config, so none of them becomes a store literal.
# ============================================================================
_: {
  den.aspects.monitoring.nixos = {
    config,
    lib,
    ...
  }: let
    listen = "127.0.0.1";

    # Grafana builds absolute links and login redirects from `root_url`, so it
    # must match the host Caddy actually serves it on. Deriving it from the
    # site definition instead of spelling a hostname here keeps the two from
    # drifting apart. `host` holds the Caddy placeholder rather than a real
    # domain, so swap in the SOPS placeholder: the URL is only rendered into
    # /run at activation and never reaches the store.
    grafanaRootUrl =
      "https://"
      + lib.replaceStrings ["{$WEB_DOMAIN}"] [config.sops.placeholder."web-domain"]
      config.web.sites.grafana.host;
  in {
    services.prometheus = {
      enable = true;
      listenAddress = listen;
      port = 9090;

      # 14 days keeps the TSDB small; the size cap is the real safety net on a
      # 75 GB disk.
      retentionTime = "14d";
      extraFlags = ["--storage.tsdb.retention.size=2GB"];

      globalConfig = {
        scrape_interval = "60s";
        evaluation_interval = "60s";
      };

      scrapeConfigs = [
        {
          # Generic job name: no host, domain, or application identifier.
          job_name = "node";
          static_configs = [{targets = ["${listen}:9100"];}];
        }
        {
          # Scraping itself catches retention and cardinality problems.
          job_name = "prometheus";
          static_configs = [{targets = ["${listen}:9090"];}];
        }
      ];
    };

    services.prometheus.exporters.node = {
      enable = true;
      listenAddress = listen;
      port = 9100;
      enabledCollectors = ["systemd" "processes"];
    };

    services.grafana = {
      enable = true;

      settings = {
        server = {
          http_addr = listen;
          http_port = 3000;

          # Behind Caddy, Grafana needs an absolute root URL for links and
          # redirects. The value embeds the real domain, so it is supplied from
          # the runtime environment instead of being written here.
          root_url = "$__env{GF_SERVER_ROOT_URL}";
          # Left off deliberately. `enforce_domain` rejects requests whose Host
          # header does not match `root_url`, which would be useful against DNS
          # rebinding, but it is not the control guarding this instance: Caddy
          # already refuses anything outside the tailnet before the request
          # reaches Grafana (see `web.sites.grafana.access`). Turning it on is a
          # separate hardening decision, not something to enable silently here.
          enforce_domain = false;
        };

        # Grafana requires an explicit secret key; using the env provider keeps
        # it out of the Nix store.
        security = {
          admin_password = "$__env{GF_SECURITY_ADMIN_PASSWORD}";
          secret_key = "$__env{GF_SECURITY_SECRET_KEY}";
          # Grafana still creates its first admin from env; no self-signup.
          disable_gravatar = true;
        };

        "auth.anonymous".enabled = false;
        users.allow_sign_up = false;
        analytics.reporting_enabled = false;
        analytics.check_for_updates = false;
      };

      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://${listen}:9090";
            isDefault = true;
          }
        ];
      };
    };

    # One runtime environment file feeds all three values. `web-domain` is
    # declared in the web aspect; reusing its placeholder keeps the domain in a
    # single place and out of the store.
    sops.secrets."grafana-admin-password" = {
      sopsFile = ../../../secrets/hosts/vps.yaml;
    };

    sops.secrets."grafana-secret-key" = {
      sopsFile = ../../../secrets/hosts/vps.yaml;
    };

    sops.templates."grafana.env" = {
      path = "/run/grafana.env";
      owner = "grafana";
      group = "grafana";
      mode = "0400";
      content = ''
        GF_SECURITY_ADMIN_PASSWORD=${config.sops.placeholder."grafana-admin-password"}
        GF_SECURITY_SECRET_KEY=${config.sops.placeholder."grafana-secret-key"}
        GF_SERVER_ROOT_URL=${grafanaRootUrl}
      '';
      # Grafana reads its environment once at start.
      restartUnits = ["grafana.service"];
    };

    systemd.services.grafana.serviceConfig.EnvironmentFile =
      config.sops.templates."grafana.env".path;

    # Resource ceilings so a runaway scrape cannot take the whole box down.
    systemd.services.prometheus.serviceConfig = {
      MemoryMax = "768M";
      CPUQuota = "150%";
    };

    systemd.services.grafana.serviceConfig = {
      MemoryMax = "512M";
      CPUQuota = "100%";
    };

    # Loopback-only backends, exposed to the tailnet by Caddy. `access` is the
    # default but is stated explicitly because this is administrative data.
    web.sites.metrics = {
      upstream = "http://${listen}:9090";
      access = "tailnet";
    };

    web.sites.grafana = {
      upstream = "http://${listen}:3000";
      access = "tailnet";
    };
  };
}
