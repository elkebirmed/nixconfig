# ============================================================================
# Command Code
# Install the Command Code CLI and expose its SOPS-backed API key.
# ============================================================================
{inputs, ...}: {
  # llm-agents.nix provides the packaged Command Code CLI.
  flake-file.inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.commandcode = {user, ...}: {
    homePersistence = {
      inherit (user) userName;
      directories = [".commandcode"];
    };

    # Own the shared credential used by both the CLI and the OpenCode provider.
    provides.to-hosts.nixos = _: {
      sops.secrets."cmdc/api-key" = {
        sopsFile = ../../../secrets/users + "/${user.userName}.yaml";
        owner = user.userName;
        mode = "0400";
      };
    };

    homeManager = {
      pkgs,
      lib,
      osConfig,
      ...
    }: let
      commandCode = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.command-code;
      apiKeyFile = osConfig.sops.secrets."cmdc/api-key".path or "/run/secrets/cmdc/api-key";

      # The CLI reads COMMAND_CODE_API_KEY for headless auth. Wrapping the
      # binaries keeps the token out of the profile environment and loads the
      # same SOPS-backed key OpenCode uses.
      wrapCommandCode = name:
        pkgs.writeShellScriptBin name ''
          set -euo pipefail
          api_key_file=${lib.escapeShellArg apiKeyFile}
          if [[ -r "$api_key_file" ]]; then
            api_key=$(tr -d '\r\n' < "$api_key_file")
            export COMMAND_CODE_API_KEY="$api_key"
            export COMMANDCODE_API_KEY="$api_key"
          fi
          exec ${lib.getExe commandCode} "$@"
        '';
    in {
      home.packages = map wrapCommandCode ["cmdc" "cmd" "command-code"];
    };
  };
}
