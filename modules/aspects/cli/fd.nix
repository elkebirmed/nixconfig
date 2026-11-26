# ============================================================================
# fd
# fd as a fast, user-friendly `find` replacement.
# ============================================================================
_: {
  den.aspects.fd.homeManager = {
    programs.fd = {
      enable = true;

      # fd is also the file source for the fzf widgets.
      hidden = true;
      extraOptions = ["--exclude" ".git"];
    };
  };
}
