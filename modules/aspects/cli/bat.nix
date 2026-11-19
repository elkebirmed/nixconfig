# ============================================================================
# Bat
# bat as a colorized `cat`, with man page rendering and Fish integration.
# ============================================================================
_: {
  den.aspects.bat.homeManager = {pkgs, ...}: {
    programs.bat = {
      enable = true;

      config = {
        # Keep bat's colors aligned with the terminal palette.
        theme = "ansi";
        style = "numbers,changes,header,grid";
        pager = "less -FR";
        italic-text = "always";
      };
    };

    # bat needs less for paging; man pages are rendered through bat as well.
    home.packages = [pkgs.less];

    programs.fish = {
      shellAbbrs.cat = "bat";

      interactiveShellInit = ''
        set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
        set -gx MANROFFOPT "-c"
      '';
    };

    # Completion for the `cat` abbreviation.
    xdg.configFile."fish/completions/cat.fish".text = "complete -c cat -w bat\n";
  };
}
