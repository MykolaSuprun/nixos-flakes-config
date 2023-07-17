{ inputs, ... }:
{
  programs = {
    zsh = {
      enable = true;
      initExtra = ''
        if [[ $(uname -a | grep arch) ]]
        then 
          distrobox-host-exec xhost +local:
          xhost +SI:localuser:$USER
          #PROMPT="%B%F{47}%n%f%b%B:%b%B%F{39}%m%f%b%B>%b "
          alias vi="nvim"
          alias vim="nvim"
          alias nano="nvim"
          alias tmux='tmux -2'
        fi
        export GPG_TTY=$(tty)
        gpgconf --launch gpg-agent
        export VI_MODE_SET_CURSOR=true
        export NIXPKGS_ALLOW_UNFREE=1
        clear
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
      shellAliases = {
        editconf = "cd ~/.dotfiles; nvim .";
        nixos-build = "~/.dotfiles/nixos-build.sh";
        home-build = "~/.dotfiles/home-build.sh";
        nix-update = "~/.dotfiles/nix-update.sh";
        confdir = "~/.dotfiles";
        nixgc = "nix-collect-garbage";
        arch-build = "~/.dotfiles/home/mykolas/distrobox/build-arch.sh";
        arch = "distrobox-enter arch";
        vim = "nvim";
        tmux = "tmux -2";
      };
    };

    bash = {
      enable = true;
      enableCompletion = true;
      bashrcExtra = ''
        if [[ $(uname -a | grep arch) ]]
        then 
          distrobox-host-exec xhost +local:
          xhost +SI:localuser:$USER
          alias vi='nvim'
          alias vim='nvim'
          alias nano='nvim'
          alias tmux='tmux -2'
          zsh
          # echo "in Arch" 
          clear
        else 
          # echo "in NixOS"
          clear
        fi
        export GPG_TTY=$(tty)
        gpgconf --launch gpg-agent
      '';
      shellAliases = {
        vi = "nvim";
        vim = "nvim";
        nano = "nvim";
        editconf = "cd ~/.dotfiles/; nvim .";
        nixos-build = "~/.dotfiles/nixos-build.sh";
        home-build = "~/.dotfiles/home-build.sh";
        nix-update = "~/.dotfiles/nix-update.sh";
        confdir = "~/.dotfiles";
        nixgc = "nix-collect-garbage";
        arch-build = "~/.dotfiles/home/mykolas/distrobox/build-arch.sh";
        arch = "distrobox-enter arch";
        tmux = "tmux -2";
      };
    };
  };
}
