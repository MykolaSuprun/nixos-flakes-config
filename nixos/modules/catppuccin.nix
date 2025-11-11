{config, ...}: {
  catppuccin = {
    enable = true;
    cache.enable = true;
    grub.enable = true;
    plymouth.enable = true;
    tty.enable = true;
    sddm.enable = false;
  };

  qt.style = "kvantum";

  environment.sessionVariables = {
    STYLIX_COLORSCHEME = "catppuccin-${config.catppuccin.flavor}";
  };
}
