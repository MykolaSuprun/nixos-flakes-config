{
  lib,
  config,
  ...
}: {
  # Stylix fills in GTK window theming and apps not covered by catppuccin-nix.
  # Triggered by catppuccin enable — no separate option needed.
  config = lib.mkIf config.myconf.catppuccin.enable {
    stylix = {
      enable = true;
      # Do not auto-theme apps — catppuccin-nix handles most of them.
      autoEnable = false;
      targets = {
        # GTK window theme — catppuccin-nix removed gtk theming in v25.05
        gtk.enable = true;
        # zen-browser — not supported by catppuccin-nix
        zen-browser.enable = true;
        # Explicitly disable targets that catppuccin.enable = true handles globally
        ghostty.enable = false;
        fcitx5.enable = false;
        btop.enable = false;
        lazygit.enable = false;
        hyprpaper.enable = false;
        waybar.enable = false;
        kitty.enable = false;
        zellij.enable = false;
      };
    };
  };
}
