{pkgs, ...}: {
  catppuccin = {
    enable = true;
    flavor = "latte";
  };
  i18n.inputMethod.fcitx5.catppuccin.enable = true;
  programs = {
    kitty.catppuccin.enable = true;
    alacritty.catppuccin.enable = true;
    tmux.catppuccin.enable = true;
    fish.catppuccin.enable = true;
    fzf.catppuccin.enable = true;
    bottom.catppuccin.enable = true;
    helix.catppuccin.enable = true;
    lazygit.catppuccin.enable = true;
    zellij.catppuccin.enable = true;
    waybar.catppuccin = {
      enable = true;
      flavor = "latte";
    };
  };
  # gtk.catppuccin = {
  #   enable = true;
  #   flavor = "latte";
  #   cursor.enable = true;
  #   icon.enable = true;
  # };
  # qt.style.catppuccin = {
  #   enable = true;
  #   flavor = "latte";
  # };
  home.packages = with pkgs; [
    # catppuccin-kde
    # catppuccin-gtk
    # catppuccin-kvantum
    # catppuccin-cursors
    # catppuccin-papirus-folders
  ];
}
