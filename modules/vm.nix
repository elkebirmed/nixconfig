# ============================================================================
# Expose `nix run .#vm` as a quick test loop for the crazy host.
# This launches its generated VM without switching or rebooting the real system.
# ============================================================================
{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.vm = pkgs.writeShellApplication {
      name = "vm";
      text = let
        # Use the evaluated NixOS configuration to locate its VM launcher.
        host = inputs.self.nixosConfigurations.crazy.config;
      in ''
        ${host.system.build.vm}/bin/run-${host.networking.hostName}-vm "$@"
      '';
    };
  };
}
