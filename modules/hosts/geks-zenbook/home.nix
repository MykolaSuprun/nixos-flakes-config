# Home Manager configuration for mykolas on geks-zenbook (Intel laptop).
# Shared user settings: modules/users/mykolas.nix.
{inputs, ...}: {
  configurations.nixos.geks-zenbook.home = {
    pkgs,
    lib,
    ...
  }: {
    myconf = {
      shell.enable = true;
      ssh.enable = true;
      dev.enable = true;
      dev.gui.enable = true;
      dev.gpu = "intel";
      git.enable = true;
      nix-index.enable = true;
      desktop.enable = true;
      chromium.enable = true;
      catppuccin.enable = true;
      catppuccin.flavor = lib.mkDefault "mocha";
      ghostty.enable = true;
      wezterm.enable = true;
      rofi.enable = true;
      fcitx5.enable = true;
      opencode.enable = true;
      herdr.enable = true;
    };

    services.ai-gateway.enable = true;
    programs.aidev.enable = true;

    programs.noctalia.enable = true; # v5 Noctalia shell (built-in default settings)

    # herdr plugins — declarative via nix-herdr-manager (programs.herdr-hpm),
    # same setup as geks-nixos (see modules/hosts/geks-nixos/home.nix).
    programs.herdr-hpm = {
      enable = true;
      manifestChecks = ["${inputs.herdr-vimnav}/herdr-plugin.toml"];
      plugins = [
        inputs.herdr-vimnav.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };

    hyprconf = {
      noctalia.enable = true;
      hyprland.enable = true;
      hypridle.oledOptimized = true;
    };

    home.stateVersion = "25.05";
  };
}
