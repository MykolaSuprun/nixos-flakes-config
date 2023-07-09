{ inputs, config, pkgs, ... }: {
  programs.neovim = {
    enable = true;
    vimAlias = true;

    # extraConfig = ''
    #   luafile $HOME/.config/nvim/settings.lua
    # '';

    plugins = with pkgs.vimPlugins; [
      nvim-treesitter
      lazygit-nvim
      telescope-nvim
    ];
  };

  # packages required for development with neovim and it's plugins
  home.packages = with pkgs; [
    # nix
    nil # Nix lsp
    nixfmt
    rnix-lsp
    # haskell
    haskell-language-server
    ghc
    # lua
    luajit
    stylua
    luajitPackages.jsregexp
    luajitPackages.lua-lsp
    luajitPackages.luarocks
    # other languages
    nodejs
    go
    gcc
    libgccjit
    cargo
    # other dev
    gh # Github CLI
    unzip
    fd
    lazygit
    ripgrep
    gnumake
    cmake
    binutils
    tree-sitter
    fzf
    fzf-zsh
    # other
    xclip
  ];
}
