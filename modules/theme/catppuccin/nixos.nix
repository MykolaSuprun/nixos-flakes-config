{inputs, ...}: {
  flake.modules.nixos.catppuccin = {
    config,
    lib,
    ...
  }: {
    imports = [inputs.catppuccin.nixosModules.catppuccin];
    options.myconf.nixos.catppuccin.enable = lib.mkEnableOption "catppuccin theming for NixOS";

    config = lib.mkIf config.myconf.nixos.catppuccin.enable {
      catppuccin = {
        enable = true;
        cache.enable = true;
        grub = {
          enable = true;
          flavor = config.catppuccin.flavor;
        };
        plymouth.enable = true;
        tty = {
          enable = true;
          flavor = config.catppuccin.flavor;
        };
        sddm.enable = true;
      };

      qt.style = "kvantum";

      environment.sessionVariables = {
        STYLIX_COLORSCHEME = "catppuccin-${config.catppuccin.flavor}";
      };
    };
  };
}
