# ============================================================================
# OpenCode
# Configure the OpenCode TUI with the OmniRoute and Command Code providers.
# ============================================================================
_: {
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

          # Default to the free-only combo.
          model = "omniroute/auto/coding:free";

          providers = {
            omniroute = {
              name = "OmniRoute";
              package = "@opencode/ai/providers/openai-compatible";
              settings = {
                baseURL = "http://localhost:20128/v1";
                apiKey = "{file:/var/lib/omniroute-bootstrap/api-key}";
              };
              models = {
                "auto/coding:free".name = "Auto Coding (Free)";
                "auto/reasoning:free".name = "Auto Reasoning (Free)";
                "auto/vision:free".name = "Auto Vision (Free)";
                "auto/chat:free".name = "Auto Chat (Free)";
                "auto/best-free".name = "Auto Best (Free)";
              };
            };

            # Command Code's Provider API is OpenAI-compatible for non-Claude
            # models. The key stays in SOPS and is read by OpenCode at runtime.
            cmdc = {
              name = "Command Code";
              package = "@opencode/ai/providers/openai-compatible";
              settings = {
                baseURL = "https://api.commandcode.ai/provider/v1";
                apiKey = "{file:${osConfig.sops.secrets."cmdc/api-key".path or "/run/secrets/cmdc/api-key"}}";
              };
              models = {
                "deepseek/deepseek-v4.1-flash".name = "DeepSeek V4.1 Flash";
                "deepseek/deepseek-v4.1-flash-fast".name = "DeepSeek V4.1 Flash Fast";
                "Qwen/Qwen3.8-Max".name = "Qwen 3.8 Max";
                "google/gemini-3.8-flash".name = "Gemini 3.8 Flash";
                "gpt-6.2-astra".name = "GPT-6.2 Astra";
                "z-ai/glm-5.3-flashx".name = "GLM-5.3 FlashX";
              };
            };
          };
        };
      };
    };
  };
}
