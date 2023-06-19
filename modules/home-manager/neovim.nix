{ inputs, config, pkgs, ... }:

# let

# in 

{
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
}
