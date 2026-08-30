{
  pkgs,
  lib,
  config,
  ...
}: {
  options.myconf.catppuccin = {
    enable = lib.mkEnableOption "catppuccin theming";
    flavor = lib.mkOption {
      type = lib.types.enum ["latte" "frappe" "macchiato" "mocha"];
      default = "latte";
      description = "Catppuccin color flavor to use";
    };
  };
  config = lib.mkIf config.myconf.catppuccin.enable {
    catppuccin = {
      enable = true;
      flavor = config.myconf.catppuccin.flavor;
      accent = "mauve";
      cache.enable = true;
      # Selective theming: disable autoEnable and opt-in per app
      autoEnable = false;

      hyprland = {
        enable = false;
      };
      hyprtoolkit.enable = true;
      cursors = {
        enable = true;
      };
      fcitx5 = {
        enable = true;
        enableRounded = true;
      };
      kvantum = {
        enable = true;
        apply = true;
      };
      btop = {
        enable = true;
      };
      rofi = {
        enable = true;
      };
      # Disabled: stylix.targets.gtk owns icon theming to avoid duplicate catppuccin-papirus-folders
      gtk.icon.enable = false;

      # Native catppuccin/nix modules
      kitty.enable = true;
      ghostty.enable = true;
      wezterm.enable = true;
      helix.enable = true;
      tmux.enable = true;
      waybar.enable = true;
      swaync.enable = true;
      yazi.enable = true;
      delta.enable = true;
      bat.enable = true;
      lazygit.enable = true;
    };
    qt = {
      enable = true;
      platformTheme.name = "kvantum";
      style.name = "kvantum";
    };

    gtk = {
      enable = true;
    };

    home.packages = with pkgs; [
      pkgs.catppuccin-kvantum
    ];
  };
}
