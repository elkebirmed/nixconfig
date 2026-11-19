# ============================================================================
# lsd
# lsd as a colorful `ls` replacement, with Fish aliases and completion.
# ============================================================================
_: {
  den.aspects.lsd.homeManager = {
    programs.lsd = {
      enable = true;

      # Provides the `ls`, `ll`, `la`, `lt`, `lla`, and `llt` shortcuts.
      enableFishIntegration = true;

      settings = {
        date = "relative";
        hyperlink = "auto";
        sorting."dir-grouping" = "first";
      };

      icons.theme = "fancy";
    };

    # lsd does not ship a Fish completion file.
    xdg.configFile."fish/completions/lsd.fish".text = ''
      complete -c lsd -s a -l all -d "Do not ignore entries starting with ."
      complete -c lsd -s A -l almost-all -d "Do not list implied . and .."
      complete -c lsd -l color -r -a "always auto never" -d "When to use colors"
      complete -c lsd -l icon -r -a "always auto never" -d "When to print icons"
      complete -c lsd -l icon-theme -r -a "fancy unicode" -d "Icon theme"
      complete -c lsd -s F -l classify -d "Append indicator to file names"
      complete -c lsd -s l -l long -d "Display extended metadata"
      complete -c lsd -l ignore-config -d "Ignore the configuration file"
      complete -c lsd -l config-file -r -F -d "Use a custom configuration file"
      complete -c lsd -s 1 -l oneline -d "Display one entry per line"
      complete -c lsd -s R -l recursive -d "Recurse into directories"
      complete -c lsd -s h -l human-readable -d "Human-readable sizes"
      complete -c lsd -l tree -d "Display the result as a tree"
      complete -c lsd -l depth -r -d "Maximum recursion depth"
      complete -c lsd -s d -l directory-only -d "Display directories themselves"
      complete -c lsd -l permission -r -a "rwx octal attributes disable" -d "Permission format"
      complete -c lsd -l size -r -a "default short bytes" -d "Size format"
      complete -c lsd -l total-size -d "Display the total size of directories"
      complete -c lsd -l date -r -a "date locale relative" -d "Date format"
      complete -c lsd -s t -l timesort -d "Sort by modification time"
      complete -c lsd -s S -l sizesort -d "Sort by size"
      complete -c lsd -s X -l extensionsort -d "Sort by extension"
      complete -c lsd -s G -l gitsort -d "Sort by git status"
      complete -c lsd -s v -l versionsort -d "Natural sort"
      complete -c lsd -l sort -r -a "size time version extension git none" -d "Sort type"
      complete -c lsd -s U -l no-sort -d "Do not sort"
      complete -c lsd -s r -l reverse -d "Reverse the sort order"
      complete -c lsd -l group-dirs -r -a "none first last" -d "Group directories"
      complete -c lsd -l group-directories-first -d "Group directories first"
      complete -c lsd -l blocks -r -a "permission user group context size date name inode links git" -d "Blocks to display"
      complete -c lsd -l classic -d "Classic ls-like output"
      complete -c lsd -l no-symlink -d "Do not display symlink targets"
      complete -c lsd -s I -l ignore-glob -r -d "Ignore glob pattern"
      complete -c lsd -s i -l inode -d "Display inode numbers"
      complete -c lsd -s g -l git -d "Show git status"
      complete -c lsd -s L -l dereference -d "Dereference symbolic links"
      complete -c lsd -s Z -l context -d "Print security context"
      complete -c lsd -l hyperlink -r -a "always auto never" -d "Attach hyperlinks"
      complete -c lsd -l header -d "Display block headers"
      complete -c lsd -l truncate-owner-after -r -d "Truncate owner names"
      complete -c lsd -l truncate-owner-marker -r -d "Truncation marker"
      complete -c lsd -s N -l literal -d "Print names without quoting"
      complete -c lsd -l help -d "Show help"
      complete -c lsd -s V -l version -d "Show version"
      complete -c lsd -F
    '';
  };
}
