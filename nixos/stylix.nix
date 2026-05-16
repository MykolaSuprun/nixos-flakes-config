{
  pkgs,
  lib,
  config,
  ...
}: {
  # Stylix provides fonts and NixOS-level theming that catppuccin-nix doesn't cover.
  # Triggered by catppuccin enable — no separate enable option needed.
  config = lib.mkIf config.myconf.nixos.catppuccin.enable {
    stylix = {
      enable = true;
      # Mirror catppuccin flavor: base16-schemes has catppuccin-{latte,frappe,macchiato,mocha}.yaml
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-${config.catppuccin.flavor}.yaml";
      # Wallpaper: only latte and mocha variants exist in the wallpapers dir.
      # Both hosts use catppuccin.flavor = "latte".
      image = ../home-manager/users/mykolas/config/wallpapers/catppuccin/latte/forrest.png;
      # Do not auto-theme apps — catppuccin-nix handles most of them.
      autoEnable = false;
      fonts = {
        serif = {
          package = pkgs.noto-fonts;
          name = "Noto Serif";
        };
        sansSerif = {
          package = pkgs.noto-fonts;
          name = "Noto Sans";
        };
        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrainsMono Nerd Font";
        };
        emoji = {
          package = pkgs.noto-fonts-emoji;
          name = "Noto Color Emoji";
        };
        sizes = {
          applications = 10;
          desktop = 10;
          terminal = 10;
        };
      };
      targets = {
        # catppuccin-nix handles Qt via kvantum
        qt.enable = false;
        nixos-icons.enable = true;
      };
    };
  };
}
