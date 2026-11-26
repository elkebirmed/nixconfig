# ============================================================================
# Session
# Desktop session plumbing: logind, kernel limits, and printing.
#
# Noctalia handles the power button, so logind must not act on it first.
# ============================================================================
_: {
  den.aspects.session.nixos = {
    # Noctalia owns the short power-key press and presents its own menu; a
    # long press is an unambiguous power-off request.
    services.logind.settings.Login = {
      HandlePowerKey = "ignore";
      HandlePowerKeyLongPress = "poweroff";
    };

    # Editors, watchers, and language servers exhaust the default watch limit.
    boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;

    # Local and network printers, discovered over mDNS.
    services.printing.enable = true;

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };
}
