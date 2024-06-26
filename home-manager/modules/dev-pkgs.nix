{
  pkgs,
  my-neovim,
  ...
}: {
  programs = {
    helix = {
      enable = true;
      package = pkgs.helix;
    };
    direnv = {
      enable = true;
      enableBashIntegration = true; # see note on other shells below
      nix-direnv.enable = true;
    };
    # neovim = {
    #   enable = true;
    #   package = my-neovim.packages.${system}.default;
    # };
    zsh.enable = true;
    gpg.enable = true;
    fzf = {
      enable = true;
      tmux.enableShellIntegration = true;
    };
    lazygit = {
      enable = true;
    };
  };

  home.packages = with pkgs; [
    # dev tools
    cachix
    my-neovim.packages.${system}.default
    tree-sitter
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
    xclip
    tree
    cmake
    gnumake
    wezterm
    git
    git-crypt
    gnupg
    alejandra
    ghc
    # nix
    nix-tree
    nix-diff
    nixfmt-classic

    lf
    sqlcmd
    killall
    bottom
  ];
}
