# ============================================================================
# Display Manager
# Noctalia Greeter on greetd with one shared niri session for every user.
#
# The greeter module and package come from the noctalia-greeter flake. The
# Noctalia cache provides the flake package; the input does not follow nixpkgs
# so the derivation matches the cache. Appearance is kept in sync from the
# Noctalia shell's constrained (passwordless) sync.
# ============================================================================
{inputs, ...}: {
  flake-file.inputs.noctalia-greeter = {
    # Do not follow nixpkgs: the Noctalia cache has the flake package built
    # against the flake's own nixpkgs.
    url = "github:noctalia-dev/noctalia-greeter";
  };

  den.aspects.display-manager = {
    # Keep the greeter's synced appearance and session state across rollbacks.
    systemPersistence.directories = ["/var/lib/noctalia-greeter"];

    nixos = _: {
      imports = [inputs.noctalia-greeter.nixosModules.default];

      services.displayManager.noctalia-greeter = {
        enable = true;

        # Let mohamed sync appearance to the greeter without a password prompt;
        # every other user keeps the authenticated sync path.
        passwordless-sync-users = ["mohamed"];

        settings = {
          # niri's desktop-entry filename; the greeter also accepts its Name.
          session.default = "niri";

          # Open directly on mohamed's password step.
          user.default = "mohamed";

          appearance = {
            # Palette and wallpaper are populated by Noctalia's constrained
            # sync; do not hard-code a palette or it would freeze the theme.
            scheme = "Synced";
            password_style = "random";
            hide_logo = false;
            power_buttons_position = "bottom-right";
            scheme_selector_position = "top-right";
            theme_mode = "dark";
            corner_radius_scale = 1.25;
            font_family = "Rubik";
          };

          clock = {
            enabled = true;
            position = "above-panel";
            time_format = "{:%H:%M}";
            date_format = "%A, %x";
            time_font_size = 48;
            date_font_size = 14;
          };

          # Follow the outputs synced from Noctalia; no explicit layout or
          # scale is pinned, so no monitor geometry is required.
          output.use_synced_settings = true;

          cursor = {
            # Match `home.pointerCursor` in desktop-defaults.nix.
            theme = "Bibata-Modern-Ice";
            size = 24;
          };

          keyboard = {
            layout = "us";
            numlock = true;
          };
        };
      };
    };
  };
}
