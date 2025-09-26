{pkgs, ...}: {
  catppuccin = {
    enable = true;
    cache.enable = true;
    flavor = "latte";
    accent = "mauve";

    hyprland = {
      enable = true;
      flavor = "latte";
    };
    cursors = {
      enable = true;
      accent = "mauve";
    };
    fcitx5 = {
      enable = true;
      enableRounded = true;
    };
    kvantum = {
      enable = true;
      apply = true;
      flavor = "latte";
    };
    btop = {
      enable = true;
      flavor = "latte";
    };
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
  ];
}
