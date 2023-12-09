{inputs, ...}: let
  neovim-local = "nix run ~/src/neovim-flake -- ";
  neovim_github = "nix run github:MykolaSuprun/neovim-flake #. -- ";
  conf_root = "~/.dotfiles";
  shell_init = ''
    if [[ $(uname -a | grep arch) ]]
    then
      distrobox-host-exec xhost +local:
      xhost +SI:localuser:$USER
      #PROMPT="%B%F{47}%n%f%b%B:%b%B%F{39}%m%f%b%B>%b "
      alias vi="nvim"
      alias vim="${neovim-local}"
      alias nano="nvim"
      alias tmux='tmux -2'
    fi
    export GPG_TTY=$(tty)
    gpgconf --launch gpg-agent
    export VI_MODE_SET_CURSOR=true
    export NIXPKGS_ALLOW_UNFREE=1
    export confdir=${conf_root}
    export EDITOR=nvim
    export VISUAL=nvim
    clear

    # Aliases
    alias editconf="cd $confdir; nvim ."
    alias nixos-build="$confdir/nixos-build.sh"
    alias home-build="$confdir/home-build.sh"
    alias nix-update="$confdir/nix-update.sh"
    alias confdir=$confdir
    alias nixgc="nix-collect-garbage"
    alias arch-build="$confdir/home/mykolas/distrobox/build-arch.sh"
    alias arch="distrobox-enter arch"
    alias vim="${neovim_github}"
    alias nv="${neovim-local}"
    alias vi="nvim"
    alias tmux="tmux -2"
  '';
in {
  programs = {
    zsh = {
      enable = true;
      initExtra = ''
        ${shell_init}
      '';
      oh-my-zsh = {
        enable = true;
        theme = "agnoster";
        plugins = [
          "git"
          "cp"
          "aliases"
          "branch"
          "cabal"
          "docker"
          "python"
          "scala"
          "sbt"
          "stack"
          "sublime"
          "sudo"
          "systemd"
          "zsh-interactive-cd"
          "vi-mode"
          "archlinux"
        ];
      };
    };

    bash = {
      enable = true;
      enableCompletion = true;
      bashrcExtra = ''
        ${shell_init}
      '';
    };
  };
}
