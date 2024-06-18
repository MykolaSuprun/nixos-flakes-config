{pkgs, ...}: {
  catppuccin.flavor = "latte";
  boot.loader.grub.catppuccin.enable = true;
  boot.loader.grub.catppuccin.flavor = "latte";
  console = {
    catppuccin.enable = true;
  };
  services.displayManager.sddm.catppuccin = {
    enable = true;
  };
}
