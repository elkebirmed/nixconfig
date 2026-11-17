# ============================================================================
# Opencode
# ============================================================================
_: {
  den.aspects.opencode = {user, ...}: {
    homePersistence = {
      inherit (user) userName;
      directories = [".local/state/opencode"];
    };

    homeManager.programs.opencode = {
      enable = true;
      enableMcpIntegration = true;
      mutableSettings = true;
      cli.theme = "kanagawa";

      settings = {
        "$schema" = "https://opencode.ai/config.json";
        providers.omniroute = {
          name = "OmniRoute";
          npm = "@ai-sdk/openai-compatible";
          options = {
            baseURL = "http://localhost:20128/v1";
            apiKey = "{env:OMNIROUTE_API_KEY}";
          };
          models = {
            auto = {
              name = "Auto";
              limit = {
                context = 128000;
                output = 8192;
              };
            };
            "auto/coding" = {
              name = "Auto Coding";
              limit = {
                context = 128000;
                output = 8192;
              };
            };
            "auto/fast" = {
              name = "Auto Fast";
              limit = {
                context = 128000;
                output = 8192;
              };
            };
            "auto/cheap" = {
              name = "Auto Cheap";
              limit = {
                context = 128000;
                output = 8192;
              };
            };
            "auto/reasoning" = {
              name = "Auto Reasoning";
              limit = {
                context = 128000;
                output = 8192;
              };
            };
            "auto/vision" = {
              name = "Auto Vision";
              limit = {
                context = 128000;
                output = 8192;
              };
            };
          };
        };
      };
    };
  };
}
