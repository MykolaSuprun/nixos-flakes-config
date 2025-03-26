{ pkgs, ... }: {
  catppuccin = {
    enable = true;
    flavor = "latte";
    accent = "mauve";

    hyprland.enable = true;
    cursors = {
      enable = true;
      accent = "mauve";
    };
    fcitx5.enable = true;
    kitty.enable = true;
    alacritty.enable = true;
    tmux.enable = true;
    starship.enable = true;
    fish.enable = true;
    zsh-syntax-highlighting.enable = true;
    bottom.enable = true;
    helix.enable = true;
    lazygit.enable = true;
    zellij.enable = true;
    spotify-player.enable = true;
    vivaldi.enable = true;
    waybar = {
      enable = true;
      flavor = "latte";
    };
  };

  wayland.windowManager.hyprland.catppuccin.enable = true;
  programs = {
    #   tmux.catppuccin.enable = true;
    #   fish.catppuccin.enable = true;
    #   zsh.syntaxHighlighting.catppuccin.enable = true;
    #   fzf.catppuccin.enable = true;
    #   bottom.catppuccin.enable = true;
    #   helix.catppuccin.enable = true;
    #   lazygit.catppuccin.enable = true;
    #   zellij.catppuccin.enable = true;
    #   mpv.catppuccin.enable = true;
    #   spotify-player.catppuccin.enable = true;
    #   waybar.catppuccin = {
    #     enable = true;
    #     flavor = "latte";
    #   };
  };
  gtk = {
    enable = true;
    catppuccin = {
      enable = true;
      flavor = "latte";
      gnomeShellTheme = true;
      icon.enable = true;
    };
  };
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
