{ config, pkgs, ... }:

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


  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx.engines = with pkgs.fcitx-engines; [ mozc hangul m17n unikey table-other rime ];
    fcitx5.addons = with pkgs; [ 
      fcitx5-rime 
      fcitx5-gtk 
      libsForQt5.fcitx5-qt 
      fcitx5-with-addons
      fcitx5-chinese-addons
      fcitx5-table-other
      fcitx5-configtool
      fcitx5-hangul
      fcitx5-unikey
      fcitx5-m17n
      fcitx5-mozc
    ];
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


  home.packages = with pkgs; [
    firefox
    brave
    vscode-with-extensions
    distrobox
    git
    git-crypt
    gnupg
    pinentry_qt
    github-desktop
    tdesktop
    megasync
    thefuck
    fzf
    fzf-zsh
    discord
    rnix-lsp
    vlc

    #fcitx
    libsForQt5.fcitx-qt5
    fcitx-configtool
    librime
    libhangul
    rime-data
    vimPlugins.fcitx-vim
    fcitx5-gtk

    # plasma packages
    libsForQt5.sddm-kcm
    libsForQt5.ark
    libsForQt5.yakuake
    libsForQt5.qmltermwidget
    libsForQt5.qt5.qtwebsockets
    qbittorrent
  ];


}
