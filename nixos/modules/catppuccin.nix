{ pkgs, ... }: {
  catppuccin.flavor = "latte";
  boot = {
    loader.grub.catppuccin.enable = true;
    loader.grub.catppuccin.flavor = "latte";
    plymouth.catppuccin.enable = true;
  };
  console = { catppuccin.enable = true; };
  services.displayManager.sddm.catppuccin = {
    # enable = true;
  };
}
