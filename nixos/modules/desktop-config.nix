{
  pkgs,
  pkgs-stable,
  ...
}: {
  programs = {
    steam = {
      enable = true;
      gamescopeSession.enable = true;
      gamescopeSession.args = [
        "-w 3440 -f -g -e -h 1440 -W 3440 -H 1440 --hdr-enabled"
        "--force-grab-cursor"
        "--adaptive-sync -r 165"
      ];
    };
    gamemode = {
      enable = true;
      enableRenice = true;
    };
    kdeconnect.enable = true;
    gamescope = {
      enable = true;
      # package = pkgs.gamescope-wsi;
      capSysNice = true;
    };
    firefox = {
      enable = true;
      package = pkgs.firefox;
    };
  };

  environment.systemPackages = with pkgs; [
    bazecor
    steam-run
  ];
}
