{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  liveLinks = import ../../lib/live-links.nix {inherit lib;};
  zshConfig = import ../../lib/zsh-config.nix;

  shell_init = pkgs.writeShellScriptBin "init_shell" (
    builtins.concatStringsSep "\n" (
      builtins.attrValues (builtins.mapAttrs (k: v: "export ${k}=${v}") zshConfig.settings.env)
    )
    + "\n"
    + builtins.concatStringsSep "\n" (
      builtins.attrValues (builtins.mapAttrs (k: v: "alias ${k}=${builtins.toJSON v}") zshConfig.settings.shellAliases)
    )
  );

  flake-init = pkgs.writeShellScriptBin "flake-init" ''
    FLAKE_DIR="''${NIXOS_CONF_DIR:-$HOME/workspaces/src/nixconf}"
    FZF_BIND=(--bind "j:down,k:up,g:first,G:last,ctrl-d:half-page-down,ctrl-u:half-page-up")

    TEMPLATE=$(printf 'python-uv\ngo\nhaskell\njava\nscala' \
      | fzf \
          --header "Select project template:" \
          --prompt "template> " \
          "''${FZF_BIND[@]}") || { echo "Aborted." >&2; exit 1; }

    git init
    nix flake init -t "$FLAKE_DIR#$TEMPLATE"
    git add .
    nix develop
  '';
in {
  options.myconf.shell.enable = lib.mkEnableOption "shell configuration";
  config = lib.mkIf config.myconf.shell.enable (lib.mkMerge [
    # tmuxp presets and sesh configs are read at SPAWN time, so live-link
    # changes need no reload hook (nothing holds them in memory).
    {
      home.activation =
        (liveLinks.mkLiveLinks {
          activationName = "linkTmuxpPresets";
          nixPath = ../users/mykolas/config/tmuxp;
          runtimePath = "${config.home.sessionVariables.NIXOS_CONF_DIR}/home-manager/users/mykolas/config/tmuxp";
          targetPath = "~/.config/tmuxp";
          filter = name: lib.hasSuffix ".yaml" name;
        }).home.activation
        // (liveLinks.mkLiveLinks {
          activationName = "linkSeshConfig";
          nixPath = ../users/mykolas/config/sesh;
          runtimePath = "${config.home.sessionVariables.NIXOS_CONF_DIR}/home-manager/users/mykolas/config/sesh";
          targetPath = "~/.config/sesh";
          filter = name: lib.hasSuffix ".toml" name;
        }).home.activation;
    }
    {
      home.packages = with pkgs; [
        babelfish
        grc
        tmuxp

        flake-init
      ];

      programs = {
        nushell = {
          enable = true;
          envFile.source = ./../users/mykolas/config/nushell/env.nu;
          configFile.source = ./../users/mykolas/config/nushell/config.nu;
        };
        carapace = {
          enable = true;
          enableNushellIntegration = true;
          enableZshIntegration = true;
          enableFishIntegration = true;
          enableBashIntegration = true;
        };
        fzf = {
          enable = true;
          tmux.enableShellIntegration = true;
          enableZshIntegration = true;
          enableFishIntegration = true;
          enableBashIntegration = true;
        };
        starship = {
          enable = true;
          enableBashIntegration = true;
          enableZshIntegration = true;
          enableFishIntegration = true;
          enableNushellIntegration = true;
          enableTransience = true;
        };
        zoxide = {
          enable = true;
          enableBashIntegration = true;
          enableZshIntegration = true;
          enableFishIntegration = true;
          enableNushellIntegration = true;
          options = [
            "--cmd cd"
          ];
        };
        direnv = {
          enableZshIntegration = true;
          enableBashIntegration = true;
          enableFishIntegration = true;
        };
        zsh = {
          enable = true;
          enableCompletion = true;
          autosuggestion.enable = true;
          defaultKeymap = "viins";
          initContent = ''
            source ${shell_init}/bin/init_shell
            ${zshConfig.extraRC}
          '';
          antidote = {
            enable = true;
            plugins = [
              "jeffreytse/zsh-vi-mode"
            ];
          };
        };
        # herdr is now managed by home-manager/modules/herdr.nix,
                # gated behind myconf.herdr.enable with tmux-like keybindings.
      };
    }
  ]);
}
