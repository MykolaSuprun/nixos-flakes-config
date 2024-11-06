{ pkgs, pkgs-stable, ... }: {
  programs = {
    steam = {
      enable = true;
      protontricks.enable = true;
      gamescopeSession.enable = true;
      gamescopeSession.args = [
        "-f -b -g -e --rt -w 3440 -h 1440 -W 3440 -H 1440 -r 165"
        "--hdr-enabled --force-grab-cursor --immediate-flips --mangoapp"
        "--adaptive-sync --backend=wayland --expose-wayland"
      ];
      extraPackages = [ pkgs.gamescope ];
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
    looking-glass-client
    spice
    virt-manager-qt
  ];
}
