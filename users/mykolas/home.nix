{ config, pkgs, pkgs-unstable, ... }:

{

  home.username = "mykolas";
  home.homeDirectory = "/home/mykolas";

  home.stateVersion = "22.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  nixpkgs.config.allowUnfree = true;

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentryFlavor = "qt";
  };

  programs = {
    neovim.enable = true;
    neovim.viAlias = true;
    neovim.vimAlias = true;
    git = {
      enable = true;
      userName = "Mykola Suprun";
      userEmail = "mykola.suprun@protonmail.com";
    };


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
        sysbuild = "~/.dotfiles/apply-system.sh";
        hmbuild = "~/.dotfiles/apply-users.sh";
        sysupdate = "~/.dotfiles/update.sh";
        confdir = "~/.dotfiles";
        nsgc = "nix-collect-garbage";
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
        sysbuild = "~/.dotfiles/apply-system.sh";
        hmbuild = "~/.dotfiles/apply-users.sh";
        sysupdate = "~/.dotfiles/update.sh";
        confdir = "~/.dotfiles";
        nsgc = "nix-collect-garbage";
        arch = "distrobox-enter arch";
      };
    };
  };

  home.packages = [
    pkgs.firefox
    pkgs.brave
    pkgs.vscode-with-extensions
    pkgs.git
    pkgs.git-crypt
    pkgs.gnupg
    pkgs.pinentry_qt
    pkgs.github-desktop
    pkgs.tdesktop
    pkgs.megasync
    pkgs.thefuck
    pkgs.fzf
    pkgs.fzf-zsh
    pkgs.rnix-lsp
    pkgs.vlc
    pkgs.cider

    # plasma packages
    pkgs.libsForQt5.sddm-kcm
    pkgs.libsForQt5.ark
    pkgs.libsForQt5.yakuake
    pkgs.libsForQt5.qmltermwidget
    pkgs.libsForQt5.qt5.qtwebsockets
    pkgs.qbittorrent

    #graphic, steam, wine libraries
    pkgs-unstable.mesa
    pkgs-unstable.libdrm
    pkgs-unstable.wine-staging
    pkgs-unstable.winetricks
    pkgs-unstable.vulkan-tools
    pkgs-unstable.vulkan-loader
    pkgs-unstable.vulkan-extension-layer
    pkgs-unstable.vkBasalt
    pkgs-unstable.dxvk
    pkgs-unstable.vulkan-headers
    pkgs-unstable.vulkan-validation-layers
    pkgs-unstable.wine64Packages.fonts
    pkgs-unstable.winePackages.fonts
    pkgs-unstable.lutris
    pkgs-unstable.steam
    pkgs-unstable.discord
    pkgs-unstable.distrobox
  ];


}
