# ============================================================================
# Niri
# Niri scrollable-tiling Wayland compositor: host-wide session wiring.
#
# This aspect registers the one shared niri session with the display manager
# and installs the portal, polkit, keyring, and XWayland plumbing. The
# declarative niri configuration itself lives in the per-user `niri-base`
# aspect plus the selected profile aspect (`niri-pro` or `niri-simple`).
#
# The compositor itself comes from nixpkgs (`pkgs.niri`), not from niri-flake's
# cache: the flake only supplies the session and Home Manager modules.
#
# Trade-offs of using `pkgs.niri`:
# - Pros: one package source, no third-party substituter trusted for input,
#   and the "built from source" intent holds — niri-flake's `niri-stable`
#   output is signed by niri-epireyn.cachix.org and is therefore a cache
#   substitution, not a local build.
# - Cons: nixpkgs updates niri on its own schedule, so newer niri releases can
#   lag until nixpkgs bumps them. If a bleeding-edge niri is needed, pin it via
#   an overlay instead of reintroducing the cache.
# - Both build the same upstream source with dbus/screencast/systemd enabled,
#   so behavior is unchanged.
# ============================================================================
{inputs, ...}: {
  # niri-flake provides the NixOS session module and the Home Manager config
  # generator used by the per-user aspects.
  flake-file.inputs.niri = {
    url = "github:epireyn/niri-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.niri = {
    nixos = {pkgs, ...}: {
      imports = [inputs.niri.nixosModules.niri];

      programs.niri = {
        enable = true;
        package = pkgs.niri;
      };

      # niri looks up xwayland-satellite on PATH when an X11 client connects.
      environment.systemPackages = [pkgs.xwayland-satellite];

      # The Noctalia polkit agent owns authentication now (polkit-keyring.nix),
      # so the agent niri-flake installs alongside the session is disabled to
      # avoid two competing agents.
      systemd.user.services.niri-flake-polkit.enable = false;

      # Secrets and app credentials are stored in the login keyring.
      services.gnome.gnome-keyring.enable = true;
    };
  };
}
