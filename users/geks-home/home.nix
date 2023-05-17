{ nputs, outputs, lib, config, pkgs, overlays, ... }: {
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
    overlays = [
      outputs.overlays.stable
      outputs.overlays.home_modifications
      outputs.overlays.additions
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };
  };

  home.username = "geks-home";
  home.homeDirectory = "/home/geks-home";
  home.stateVersion = "22.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.zsh.enable = true;

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentryFlavor = "qt";
  };

  programs = {
    neovim.enable = true;
    neovim.viAlias = true;
    neovim.vimAlias = true;
  };

  home.packages = [
    pkgs.tdesktop
    pkgs.fzf
    pkgs.fzf-zsh
    pkgs.rnix-lsp
    pkgs.vlc
    pkgs.cider
    pkgs.spotify
    pkgs.qbittorrent
    pkgs.zoom-us
    pkgs.libreoffice-qt
    pkgs.discord
    pkgs.mullvad-browser

    # plasma packages
    pkgs.libsForQt5.sddm-kcm
    pkgs.libsForQt5.ark
    pkgs.libsForQt5.yakuake
    pkgs.libsForQt5.qmltermwidget
    pkgs.libsForQt5.qt5.qtwebsockets
    pkgs.libsForQt5.qtstyleplugin-kvantum # flatpak plasma theming compatibility tool

    #dev related packages
    pkgs.github-desktop
    pkgs.vscode
    pkgs.git
    pkgs.git-crypt
    pkgs.gnupg
    pkgs.pinentry_qt
    pkgs.nixfmt
    pkgs.nix-tree
    pkgs.nix-diff
    pkgs.ghc
  ];
}
