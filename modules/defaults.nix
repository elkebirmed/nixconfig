# ============================================================================
# Shared defaults applied across den hosts, users, and homes.
# ============================================================================
{
  lib,
  den,
  ...
}: let
  # Preserve backwards compatibility and handle stateful data migrations.
  # Do NOT change it after the first initial install.
  stateVersion = "26.05";
in {
  # Define default includes for each host.
  den.default.includes = with den.batteries; [
    hostname # Allow hosts to set their hostname and domain name
    self' # Flake’s self outputs with system pre-selected
  ];

  # Keep the NixOS and Home Manager state versions consistent for this config.
  den.default.nixos.system.stateVersion = stateVersion;
  den.default.homeManager.home.stateVersion = stateVersion;

  # Give users Home Manager output by default unless a user overrides this.
  den.schema.user.classes = lib.mkDefault ["homeManager"];

  # Include user-owned NixOS content and user aspects that provide settings to hosts.
  den.schema.host.includes = with den.batteries; [
    user-aspects
    mutual-provider
  ];
}
