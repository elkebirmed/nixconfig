# ============================================================================
# Quadlet
# Declarative Podman containers through quadlet-nix (podman-systemd).
#
# This is the single container path for server applications. Keep it that way:
# do not mix in a second container framework, and do not introduce a separate
# deployment control plane (Komodo/ArgoCD/Kubernetes) for a single VPS.
#
# Hardening baseline for every container declared here:
#   * no `Privileged`, no `Network=host`, no `PID=host`, no added capabilities
#     unless a specific, documented exception exists;
#   * `NoNewPrivileges=true`, dropped capabilities, resource limits, and one
#     explicit persistent directory per stateful app;
#   * images pinned by digest, never `:latest`.
#
# Private application images must NOT be written here. A literal image
# reference in this file would land in the Nix store. See
# `modules/aspects/server/private-app.nix` for the runtime injection path.
# ============================================================================
{inputs, ...}: {
  # Pin quadlet-nix. It declares only a `flake-parts` input (no `nixpkgs`), so
  # there is nothing to make follow the flake's nixpkgs; the generated units are
  # consumed by this flake's pkgs regardless.
  flake-file.inputs.quadlet-nix = {
    url = "github:mirkolenz/quadlet-nix";
  };

  den.aspects.quadlet.nixos = {
    config,
    lib,
    ...
  }: {
    imports = [inputs.quadlet-nix.nixosModules.default];

    virtualisation.quadlet.enable = true;

    # The default `containers` system user exists to allocate subordinate IDs
    # for `UserNS=auto`. The declared containers run as explicit numeric users
    # with bind-mounted state, so that helper account is not needed.
    virtualisation.quadlet.containersUser.enable = false;

    # Container storage is a large, rebuildable cache. It is intentionally not
    # backed up: images are re-pulled from pinned digests after a restore.
    #
    # Note: quadlet units are generated into /etc/systemd by the Podman
    # generator, so they need no persistence entry of their own.
    assertions = [
      {
        # Guards the rule above: a `:latest` reference must never reach
        # production, because it defeats digest pinning.
        assertion =
          lib.all
          (container:
            !(lib.hasSuffix ":latest" (container.containerConfig.Image or "")))
          (lib.attrValues config.virtualisation.quadlet.containers);
        message = "quadlet: pin container images by digest, not `:latest`";
      }
    ];
  };
}
