{pkgs, ...}: {
  stylix = {
    targets = {
      zen-browser.enable = false;
      waybar = {
        enable = true;
        enableCenterBackColors = true;
        enableLeftBackColors = true;
        enableRightBackColors = true;
      };
    };
  };
}
