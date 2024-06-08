{
  pkgs,
  pkgs-stable,
  ...
}: {
  programs = {
    steam = {
      enable = true;
      gamescopeSession.enable = true;
    };
    gamemode = {
      enable = true;
      enableRenice = true;
    };
    kdeconnect.enable = true;
    gamescope = {
      enable = true;
      # capSysNice = true;
    };
    firefox = {
      enable = true;
      package = pkgs.firefox;
      # preferences = {
      #   "widget.use-xdg-desktop-portal.file-picker" = 1;
      # };
    };
  };

  environment.systemPackages = with pkgs; [
    bazecor
    steam-run
  ];
}
