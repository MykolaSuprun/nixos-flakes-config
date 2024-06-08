{pkgs, ...}: {
  catppuccin = {
    enable = true;
    flavor = "latte";
  };
  i18n.inputMethod.fcitx5.catppuccin.enable = true;
  programs = {
    tmux.catppuccin.enable = true;
    fish.catppuccin.enable = true;
    fzf.catppuccin.enable = true;
    helix.catppuccin.enable = true;
    lazygit.catppuccin.enable = true;
  };
}
