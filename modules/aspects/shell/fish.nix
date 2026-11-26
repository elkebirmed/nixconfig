# ============================================================================
# Fish
# Shell defaults, helpers, and persistence across root rollbacks.
# ============================================================================
_: {
  den.aspects.fish = {user, ...}: {
    homePersistence = {
      inherit (user) userName;
      directories = [".local/share/fish"];
    };

    homeManager = {
      programs.fish = {
        # Prefer abbreviations when other modules offer both.
        preferAbbrs = true;

        interactiveShellInit = ''
          set -g fish_greeting
          set -gx EDITOR nvim

          # Jump to the parent directory without leaving the home row.
          bind \ce 'cd ..; and commandline -f repaint'

          # Interactive ripgrep (defined below).
          bind \cg rgf
        '';

        functions = {
          rgf = {
            description = "Interactive ripgrep; Enter opens the match";
            body = ''
              set -l rg "rg --column --line-number --no-heading --color=always --smart-case"
              fzf --ansi --disabled --query "$argv" \
                  --bind "start:reload:$rg {q} || true" \
                  --bind "change:reload:sleep 0.1; $rg {q} || true" \
                  --prompt 'ripgrep> ' \
                  --delimiter : \
                  --color "hl:-1:underline,hl+:-1:underline:reverse" \
                  --preview 'bat --color=always {1} --highlight-line {2}' \
                  --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
                  --bind "enter:become($EDITOR {1} +{2})"
            '';
          };
        };
      };
    };
  };
}
