{
  pkgs,
  my-neovim,
  ...
}: {
  programs = {
    helix = {
      enable = true;
      package = pkgs.helix;
      catppuccin.enable = true;
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
      catppuccin.enable = true;
      tmux.enableShellIntegration = true;
    };
    lazygit = {
      enable = true;
      catppuccin.enable = true;
    };
  };

  home.packages = with pkgs; [
    # dev tools
    my-neovim.packages.${system}.default
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
    xclip
    tree
    cmake
    gnumake
    wezterm
    git
    git-crypt
    gnupg
    github-desktop
    alejandra
    # haskell
    haskell-language-server
    ghc
    # nix
    nil
    nix-tree
    nix-diff
    nixfmt-classic

    sqlcmd
    killall
    bottom
  ];
}
