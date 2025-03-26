{pkgs, ...}: {
  imports = [
    ./shell.nix
    ./tmux.nix
  ];

  catppuccin = {
    enable = true;
    flavor = "latte";
    accent = "sapphire";

    tmux.enable = true;
    starship.enable = true;
    fish.enable = true;
    zsh-syntax-highlighting.enable = true;
    bottom.enable = true;
    helix.enable = true;
    lazygit.enable = true;
    zellij.enable = true;
  };

  programs = {
    zsh.enable = true;
    lazygit.enable = true;
  };

  home.packages = with pkgs; [
    # dev tools
    cachix
    # my-neovim.packages.${system}.default
    lazydocker
    nodejs
    gh # Github CLI
    meld
    cargo
    binutils
    openssl
    go
    gcc
    cmake
    gnumake
    alejandra
    ghc
    lshw-gui
    glxinfo
    # nix
    nix-tree
    nix-diff
    nixfmt-classic
  ];

  home.sessionVariables = {
    NIXOS_CONF_DIR = "$HOME/.nixconf";
    NIXOS_TARGET = "nix-on-droid";
    BEMENU_BACKEND = "wayland";
    FLAKE = "/home/mykolas/.nixconf";
    # BROWSER = "${pkgs.vivaldi}/bin/vivaldi";
    # DEFAULT_BROWSER = "${pkgs.vivaldi}/bin/vivaldi";
  };
}
