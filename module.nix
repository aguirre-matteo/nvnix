{ starterRepo }:

{ lib, pkgs, config, ... }:
let
  inherit (lib)
  mkRenamedOptionModule mkRemovedOptionModule
  mkEnableOption mkPackageOption mkOption
  mkIf types;

  cfg = config.programs.nvchad;
in {
  imports = [
    (mkRenamedOptionModule
      [ "programs" "nvchad" "neovim" ]
      [ "programs" "nvchad" "package" ]
    )
    (mkRenamedOptionModule
      [ "programs" "nvchad" "lazy-lock" ]
      [ "programs" "nvchad" "lazyLock" ]
    )
    (mkRemovedOptionModule
      [ "programs" "nvchad" "gcc" ]
      "Override `finalPackage` instead."
    )
    (mkRemovedOptionModule
      [ "programs" "nvchad" "hm-activation" ]
      "Home-Manager will always copy NvChad's config when `programs.nvchad.enable` is set to true."
    )
  ];

  options.programs.nvchad = {
    enable = mkEnableOption "NvChad";
    package = mkOption {
      type = with types; nullOr package;
      default = pkgs.neovim;
      defaultText = "pkgs.neovim";
      description = "Neovim package to use along NvChad.";
    };

    finalPackage = mkOption {
      type = types.package;
      default = pkgs.callPackage ./package.nix {
        inherit (cfg) starterConfig extraPackages
        extraConfig chadrcConfig lazyLock excludePackages;

        neovim = cfg.package;
        withDesktopEntry = cfg.desktopEntry.enable;
        desktopEntryTitle = cfg.desktopEntry.title;
        desktopEntryStyle = cfg.desktopEntry.style;
      };
      defaultText = "nvchad";
      description = "Final package containing NvChad's config and Neovim wrapper.";
    };

    starterConfig = mkOption {
      type = types.path;
      default = starterRepo;
      defaultText = "NvChad's starter repo.";
      description = "Starter config for NvChad.";
    };

    excludePackages = mkOption {
      type = with types; listOf package;
      default = [ ];
      example = ''
        with pkgs; [
          nodejs
          lua-language-server
          ripgrep
        ];
      '';
      description = ''
        List of packages to exclude from the wrapped Neovim
        PATH. Use at your own risk.
      '';
    };

    extraPackages = mkOption {
      type = with types; listOf package;
      default = [ ];
      example = ''
        with pkgs; [
          nodePackages.bash-language-server
          emmet-language-server
          nixd
          (python3.withPackages(ps: with ps; [
            python-lsp-server
            flake8
          ]))
        ];
      '';
      description = ''
        List of additional packages available for NvChad as runtime dependencies
        NvChad extensions assume that the libraries it need will be available
        globally. By default, all dependencies for the starting configuration
        are included. Overriding the option will expand this list.
      '';
    };

    extraPlugins = mkOption {
      type = with types; either str path;
      default = "return {}";
      description = "Extra plugins to install in NvChad through `lazy.nvim`.";
    };

    extraConfig = mkOption {
      type = with types; either str path;
      default = "";
      description = "Extra config to be loaded at the end of `init.lua` in the NvChad's starter.";
    };

    chadrcConfig = mkOption {
      type = with types; either str path;
      default = "";
      description = ''
        Config to be put on NvChad's `chadrc.lua` file. Make sure to
        include `local M = {}` at the top and `return M` at the bottom
        to make sure it's a valid file.
      '';
    };

    lazyLock = mkOption {
      type = with types; either str path;
      default = "";
      description = "The `lazy-lock.json` file for pinning the versions in your config.";
    };

    backup = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to backup existing configurations. It will save the previous
        config at `~/.config/nvim_%Y_%m_%d_%H_%M_%S.bak`. This ensures the 
        module doesn't accidentally deletes your personal config. It's highly
        recommended to set this to `false`, since otherwise the activation
        would create a lot of unnecessary backups.
      '';
    };

    desktopEntry = mkOption {
      type = with types; submodule {
        options = {
          enable = mkOption {
            type = bool;
            default = true;
            description = "Whether to enable NvChad's desktop entry.";
          };
          title = mkOption {
            type = str;
            default = "NvChad";
            description = "Title the desktop entry should show.";
          };
          style = mkOption {
            type = enum [ "light" "dark" ];
            default = "light";
            description = "Style for the NvChad logo in the desktop entry.";
          };
        };
      };
      default = {};
      description = "Configuration for NvChad's desktop entry.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.programs.neovim.enable;
        message = "Cannot set `programs.nvchad.enable = true` if `programs.neovim.enable` is also set to true.";
      }
    ];
    
    home.packages = [ cfg.finalPackage ];
    home.activation = let
      nvchadConfig = "${config.xdg.configHome}/nvim";
    in {
      backupNvimConfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        if [ -d "${nvchadConfig}" ]; then
          ${
            if cfg.backup then
              ''
                backup_name="nvim_$(${pkgs.coreutils}/bin/date +'%Y_%m_%d_%H_%M_%S').bak"
                ${pkgs.coreutils}/bin/mv \
                  ${nvchadConfig} \
                  ${config.xdg.configHome}/$backup_name
              ''
            else
              ''
                ${pkgs.coreutils}/bin/rm -r ${nvchadConfig}
              ''
          }
        fi
      '';

      copyNvchadConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.coreutils}/bin/mkdir -p ${nvchadConfig}
        ${pkgs.coreutils}/bin/cp -r ${cfg.finalPackage}/config/* ${nvchadConfig}
        for file_or_dir in $(${pkgs.findutils}/bin/find ${nvchadConfig}); do
          if [ -d "$file_or_dir" ]; then
            ${pkgs.coreutils}/bin/chmod 755 $file_or_dir
          else
            ${pkgs.coreutils}/bin/chmod 664 $file_or_dir
          fi
        done
      '';
    };
  };
}
