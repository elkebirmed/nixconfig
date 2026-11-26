# ============================================================================
# OpenCode
# Configure the OpenCode TUI with the Command Code Provider API.
# ============================================================================
let
  cc = import ./_commandcode-lib.nix;
in {
  den.aspects.opencode = {user, ...}: {
    homePersistence = {
      inherit (user) userName;
      directories = [".local/state/opencode"];
    };

    homeManager = {osConfig, ...}: {
      programs.opencode = {
        enable = true;
        enableMcpIntegration = true;
        mutableSettings = true;
        cli.theme = "kanagawa";

        settings = {
          "$schema" = "https://opencode.ai/config.json";

          # Command Code's Provider API is OpenAI-compatible. The key stays in
          # SOPS and is read by OpenCode at runtime, so nothing secret is in the
          # store. This replaces the local OmniRoute gateway, which was removed.
          model = "cmdc/${cc.defaultModel}";

          providers.cmdc = {
            name = "Command Code";
            package = "@opencode/ai/providers/openai-compatible";
            settings = {
              inherit (cc) baseURL;
              apiKey = "{file:${osConfig.sops.secrets."cmdc/api-key".path or "/run/secrets/cmdc/api-key"}}";
            };

            # Model IDs must be sent verbatim to the API; the display names are
            # local only. See _commandcode-lib.nix for how this list is sourced.
            models = builtins.listToAttrs (
              map (m: {
                name = m.id;
                value.name = m.name;
              })
              cc.models
            );
          };
        };
      };
    };
  };
}
