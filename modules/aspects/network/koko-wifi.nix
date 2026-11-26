# ============================================================================
# Koko Wi-Fi
# Allow koko to join, leave, and modify Wi-Fi (and VPN) connections from the
# desktop without granting the wider `networkmanager` group.
#
# Only the NetworkManager actions a desktop needs are allowed; system-wide
# network configuration and sharing stay admin-only.
# ============================================================================
_: {
  den.aspects.koko-wifi = {
    nixos = {pkgs, ...}: {
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          var allowed = [
            "org.freedesktop.NetworkManager.network-control",
            "org.freedesktop.NetworkManager.settings.modify.own",
            "org.freedesktop.NetworkManager.settings.modify.system",
            "org.freedesktop.NetworkManager.enable-disable-wifi",
            "org.freedesktop.NetworkManager.wifi.scan",
          ];
          if (subject.user == "koko" && subject.local && subject.active
              && allowed.indexOf(action.id) >= 0) {
            return polkit.Result.YES;
          }
        });
      '';

      # The tray applet and the shell's network widget drive these actions.
      environment.systemPackages = [pkgs.networkmanagerapplet];
    };
  };
}
