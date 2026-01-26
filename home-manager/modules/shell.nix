{
  inputs,
  pkgs,
  ...
}: let
  shell_init = pkgs.writeShellScriptBin "init_shell" ''
    export GPG_TTY=$(tty)
    gpgconf --launch gpg-agent
    export VI_MODE_SET_CURSOR=true
    export NIXPKGS_ALLOW_UNFREE=1
    export EDITOR=nvim
    export VISUAL=nvim

    # Aliases
    alias editconf="cd $NIXOS_CONF_DIR; nixvim ."
    alias nxcnf="$NIXOS_CONF_DIR/nxcnf.sh"
    alias nixos-build="$NIXOS_CONF_DIR/scripts/nixos-build.sh"
    alias nix-update="cd $NIXOS_CONF_DIR; nix flake update --accept-flake-config; cd -"
    alias confdir="cd $NIXOS_CONF_DIR"
    alias nixgc="nix-collect-garbage"
    # alias arch-build="$NIXOS_CONF_DIR/home/mykolas/distrobox/build-arch.sh"
    # alias arch="distrobox-enter arch"
    alias vi="nvim"
    alias ls="eza"
    alias cat="bat --theme base16-256"
    # alias conn-win="sdl-freerdp /v:localhost:3389 /u:VM /size:1920x1080 /dynamic-resolution +clipboard"
  '';
  tmux_init = pkgs.writeShellScriptBin "start_tmux" ''
    if tmux run 2>/dev/null; then
      echo "Tmux server is running:"
      exec tmux list-sessions -F '#S' | fzf --reverse | xargs tmux switch-client -t
    else
        echo "Tmux server is not running:"
        exec tmux new-session -s home
    fi
  '';
  conn-win = pkgs.writeShellScriptBin "conn-win" ''
        sdl-freerdp /v:localhost:3389 /u:VM /size:1920x1080 /sound \
      /gfx:AVC444,mask:0xFFFFFFFF /bpp:32 /gdi:hw /network:lan -compression \
      +aero +menu-anims +window-drag +clipboard -grab-keyboard -grab-mouse \
      /cert:ignore /sec:nla:off

    # sdl-freerdp \
    #   /v:localhost:3389 \
    #   /u:VM \
    #   /cert:ignore \
    #   /sec:nla:off \
    #   /dynamic-resolution \
    #   +clipboard \
    #   /sound:sys:pulse \
    #   /gdi:hw \
    #   +rfx \
    #   +fonts \
    #   /bpp:32
  '';

  win11 = pkgs.writeShellScriptBin "win11" ''
    docker compose -f $NIXOS_CONF_DIR/windows-containers/win_11_bacis.yaml up
  '';
  py-init = pkgs.writeShellScriptBin "py-init" ''
    git init

    cat > flake.nix << 'EOF'
    {
      description = "Python development environment with uv";

      inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";
      };

      outputs = {
        self,
        nixpkgs,
        flake-utils,
      }:
        flake-utils.lib.eachDefaultSystem (
          system: let
            pkgs = nixpkgs.legacyPackages.''${system};
          in {
            devShells.default = pkgs.mkShell {
              buildInputs = with pkgs; [
                uv
                python312
              ];

              shellHook = '''
                echo "UV Python environment activated"
                uv --version
                python --version
              ''';
            };
          }
        );
    }
    EOF

    git add .
    nix develop
  '';
in {
  home.packages = with pkgs; [
    babelfish
    grc

    conn-win
    win11
    py-init
  ];

  programs = {
    nushell = {
      enable = true;
      envFile.source = ./../configurations/mykolas/nushell/env.nu;
      configFile.source = ./../configurations/mykolas/nushell/config.nu;
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
        ${builtins.readFile ./../configurations/mykolas/zsh/zshrc}
        # Auto-start tmux if no serve is found. Otherwise choose session with fzf
        # if [[ -z "$TMUX" ]]; then
        #   ${tmux_init}/bin/start_tmux
        # fi
      '';
      antidote = {
        enable = true;
        plugins = [
          "jeffreytse/zsh-vi-mode"
        ];
      };
    };

    bash = {
      enable = true;
      enableCompletion = true;
      initExtra = ''
        source ${shell_init}/bin/init_shell
        # Auto-start tmux if no serve is found. Otherwise choose session with fzf
        # if [[ -z "$TMUX" ]]; then
        #   ${tmux_init}/bin/start_tmux
        # fi
      '';
    };
  };
}
