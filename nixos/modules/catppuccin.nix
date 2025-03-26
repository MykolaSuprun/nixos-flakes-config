{ pkgs, ... }: {
  catppuccin = {
    enable = true;
    flavor = "latte";
    accent = "mauve";
    cache.enable = true;
    grub.enable = true;
    plymouth.enable = true;
    tty.enable = true;
    sddm.enable = false;
  };
}
