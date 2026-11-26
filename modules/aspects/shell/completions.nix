# ============================================================================
# Completions
# Fish command-line completion for the tools in this repository.
#
# Carapace provides dynamic completions for most existing tools (git, gh, nix,
# nvim, nh, kitty, bat, fd, rg, fzf, ...). Tools without a carapace spec ship
# their own completions in their aspects; sops and opencode are handled here.
# ============================================================================
_: {
  den.aspects.completions.homeManager = {
    lib,
    pkgs,
    ...
  }: {
    programs.carapace = {
      enable = true;
      enableFishIntegration = true;
    };

    xdg.configFile = {
      # sops supports bash and zsh completion only.
      "fish/completions/sops.fish".text = ''
        function __fish_sops_no_subcommand
            not __fish_seen_subcommand_from decrypt encrypt edit exec-env exec-file filestatus groups publish rotate set unset updatekeys completion
        end

        complete -c sops -f -n __fish_sops_no_subcommand -a decrypt -d "Decrypt a file to stdout"
        complete -c sops -f -n __fish_sops_no_subcommand -a encrypt -d "Encrypt a file to stdout"
        complete -c sops -f -n __fish_sops_no_subcommand -a edit -d "Edit an encrypted file"
        complete -c sops -f -n __fish_sops_no_subcommand -a exec-env -d "Run a command with decrypted variables"
        complete -c sops -f -n __fish_sops_no_subcommand -a exec-file -d "Run a command with a decrypted file"
        complete -c sops -f -n __fish_sops_no_subcommand -a filestatus -d "Show encryption status of files"
        complete -c sops -f -n __fish_sops_no_subcommand -a groups -d "List or modify key groups"
        complete -c sops -f -n __fish_sops_no_subcommand -a publish -d "Publish a file to a destination"
        complete -c sops -f -n __fish_sops_no_subcommand -a rotate -d "Rotate the data key"
        complete -c sops -f -n __fish_sops_no_subcommand -a set -d "Set a value in an encrypted file"
        complete -c sops -f -n __fish_sops_no_subcommand -a unset -d "Remove a value from an encrypted file"
        complete -c sops -f -n __fish_sops_no_subcommand -a updatekeys -d "Update the master keys"
        complete -c sops -f -n __fish_sops_no_subcommand -a completion -d "Generate shell completion"

        complete -c sops -s d -l decrypt -d "Decrypt and print to stdout"
        complete -c sops -s e -l encrypt -d "Encrypt and print to stdout"
        complete -c sops -s r -l rotate -d "Rotate the data key"
        complete -c sops -s i -l in-place -d "Write output back to the file"
        complete -c sops -s a -l age -r -d "age recipients"
        complete -c sops -s k -l kms -r -d "KMS ARNs"
        complete -c sops -s p -l pgp -r -d "PGP fingerprints"
        complete -c sops -l gcp-kms -r -d "GCP KMS resource IDs"
        complete -c sops -l azure-kv -r -d "Azure Key Vault URLs"
        complete -c sops -l hc-vault-transit -r -d "Vault transit key URIs"
        complete -c sops -l extract -r -d "Extract a key or branch (decrypt only)"
        complete -c sops -l set -r -d "Set a key or branch (edit only)"
        complete -c sops -l unset -r -d "Unset a key or branch (edit only)"
        complete -c sops -l input-type -r -a "json yaml dotenv ini binary" -d "Input format"
        complete -c sops -l output-type -r -a "json yaml dotenv ini binary" -d "Output format"
        complete -c sops -l config -r -F -d "Path to the SOPS configuration"
        complete -c sops -l filename-override -r -F -d "Filename used for configuration lookup"
        complete -c sops -l indent -r -d "Indentation width"
        complete -c sops -l output -r -F -d "Write output to a file"
        complete -c sops -l verbose -d "Verbose logging"
        complete -c sops -l disable-version-check -d "Skip the update check"
        complete -c sops -s h -l help -d "Show help"
        complete -c sops -s v -l version -d "Show version"

        complete -c sops -F
      '';

      # opencode generates its own Fish completion script. It needs a writable
      # HOME while generating, so point it at the build sandbox.
      "fish/completions/opencode.fish".source = pkgs.runCommandLocal "opencode-fish-completions" {} ''
        export HOME="$TMPDIR"
        ${lib.getExe pkgs.opencode} --completions fish > $out
      '';
    };
  };
}
