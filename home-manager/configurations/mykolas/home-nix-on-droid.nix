{
  config,
  lib,
  pkgs,
  ...
}: {
  # Read the changelog before changing this value
  home.stateVersion = "24.05";

  imports = [
    # ./../../modules/geks-nix-on-droid.nix
  ];

  # insert home-manager config

  catppuccin = {
    enable = true;
    flavor = "latte";
    accent = "mauve";

    tmux.enable = true;
    starship.enable = true;
    fish.enable = true;
    zsh-syntax-highlighting.enable = true;
    bottom.enable = true;
    helix.enable = true;
    lazygit.enable = true;
    zellij.enable = true;
  };

  services.gpg-agent = {
    enable = true;
    # pinentryPackage = pkgs.pinentry-tty;
    pinentryPackage = pkgs.pinentry-bemenu;
  };

  programs = {
    zsh.enable = true;
    lazygit.enable = true;
    home-manager.enable = true;
  };

  home.packages = with pkgs; [
    # dev tools
    cachix
    # my-neovim.packages.${system}.default
    gh # Github CLI
    meld
    cargo
    binutils
    openssl
    go
    gcc
    alejandra
    ghc
    lshw-gui
    glxinfo
    # nix
    nix-tree
    nix-diff
    nixfmt-classic
  ];

  home.file = {
    "./.gitconfig".source = ./gitconfig/gitconfig;
    "./.gnupg/" = {
      source = ./gnupg;
      recursive = true;
    };
  };

  fonts.fontconfig.enable = true;
}
