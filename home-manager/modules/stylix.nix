{pkgs, ...}: {
  stylix = {
    enable = true;
    targets = {
      zen-browser.enable = true;
      ghostty.enable = true;
      fcitx5.enable = true;
      btop.enable = true;
      lazygit.enable = true;
      hyprpaper.enable = true;
      waybar = {
        enable = true;
        enableCenterBackColors = true;
        enableLeftBackColors = true;
        enableRightBackColors = true;
      };
      kitty = {
        enable = true;
        variant256Colors = true;
      };
      zellij = {
        enable = true;
      };
    };
  };
}
