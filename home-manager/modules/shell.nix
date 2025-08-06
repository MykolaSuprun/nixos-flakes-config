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
in {
  home.packages = with pkgs; [
    babelfish
    grc
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
