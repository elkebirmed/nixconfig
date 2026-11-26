# ============================================================================
# Kanata
# System-level keyboard remapper with its own unprivileged identity.
#
# NixOS's `services.kanata` module runs each keyboard as a `DynamicUser` with
# only the `input` and `uinput` supplementary groups and a narrow device
# allowlist. Nothing else needs read access to `/dev/input/event*`, so this
# aspect no longer widens device permissions or adds users to groups.
# ============================================================================
_: {
  den.aspects.kanata = {
    nixos = {
      services.kanata = {
        enable = true;

        keyboards.default = {
          # A full upstream config; the module's `devices`/`extraDefCfg` are
          # ignored when `configFile` is set.
          configFile = ./kanata/kanata.kbd;

          # Kanata maps a bare port to 127.0.0.1, so the TCP control server is
          # never reachable from the network.
          port = 5829;
        };
      };
    };

    # The CLI is on the system PATH; only the completion file is still needed
    # because kanata does not ship one.
    homeManager = {
      xdg.configFile."fish/completions/kanata.fish".text = ''
        complete -c kanata -s c -l cfg -r -F -d "Configuration file"
        complete -c kanata -l cfg-stdin -d "Read configuration from stdin"
        complete -c kanata -s p -l port -r -d "TCP server port or address"
        complete -c kanata -s s -l symlink-path -r -F -d "Symlink for the virtual device"
        complete -c kanata -s l -l list -d "List available keyboards"
        complete -c kanata -s q -l quiet -d "Only log errors"
        complete -c kanata -s d -l debug -d "Enable debug logging"
        complete -c kanata -s t -l trace -d "Enable trace logging"
        complete -c kanata -s n -l nodelay -d "Remove the startup delay"
        complete -c kanata -s w -l wait-device-ms -r -d "Device wait in milliseconds"
        complete -c kanata -l check -d "Validate the configuration and exit"
        complete -c kanata -l log-layer-changes -d "Log layer changes"
        complete -c kanata -l no-wait -d "Skip the press-enter prompt"
        complete -c kanata -l emergency-exit-code -r -d "Exit code for emergency exit"
        complete -c kanata -s h -l help -d "Show help"
        complete -c kanata -s V -l version -d "Show version"
      '';
    };
  };
}
