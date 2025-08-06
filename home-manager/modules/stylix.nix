{pkgs, ...}: {
  stylix = {
    targets = {
      zen-browser.enable = true;
      ghostty.enable = true;
      fcitx5.enable = true;
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
    };
  };
}
