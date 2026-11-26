# ============================================================================
# fzf
# Fuzzy finding wired into Fish, with fd-backed and preview-enabled widgets.
# ============================================================================
_: {
  den.aspects.fzf.homeManager = {
    programs.fzf = {
      enable = true;
      enableFishIntegration = true;

      defaultCommand = "fd --type f --hidden --follow --exclude .git";

      defaultOptions = [
        "--height=60%"
        "--layout=reverse"
        "--border"
        "--info=inline"
      ];

      # Ctrl-T: files with a bat preview.
      fileWidget = {
        command = "fd --type f --hidden --follow --exclude .git";
        options = ["--preview 'bat --style=numbers --color=always --line-range :200 {}'"];
      };

      # Alt-C: directories with a tree preview.
      changeDirWidget = {
        command = "fd --type d --hidden --follow --exclude .git";
        options = ["--preview 'lsd --tree --depth 2 {}'"];
      };
    };
  };
}
