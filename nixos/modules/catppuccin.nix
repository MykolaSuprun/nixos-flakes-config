{pkgs, ...}: let
  base16_scheme = "catppuccin-latte";
in {
  catppuccin = {
    enable = true;
    cache.enable = true;
    flavor = "latte";
    accent = "mauve";
    grub.enable = true;
    plymouth.enable = true;
    tty.enable = true;
    sddm.enable = false;
  };

  qt.style = "kvantum";

  environment.sessionVariables = {
    STYLIX_COLORSCHEME = "${base16_scheme}";
  };
}
