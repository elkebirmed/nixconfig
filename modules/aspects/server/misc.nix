# ============================================================================
# Server Misc
# Small server services: fail2ban, nix-ld, and Podman pruning.
# ============================================================================
_: {
  den.aspects.server-misc.nixos = {
    services.fail2ban.enable = true;
    programs.nix-ld.enable = true;

    # The Podman module owns the prune unit; only its schedule is set here.
    # Do not pass `--all`: it can delete the pinned OmniRoute image while its
    # container is stopped mid-switch. Dangling images and unused volumes are
    # still reclaimed.
    virtualisation.podman.autoPrune = {
      enable = true;
      flags = ["--volumes"];
      dates = "weekly";
    };
  };
}
