# ============================================================================
# Polkit & Keyring
# Host-wide authentication and secret plumbing for the desktop session.
#
# Noctalia presents the polkit prompts and stores app secrets in the GNOME
# keyring. The niri-flake polkit agent is disabled in `niri.nix` so only one
# agent runs; this aspect keeps the polkit/keyring services explicit and
# installs the session helpers the shell expects.
# ============================================================================
_: {
  den.aspects.polkit-keyring = {
    nixos = {pkgs, ...}: {
      security.polkit.enable = true;
      services.gnome.gnome-keyring.enable = true;

      # `gnome-keyring.nix` already unlocks the keyring through the `login`
      # PAM service, which both greetd (the Noctalia Greeter) and the console
      # login include. Noctalia's lock screen authenticates with
      # `pam_start("login", ...)` via noctalia-pam-helper, so the same service
      # covers it. Keep the setting explicit so the dependency is visible.
      security.pam.services.login.enableGnomeKeyring = true;

      # NetworkManager's tray applet and the shell's network widgets.
      environment.systemPackages = [pkgs.networkmanagerapplet];
    };
  };
}
