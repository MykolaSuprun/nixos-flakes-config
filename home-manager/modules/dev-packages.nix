{
  pkgs,
  my-neovim,
  ...
}: {
  services.gpg-agent = {
    enable = true;
    pinentryFlavor = "tty";
  };

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
    rnix-lsp
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
    nixfmt

    sqlcmd
    killall
  ];
}
