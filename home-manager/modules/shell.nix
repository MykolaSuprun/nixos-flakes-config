{
  inputs,
  pkgs,
  ...
}: let
  neovim-local = "nix run ~/src/nixvim-config -- ";
  nvf-local = "nix run ~/src/neovim-nvf-config -- ";
  neovim_github = "nix run github:MykolaSuprun/nixvim-config #. -- ";
  conf_root = "$NIXOS_CONF_DIR";
  shell_init = pkgs.writeShellScriptBin "init_shell" ''
    # if [[ $(uname -a | grep arch) ]]
    # then
    #   distrobox-host-exec xhost +local:
    #   xhost +SI:localuser:$USER
    #   #PROMPT="%B%F{47}%n%f%b%B:%b%B%F{39}%m%f%b%B>%b "
    #   alias vi="nvim"
    #   alias vim="${neovim-local}"
    #   alias nano="nvim"
    #   alias tmux='tmux -2'
    #   alias steamtinkerlaunch=/home/mykolas/.steam/root/compatibilitytools.d/SteamTinkerLaunch
    #   clear
    # fi
    export GPG_TTY=$(tty)
    gpgconf --launch gpg-agent
    export VI_MODE_SET_CURSOR=true
    export NIXPKGS_ALLOW_UNFREE=1
    export confdir=${conf_root}
    export EDITOR=nvim
    export VISUAL=nvim

    # Aliases
    alias editconf="cd $confdir; nvim ."
    alias nxcnf="$confdir/nxcnf.sh"
    alias nixos-build="$confdir/scripts/nixos-build.sh"
    alias nix-update="cd $confdir; nix flake update --accept-flake-config; cd -"
    alias confdir="cd $confdir"
    alias nixgc="nix-collect-garbage"
    alias arch-build="$confdir/home/mykolas/distrobox/build-arch.sh"
    alias arch="distrobox-enter arch"
    alias vim="${neovim_github}"
    alias nv="${nvf-local}"
    alias vi="nvim"
    alias tmux="tmux -2"
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
  home.packages = with pkgs; [babelfish grc];

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
      initExtra = ''
        ${shell_init}
        ${builtins.readFile ./../configurations/mykolas/zsh/zshrc}
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
        ${shell_init}
      '';
    };
  };
}
