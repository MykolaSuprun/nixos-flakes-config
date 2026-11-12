_: {
  flake.modules.homeManager.stylix = {
    lib,
    config,
    osConfig,
    ...
  }: {
    # Stylix fills in GTK window theming and apps not covered by catppuccin-nix.
    # The stylix HM options only exist when the NixOS side enables stylix (its
    # HM integration injects them), hence the structural osConfig guard.
    config = lib.optionalAttrs osConfig.myconf.nixos.stylix.enable (lib.mkIf config.myconf.catppuccin.enable {
      stylix = {
        enable = true;
        # Do not auto-theme apps — catppuccin-nix handles most of them.
        autoEnable = false;
        targets = {
          # GTK window theme — catppuccin-nix removed gtk theming in v25.05
          gtk.enable = true;
          # Zen uses the Catppuccin preset supplied by zen-browser-flake.
          zen-browser.enable = false;
          # Explicitly disable targets that catppuccin.enable = true handles globally
          ghostty.enable = false;
          fcitx5.enable = false;
          btop.enable = false;
          lazygit.enable = false;
          hyprpaper.enable = false;
        };
      };
    });
  };
}
