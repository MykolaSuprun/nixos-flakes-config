{ inputs, outputs, lib, config, pkgs, overlays, ... }: {
  # imports = [./default-shell.nix];
  imports = [

    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ] ++ outputs.homeManagerModules;

  nixpkgs = {
    # You can add overlays here
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);

      permittedInsecurePackages = [ "openssl-1.1.1u" ];
    };
  };

  home.username = "mykolas";
  home.homeDirectory = "/home/mykolas";

  home.stateVersion = "23.11";

  # Let Home Manager install and manage itself.

  services.gpg-agent = {
    enable = true;
    pinentryFlavor = "tty";
  };

  programs = {
    home-manager.enable = true;

    helix = {
      enable = true;
      package = pkgs.helix;
    };

    zsh.enable = true;
    gpg.enable = true;
  };

  # create home configuration files
  home.file = {
    "./.config/nvim/" = {
      source = ./nvim;
      recursive = true;
      enable = true;
    };
    "./.config/helix" = {
      source = ./helix;
      recursive = true;
      enable = true;
    };
    "./.wezterm.lua" = {
      source = ./wezterm/wezterm.lua;
      enable = true;
    };
    "./.tmux.conf" = {
      source = ./tmux/tmux.conf;
      enable = true;
    };
    "./.gnupg/" = {
      source = ./gnupg;
      recursive = true;
      enable = true;
    };
    "./.gitconfig" = {
      source = ./gitconfig/gitconfig;
      enable = true;
    };
  };

  home.packages = with pkgs; [
    # dev tools
    libgccjit
    tree-sitter
    lazygit
    ripgrep
    fd
    nodejs
    gh # Github CLI
    meld
    cargo
    binutils
    go
    gcc
    fzf
    fzf-zsh
    rnix-lsp
    xclip
    tmux
    tree
    cmake
    gnumake
    wezterm
    git
    git-crypt
    gnupg
    github-desktop
    # haskell
    haskell-language-server
    ghc
    # nix
    nil
    nix-tree
    nix-diff
    nixfmt

    # internet
    mullvad-browser

    # media
    spotify
    vlc
    cider

    # social
    discord
    signal-desktop
    telegram-desktop

    # other
    megasync
    qbittorrent
    morgen
    tusk
    libreoffice-qt
    ledger-live-desktop
    partition-manager
    obsidian

    # plasma packages
    libsForQt5.sddm-kcm
    libsForQt5.ark
    libsForQt5.yakuake
    libsForQt5.qmltermwidget
    libsForQt5.qt5.qtwebsockets
    libsForQt5.qtstyleplugin-kvantum # flatpak plasma theming compatibility tool
    libsForQt5.kpmcore
    libsForQt5.plasma-browser-integration
    libsForQt5.dolphin-plugins

    #graphic, steam, wine libraries
    steam
    mesa
    libdrm
    wine-staging
    winetricks
    vulkan-tools
    vulkan-loader
    vulkan-extension-layer
    vkBasalt
    dxvk
    vulkan-headers
    vulkan-validation-layers
    wine64Packages.fonts
    winePackages.fonts
    distrobox
    gamescope
  ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };

}
