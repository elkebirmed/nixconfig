# ============================================================================
# Command Code Provider API (shared)
#
# Plain data imported explicitly by consumers; the leading underscore keeps
# import-tree from treating it as a Den module.
#
# Endpoints and catalog: https://api.commandcode.ai/provider/v1/models
#
# Two filters are applied to the catalog, both verified empirically rather than
# assumed:
#
#   1. `/chat/completions` only. Claude-family models advertise `/messages`
#      only and are rejected with 400 on this route, so listing them would
#      produce a config that looks right and fails at runtime.
#
#   2. Availability on THIS account's plan. The catalog lists every model
#      Command Code offers, but access is plan-gated: querying the full catalog
#      with this key returned HTTP 403 MODEL_NOT_IN_PLAN for every GPT model and
#      for `google/gemini-4-carbon`. Only IDs below returned HTTP 200 with an
#      actual completion.
#
# Every ID below therefore contains a slash. That is unavoidable here — every
# model on this plan is vendor-prefixed — so the `provider/model` split is
# expected to take only the first segment (leaving `deepseek/...` as the model).
# See docs/openclaw.md "Models (Command Code)" for where to confirm this after a
# change.
# ============================================================================
{
  # Provider root. Clients that append `/v1/chat/completions` themselves (the
  # CodeCompanion and Minuet adapters in nvf) need this form.
  providerRoot = "https://api.commandcode.ai/provider";

  # OpenAI-compatible base, `/v1` already included. Clients append
  # `/chat/completions`. This is the form OpenCode and OpenClaw expect.
  baseURL = "https://api.commandcode.ai/provider/v1";

  # Default assistant model. Chosen because the GOAT plan carries an active
  # boosted-usage deal on this one, it has a 1M context window, and it is fast
  # enough for interactive chat.
  defaultModel = "deepseek/deepseek-v4.1-flash";

  # Fast/cheap model for inline ghost-text completion, where latency matters
  # far more than depth. Also confirmed available on this plan.
  fastModel = "deepseek/deepseek-v4.1-flash-fast";

  # Chat/completions models confirmed HTTP 200 against this account. Re-run the
  # availability probe if the plan changes.
  models = [
    {
      id = "deepseek/deepseek-v4.1-flash";
      name = "DeepSeek V4.1 Flash";
    }
    {
      id = "deepseek/deepseek-v4.1-flash-fast";
      name = "DeepSeek V4.1 Flash Fast";
    }
    {
      id = "deepseek/deepseek-v4-pro";
      name = "DeepSeek V4 Pro";
    }
    {
      id = "z-ai/glm-5.3-flash";
      name = "GLM-5.3 Flash";
    }
    {
      id = "zai-org/GLM-5.3";
      name = "GLM-5.3";
    }
    {
      id = "inclusionai/ling-3.1-flash";
      name = "Ling 3.1 Flash";
    }
    {
      id = "minimax/minimax-m3.1-flash";
      name = "MiniMax M3.1 Flash";
    }
    {
      id = "Qwen/Qwen3.8-Max";
      name = "Qwen 3.8 Max";
    }
    {
      id = "Qwen/Qwen3.8-Flash";
      name = "Qwen 3.8 Flash";
    }
    {
      id = "google/gemini-3.8-flash";
      name = "Gemini 3.8 Flash";
    }
    {
      id = "moonshotai/Kimi-K3";
      name = "Kimi K3";
    }
    {
      id = "moonshotai/Kimi-K2.7-Code";
      name = "Kimi K2.7 Code";
    }
    {
      id = "xai/grok-4.6";
      name = "Grok 4.6";
    }
  ];
}
