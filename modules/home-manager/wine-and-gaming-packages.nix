{pkgs, ...}: {
  home.packages = with pkgs; [
    # wine, steam and other gaming related packages
    steam
    mesa
    libdrm
    wine-staging
    winetricks
    vulkan-tools
    vulkan-loader
    vulkan-extension-layer
    vkBasalt
    dxvk
    vulkan-headers
    vulkan-validation-layers
    wine64Packages.fonts
    winePackages.fonts
    gamescope
    mangohud
    heroic
    gogdl

    # media
    spotify
    vlc
    cider
  ];
}
