{ pkgs, ... }: {
  catppuccin = {
    enable = true;
    flavor = "latte";
    accent = "sapphire";
    cache.enable = true;
    grub.enable = true;
    plymouth.enable = true;
    tty.enable = true;
    sddm.enable = false;
  };
}
