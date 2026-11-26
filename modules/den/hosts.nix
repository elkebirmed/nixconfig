# ============================================================================
# Hosts
# Declare which hosts, users, and standalone homes Den should build.
# Their settings live in separate aspect files under `hosts/` and `users/`.
# ============================================================================
{
  # Build the crazy NixOS host with these three users attached. Mohamed gets the
  # full desktop; koko and kids keep the default simple, Windows-like setup.
  den.hosts.x86_64-linux.crazy = {
    users.mohamed.desktopProfile = "full";
    users.koko = {};
    users.kids = {};
  };

  # Also expose independent Home Manager configurations for each user. The
  # standalone homes mirror the host profiles for the same accounts.
  den.homes.x86_64-linux.mohamed.desktopProfile = "full";
  den.homes.x86_64-linux.koko = {};
  den.homes.x86_64-linux.kids = {};
}
