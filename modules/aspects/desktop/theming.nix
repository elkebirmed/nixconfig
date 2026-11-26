# ============================================================================
# Theming
# Noctalia palettes, per-app templates, wallpaper sets, and the theme CLI.
#
# Palette and template data live next to this file. Wiring goes through the
# Noctalia Home Manager options (`customPalettes`, `theme.templates.user`) so
# every generated file is owned by exactly one writer. Runtime helpers are
# built as packages instead of loose scripts in the home directory.
# ============================================================================
_: {
  den.aspects.theming = {user, ...}: {
    # Theme selection state survives root rollbacks. The wallpaper set lives
    # under `Pictures`, which `persisted-home` already covers.
    homePersistence = {
      inherit (user) userName;
      directories = [
        ".cache/dotfiles"
      ];
    };

    homeManager = {
      lib,
      config,
      pkgs,
      ...
    }: let
      paletteDir = ./theming/palettes;
      templateDir = ./theming/templates;

      # Every palette JSON is installed as-is. `customPalettes` cannot be used
      # here because those names contain spaces, which are illegal in store
      # path names.
      paletteFiles =
        lib.filterAttrs
        (name: type: type == "regular" && lib.hasSuffix ".json" name)
        (builtins.readDir paletteDir);

      templateFiles = builtins.readDir templateDir;

      # Wrap an existing script so its interpreter and tools come from the
      # store instead of the ambient PATH.
      wrapScript = {
        name,
        src,
        runtimeInputs ? [],
      }:
        pkgs.stdenv.mkDerivation {
          pname = name;
          version = "1.0";
          inherit src;
          dontUnpack = true;
          nativeBuildInputs = [pkgs.makeWrapper];
          installPhase = ''
            runHook preInstall
            install -Dm755 "$src" "$out/bin/${name}"
            ${
              lib.optionalString (runtimeInputs != []) ''
                wrapProgram "$out/bin/${name}" --prefix PATH : ${lib.makeBinPath runtimeInputs}
              ''
            }
            runHook postInstall
          '';
        };

      themeCli = wrapScript {
        name = "noctalia-theme";
        src = ./theming/noctalia-theme;

        # The script drives the shell over IPC, so noctalia must be on PATH.
        runtimeInputs =
          (with pkgs; [bash coreutils findutils gnused libnotify])
          ++ lib.optional (config.programs.noctalia.package != null)
          config.programs.noctalia.package;
      };

      kittyReload = wrapScript {
        name = "noctalia-kitty-reload";
        src = ./theming/hooks/kitty.sh;
        runtimeInputs = [pkgs.procps];
      };

      batCache = wrapScript {
        name = "noctalia-bat-cache";
        src = ./theming/hooks/bat.sh;
        runtimeInputs = [pkgs.bat];
      };

      zenSync = wrapScript {
        name = "noctalia-zen-sync";
        src = ./theming/hooks/zen-browser.sh;
        runtimeInputs = with pkgs; [coreutils findutils gnused];
      };

      getPalettes = wrapScript {
        name = "noctalia-get-palettes";
        src = ./theming/quickshell/get-palettes.sh;
        runtimeInputs = [pkgs.bash pkgs.python3];
      };

      # Noctalia reads templates from the XDG config directory.
      templateInput = file: "$XDG_CONFIG_HOME/noctalia/templates/${file}";

      template = file: outputPath: extra:
        {
          input_path = templateInput file;
          output_path = outputPath;
        }
        // extra;

      configHome = "$XDG_CONFIG_HOME";
      cacheHome = "$XDG_CACHE_HOME";
    in {
      home.packages = [
        themeCli
        kittyReload
        batCache
        zenSync
        pkgs.quickshell
      ];

      programs.noctalia.settings.theme.templates.user = {
        niri_colors = template "niri-colors.kdl" "${configHome}/niri/colors.kdl" {};

        kitty_colors =
          template "kitty-colors.conf" "${configHome}/kitty/kitty-colors.conf"
          {post_hook = "${kittyReload}/bin/noctalia-kitty-reload";};

        fish_colors =
          template "fish-colors.fish" "${configHome}/fish/conf.d/noctalia-colors.fish" {};

        lsd_colors = template "lsd-colors.yaml" "${configHome}/lsd/colors.yaml" {};

        starship_colors = template "starship.toml" "${configHome}/starship.toml" {};

        bat =
          template "bat.tmTheme" "${configHome}/bat/themes/noctalia.tmTheme"
          {post_hook = "${batCache}/bin/noctalia-bat-cache";};

        fzf = template "fzf.opts" "${configHome}/fzf/themes/noctalia" {};

        yazi = template "yazi.toml" "${configHome}/yazi/theme.toml" {};

        lazygit = template "lazygit.yml" "${configHome}/lazygit/themes/noctalia.yml" {};

        opencode = template "opencode.json" "${configHome}/opencode/themes/matugen.json" {};

        zen_browser_chrome =
          template "zen-userChrome.css" "${cacheHome}/noctalia/zen-browser/zen-userChrome.css"
          {
            post_hook = "${zenSync}/bin/noctalia-zen-sync";
            hook_async = false;
          };

        zen_browser_content =
          template "zen-userContent.css" "${cacheHome}/noctalia/zen-browser/zen-userContent.css"
          {
            post_hook = "${zenSync}/bin/noctalia-zen-sync";
            hook_async = false;
          };
      };

      # Palette data, template inputs, wallpaper directory map, and picker UI.
      xdg.configFile =
        (lib.mapAttrs' (name: _: {
            name = "noctalia/palettes/${name}";
            value.source = paletteDir + "/${name}";
          })
          paletteFiles)
        // (lib.mapAttrs' (name: _: {
            name = "noctalia/templates/${name}";
            value.source = templateDir + "/${name}";
          })
          templateFiles)
        // {
          "noctalia/wallpaper-sources.toml".source = ./theming/wallpaper-sources.toml;
          "quickshell/theme-switcher/shell.qml".source = ./theming/quickshell/shell.qml;
          "quickshell/theme-switcher/get-palettes.sh".source = getPalettes;
        };

      # Palette wallpapers, resolved by $HOME path from wallpaper-sources.toml.
      home.file."Pictures/Wallpapers".source = ../../../assets/wallpapers;

      # fzf only reads its theme through this variable.
      home.sessionVariables.FZF_DEFAULT_OPTS_FILE = "${config.xdg.configHome}/fzf/themes/noctalia";

      # Theme, wallpaper, and picker binds for the full desktop profile. The
      # generated palette is included by `niri-base` for every profile.
      programs.niri.settings = {
        binds = {
          "Mod+Shift+T".action.spawn = ["${themeCli}/bin/noctalia-theme" "next"];
          "Mod+Ctrl+Shift+T".action.spawn = ["${themeCli}/bin/noctalia-theme" "prev"];
          "Mod+Alt+T".action.spawn = ["${themeCli}/bin/noctalia-theme" "random"];
          "Mod+Shift+Y".action.spawn = ["${themeCli}/bin/noctalia-theme" "mode"];

          "Mod+Shift+W".action.spawn = ["${themeCli}/bin/noctalia-theme" "wallpaper-next"];
          "Mod+Ctrl+Shift+W".action.spawn = ["${themeCli}/bin/noctalia-theme" "wallpaper-prev"];
          "Mod+Alt+W".action.spawn = ["${themeCli}/bin/noctalia-theme" "wallpaper-random"];

          "Mod+P".action.spawn = ["${pkgs.quickshell}/bin/quickshell" "--config" "theme-switcher"];
        };
      };
    };
  };
}
