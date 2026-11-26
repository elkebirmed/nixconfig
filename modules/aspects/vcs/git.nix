# ============================================================================
# Git
# Git identity, delta pager, SSH commit signing, and shared config files.
#
# The email address stays encrypted in SOPS and is rendered into an include.
# Only accounts that actually use git and have an `email/<user>` secret are
# given this aspect, so managed desktop accounts do not need an age key.
# ============================================================================
_: {
  den.aspects.git = {user, ...}: {
    homeManager = {
      config,
      lib,
      pkgs,
      ...
    }: {
      sops.secrets."email/${user.userName}" = {};

      # Render the SOPS-backed email into a git include.
      sops.templates.git-email.content = ''
        [user]
          email = ${config.sops.placeholder."email/${user.userName}"}
      '';

      programs.git = {
        enable = true;

        # Fetch large files with git-lfs.
        lfs.enable = true;

        settings = {
          user = {
            name = user.fullName or user.userName;

            # Sign with the SSH key sops-nix deploys for this account.
            signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519";
          };

          gpg.format = "ssh";

          commit = {
            gpgsign = true;
            template = "~/.config/git/message";
          };

          init.defaultBranch = "main";

          core = {
            pager = "delta";
            editor = "nvim";
            attributesfile = "~/.config/git/attributes";
            excludesfile = "~/.config/git/ignore";
          };

          interactive.diffFilter = "delta --color-only";

          delta = {
            navigate = true;
            dark = true;
            line-numbers = true;
          };

          diff = {
            mnemonicPrefix = true;
            tool = "nvimdiff";
          };

          difftool."nvimdiff".cmd = "nvim -d \"$LOCAL\" \"$REMOTE\"";

          merge = {
            conflictstyle = "zdiff3";
            defaultToUpstream = true;
            tool = "nvimdiff";
          };

          mergetool = {
            keepBackup = false;
          };

          mergetool."nvimdiff".cmd = "nvim -d \"$LOCAL\" \"$REMOTE\"";

          pull.ff = "only";
          push.default = "upstream";

          # Rebase instead of merging on pull, and keep dirty work stashed.
          rebase.autoStash = true;

          # Drop deleted remote branches and auto-track new pushes.
          fetch.prune = true;
          push.autoSetupRemote = true;

          # Reuse recorded conflict resolutions.
          rerere.enabled = true;

          # Histogram diff is easier to read than the default Myers diff.
          diff.algorithm = "histogram";

          # Verify SSH-signed commits against the deployed key.
          gpg.ssh.allowedSignersFile = "~/.config/git/allowed_signers";

          advice.detachedHead = false;

          alias = {
            co = "checkout";
            br = "branch";
            ci = "commit";
            st = "status";
            lg = "log --oneline --graph --decorate";
            po = "push";
          };
        };

        includes = [{path = config.sops.templates.git-email.path;}];
      };

      # delta is referenced by name from the git config.
      home.packages = [pkgs.delta];

      # `gpg.ssh.allowedSignersFile` needs "email key" lines. Generate it from
      # the deployed public key and the SOPS email so signature checks work
      # without a hand-maintained file.
      home.activation.gitAllowedSigners = lib.hm.dag.entryAfter ["writeBoundary"] ''
        signers="${config.xdg.configHome}/git/allowed_signers"
        pubkey="${config.home.homeDirectory}/.ssh/id_ed25519.pub"
        email=$(sed -n 's/^[[:space:]]*email[[:space:]]*=[[:space:]]*//p' "${config.sops.templates.git-email.path}" | head -n1)
        if [[ -r "$pubkey" && -n "$email" ]]; then
          printf '%s %s\n' "$email" "$(cat "$pubkey")" > "$signers"
        fi
      '';

      xdg.configFile = {
        "git/attributes".text = ''
          * text=auto eol=lf
        '';

        "git/message".text = ''
          # 50-character subject line
          #
          # 72-character wrapped longer description. This should answer:
          #
          # * Why was this change necessary?
          # * How does it address the problem?
          # * Are there any side effects?
          #
          # Include a link to the ticket, if any.
          #
          # Add co-authors if you worked on this code with others:
          #
          # Co-authored-by: Full Name <email@example.com>
        '';

        "git/ignore".text = ''
          # IDE and editor state
          .idea
          tmp/

          # Compiled source
          *.com
          *.class
          *.dll
          *.exe
          *.o
          *.so
          *.pyc

          # Editing tools and IDEs
          [._]*.sw[a-p]
          [._]*.s[a-v][a-z]
          *~
          ~*
          \#*\#
          \.#*
          .ipynb_checkpoints/

          # Logs and databases. Only files are ignored, not directories named
          # "log", so a real source tree such as `log/` is still tracked.
          *.log
          *.sqlite

          # OS generated files
          .DS_Store
          .DS_Store?
          Desktop.ini
          Icon?
          ._*
          ehthumbs.db
          Thumbs.db
          .Spotlight-V100
          .Trashes
          Brewfile.lock.json

          # Python and Node dependency directories. `*env/` and bare `env/`
          # are deliberately not ignored: they would hide source directories
          # such as `env/` or `myenv/`.
          .env
          .venv/
          venv/
          node_modules/
        '';
      };
    };
  };
}
