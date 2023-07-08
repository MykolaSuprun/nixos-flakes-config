{ inputs, config, pkgs, ... }:
{
  programs.neovim =  {
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

  # packages required for neovim
  home.packages = with pkgs; [
    luajit
    luajitPackages.jsregexp
    luajitPackages.lua-lsp
    stylua
    lazygit
    ripgrep
    fd
    gh
    git
    libgccjit
    tree-sitter
    lazygit
    ripgrep
    fd
    nodejs
    gh                          # Github CLI
    cargo
    binutils
    go
    gcc
    fzf
    fzf-zsh
    rnix-lsp
    nil
    gnumake
    cmake
  ];
}
