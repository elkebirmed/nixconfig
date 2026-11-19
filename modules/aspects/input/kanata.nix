# ============================================================================
# Kanata
# Kanata as a user service, with access to input devices and uinput.
#
# The user service needs two grants from the host:
#   - membership in `input` to read /dev/input/event* devices;
#   - membership in `uinput` to create the remapped virtual keyboard.
# Both are declared here so the aspect is self-contained.
# ============================================================================
_: {
  den.aspects.kanata = {user, ...}: {
    nixos = {
      hardware.uinput.enable = true;

      # Make keyboard event devices readable by the input group, which the
      # user service joins below.
      services.udev.extraRules = ''
        SUBSYSTEM=="input", KERNEL=="event*", GROUP="input", MODE="0660"
      '';

      users.users.${user.userName}.extraGroups = ["input" "uinput"];
    };

    homeManager = {
      config,
      lib,
      pkgs,
      ...
    }: {
      # Keep the CLI available for manual checks, and so Fish can autoload
      # its completion file for commands present in PATH.
      home.packages = [pkgs.kanata];

      # The configuration lives in the aspect directory, next to this file.
      xdg.configFile."kanata/kanata.kbd".source = ./kanata/kanata.kbd;

      systemd.user.services.kanata = {
        Unit = {
          Description = "Kanata keyboard remapper";
          Documentation = ["https://github.com/jtroo/kanata"];
        };

        Service = {
          Type = "simple";

          # Fail early on a broken configuration instead of restarting forever.
          ExecStartPre = "${lib.getExe pkgs.kanata} --cfg ${config.xdg.configHome}/kanata/kanata.kbd --check";
          ExecStart = "${lib.getExe pkgs.kanata} --cfg ${config.xdg.configHome}/kanata/kanata.kbd --port 5829";

          Restart = "on-failure";
          RestartSec = 2;
        };

        Install.WantedBy = ["default.target"];
      };

      # kanata does not ship a Fish completion file.
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
