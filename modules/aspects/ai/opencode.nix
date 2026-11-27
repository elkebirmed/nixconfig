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

          # --- Token economics -------------------------------------------
          # OpenCode re-sends the whole conversation on every turn, so the
          # recurring cost is `turns x context size`. These three settings cut
          # that payload without touching answer quality; see the "Token use"
          # section in docs/openclaw.md, which covers all three AI consumers.
          #
          # Background work (title generation, summaries) on the fast model:
          # full price for a haiku-sized job is the easiest waste to remove.
          "small_model" = "cmdc/${cc.fastModel}";

          compaction = {
            auto = true;
            # Verbatim tail kept after compaction. Upstream keeps far more,
            # and that tail is replayed on every later turn.
            keep.tokens = 8000;
            # Start compacting with 15% of the window still free, so a long
            # tool loop cannot overflow mid-turn and force a full retry.
            buffer = "15%";
          };

          # Tool results are truncated here and spilled to disk, so an
          # oversized `cat` or test log costs a pointer instead of thousands
          # of tokens. Upstream defaults are 2000 lines / 51200 bytes.
          tool_output = {
            max_lines = 1000;
            max_bytes = 32768;
          };

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
