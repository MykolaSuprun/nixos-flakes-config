{...}: {
  imports = [
    ./xdg.nix
    ./nix-conf.nix
    ./fonts.nix
    ./pipewire.nix
    ./input_method.nix
    ./sys-pkgs.nix
    ./desktop-config.nix
    ./catppuccin.nix
    ./hyprland.nix
    ./flatpak.nix
  ];
  environment.sessionVariables = {
    IGPU_ADDR = "pci-0000_59_00_0";
    DGPU_ADDR = "pci-0000_03_00_0";
    SYS_THEME = "catppuccin-latte";
    # DRI_PRIME = "pci-0000_03_00_0";
  };
}
