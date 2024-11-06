{ pkgs, ... }: {
  catppuccin = {
    enable = true;
    flavor = "latte";
    pointerCursor.enable = true;
  };
  i18n.inputMethod.fcitx5.catppuccin.enable = true;

  wayland.windowManager.hyprland.catppuccin.enable = true;
  programs = {
    kitty.catppuccin.enable = true;
    alacritty.catppuccin.enable = true;
    tmux.catppuccin.enable = true;
    fish.catppuccin.enable = true;
    zsh.syntaxHighlighting.catppuccin.enable = true;
    fzf.catppuccin.enable = true;
    bottom.catppuccin.enable = true;
    helix.catppuccin.enable = true;
    lazygit.catppuccin.enable = true;
    zellij.catppuccin.enable = true;
    mpv.catppuccin.enable = true;
    spotify-player.catppuccin.enable = true;
    waybar.catppuccin = {
      enable = true;
      flavor = "latte";
    };
  };
  # gtk = {
  #   enable = true;
  #   catppuccin = {
  #     enable = true;
  #     flavor = "latte";
  #     gnomeShellTheme = true;
  #     icon.enable = true;
  #   };
  # };
  qt.style.catppuccin = {
    enable = true;
    flavor = "latte";
  };

  home.pointerCursor = {
    gtk.enable = true;
    # package = pkgs.catppuccin-cursors;
    # name = "mochaMauve";

  };

  home.packages = with pkgs;
    [
      # catppuccin-kde
      # catppuccin-gtk
      # catppuccin-kvantum
      # catppuccin-cursors
      # catppuccin-papirus-folders
    ];
}
