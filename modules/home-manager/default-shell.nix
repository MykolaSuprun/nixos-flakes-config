{ inputs, ... }:

{
  programs = {
    zsh = {
      enable = true;
      oh-my-zsh = {
        enable = true;
        extraConfig = ''
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
        editconf = "code ~/.dotfiles";
        nixos-build = "~/.dotfiles/apply-system.sh";
        home-build = "~/.dotfiles/apply-users.sh";
        nix-update = "~/.dotfiles/update.sh";
        confdir = "~/.dotfiles";
        nixgc = "nix-collect-garbage";
        arch = "distrobox-enter arch";
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
        editconf = "code ~/.dotfiles";
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