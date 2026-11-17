# ============================================================================
# OmniRoute
# ============================================================================
_: {
  den.aspects.omniroute = {
    provides.to-hosts.nixos = {config, ...}: {
      environment.persistence."/persist".directories = [
        {
          directory = "/var/lib/omniroute";
          user = "10001";
          group = "10001";
          mode = "0750";
        }
      ];

      sops.secrets = {
        "omniroute/jwt-secret" = {};
        "omniroute/api-key-secret" = {};
        "omniroute/admin-password" = {};
      };

      sops.templates."omniroute.env".content = ''
        JWT_SECRET=${config.sops.placeholder."omniroute/jwt-secret"}
        API_KEY_SECRET=${config.sops.placeholder."omniroute/api-key-secret"}
        INITIAL_PASSWORD=${config.sops.placeholder."omniroute/admin-password"}
      '';

      virtualisation.oci-containers.containers.omniroute = {
        image = "docker.io/diegosouzapw/omniroute:latest";
        user = "10001:10001";
        ports = ["127.0.0.1:20128:20128"];
        volumes = ["/var/lib/omniroute:/app/data"];
        environment.REQUIRE_API_KEY = "true";
        environmentFiles = [config.sops.templates."omniroute.env".path];
      };
    };
  };
}
