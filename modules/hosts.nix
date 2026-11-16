# ============================================================================
# Declare which hosts, users, and standalone homes Den should build.
# Their settings live in separate aspect files under `hosts/` and `users/`.
# ============================================================================
{
  # Build the crazy NixOS host with these three users attached.
  den.hosts.x86_64-linux.crazy = {
    users.mohamed = {};
    users.koko = {};
    users.kids = {};
  };

  # Also expose independent Home Manager configurations for each user.
  den.homes.x86_64-linux.mohamed = {};
  den.homes.x86_64-linux.koko = {};
  den.homes.x86_64-linux.kids = {};
}
