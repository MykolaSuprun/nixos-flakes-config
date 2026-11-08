_: {
  flake.modules.homeManager.shell = {
    pkgs,
    lib,
    config,
    ...
  }: let
    flake-init = pkgs.writeShellApplication {
      name = "flake-init";
      runtimeInputs = [pkgs.fzf pkgs.git];
      text = ''
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
    };
  in {
    options.myconf.shell.enable = lib.mkEnableOption "shell configuration";

    config = lib.mkIf config.myconf.shell.enable {
      home.packages = [
        pkgs.eza
        pkgs.grc
        flake-init
      ];

      home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };

      programs = {
        carapace = {
          enable = true;
          enableZshIntegration = true;
          enableBashIntegration = true;
        };
        fzf = {
          enable = true;
          enableZshIntegration = true;
          enableBashIntegration = true;
        };
        starship = {
          enable = true;
          enableBashIntegration = true;
          enableZshIntegration = true;
          enableTransience = true;
        };
        zoxide = {
          enable = true;
          enableBashIntegration = true;
          enableZshIntegration = true;
          options = ["--cmd cd"];
        };
        direnv = {
          enableZshIntegration = true;
          enableBashIntegration = true;
        };
        zsh = {
          enable = true;
          dotDir = config.home.homeDirectory; # keep ~/.zshrc (pre-26.05 default)
          enableCompletion = true;
          autosuggestion.enable = true;
          defaultKeymap = "viins";
          autocd = true;
          history = {
            share = true;
            ignoreAllDups = true;
            save = 50000;
            size = 50000;
          };
          sessionVariables.VI_MODE_SET_CURSOR = "true";
          shellAliases = {
            vi = "nvim";
            ls = "eza";
            cat = "bat --theme base16-256";
            nixgc = "nix-collect-garbage";
            confdir = "cd $NIXOS_CONF_DIR";
            editconf = "cd $NIXOS_CONF_DIR; nixvim .";
          };
          initContent = ''
            # Per-terminal: must be evaluated in every interactive shell.
            export GPG_TTY="$(tty)"

            # Local, untracked overrides.
            [[ -f ~/.zshrc_lcl ]] && source ~/.zshrc_lcl
          '';
          antidote = {
            enable = true;
            plugins = ["jeffreytse/zsh-vi-mode"];
          };
        };
      };
    };
  };
}
