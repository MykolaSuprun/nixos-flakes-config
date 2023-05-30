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
          PROMPT="%B%F{47}%n%f%b%B:%b%B%F{39}%m%f%b%B>%b "
          alias vi="nvim"
          alias vim="nvim"
          alias nano="nvim"
        fi
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
        editconf = "hx ~/.dotfiles";
        nixos-build = "~/.dotfiles/apply-system.sh";
        home-build = "~/.dotfiles/apply-users.sh";
        nix-update = "~/.dotfiles/update.sh";
        confdir = "~/.dotfiles";
        nixgc = "nix-collect-garbage";
        arch = "distrobox-enter arch";
        vim = "nvim";
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
          zsh
          # echo "in Arch" 
          clear
        else 
          # echo "in NixOS"
          clear
        fi
      '';
      shellAliases = {
        vi = "nvim";
        vim = "nvim";
        nano = "nvim";
        editconf = "hx ~/.dotfiles";
        nixos-build = "~/.dotfiles/apply-system.sh";
        home-build = "~/.dotfiles/apply-users.sh";
        nix-update = "~/.dotfiles/update.sh";
        confdir = "~/.dotfiles";
        nixgc = "nix-collect-garbage";
        arch = "distrobox-enter arch";
      };
    };
  };
}
