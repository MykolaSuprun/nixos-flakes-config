{
  config,
  lib,
  ...
}: {
  options.myconf.nixos.catppuccin.enable = lib.mkEnableOption "catppuccin theming for NixOS";

  config = lib.mkIf config.myconf.nixos.catppuccin.enable {
    catppuccin = {
      enable = true;
      cache.enable = true;
      grub = {
        enable = true;
        flavor = "mocha";
      };
      plymouth.enable = true;
      tty = {
        enable = true;
        # flavor = "mocha";
      };
      sddm.enable = true;
    };

    qt.style = "kvantum";

    environment.sessionVariables = {
      STYLIX_COLORSCHEME = "catppuccin-${config.catppuccin.flavor}";
    };
  };
}
