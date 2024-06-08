{pkgs, ...}: {
  catppuccin = {
    enable = true;
    flavor = "latte";
  };
  i18n.inputMethod.fcitx5.catppuccin.enable = true;
  programs.tmux.catppuccin.enable = true;
  programs.fish.catppuccin.enable = true;
}
