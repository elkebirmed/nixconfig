# ============================================================================
# Podman
# ============================================================================
_: {
  den.aspects.podman = {
    nixos = {
      environment.persistence."/persist".directories = [
        "/var/lib/containers"
      ];

      virtualisation = {
        podman.enable = true;
        oci-containers.backend = "podman";
      };
    };
  };
}
