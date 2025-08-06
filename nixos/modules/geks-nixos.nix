{pkgs, ...}: {
  imports = [
    ./xdg.nix
    ./nix-conf.nix
    ./fonts.nix
    ./pipewire.nix
    ./input_method.nix
    ./sys-pkgs.nix
    ./desktop-config.nix
    ./stylix.nix
    #  ./catppuccin.nix
    ./hyprland.nix
    ./flatpak.nix
  ];

  programs = {
    ssh = {
      startAgent = true;
      enableAskPassword = true;
      askPassword = pkgs.lib.mkForce "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";
    };
  };

  environment.sessionVariables = {
    SSH_ASKPASS_REQUIRE = "prefer";
    IGPU_ADDR = "pci-0000_59_00_0";
    DGPU_ADDR = "pci-0000_03_00_0";
    SYS_THEME = "catppuccin-latte";
    # DRI_PRIME = "pci-0000_03_00_0";
  };
}
