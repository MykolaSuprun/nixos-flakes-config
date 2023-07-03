{ config, pkgs, lib }:

{ 
environment.systemPackages = with pkgs; [
    (pkgs.buildFHSUserEnv {
    name = "fhs";
    targetPkgs = pkgs: (with pkgs;
      [
        pkg-config
        ncurses
      ]) ++ (with pkgs.xorg;
      [ libX11
        libXcursor
        libXrandr
      ]) ++ (pkgs.appimageTools.defaultFhsEnvArgs.targetPkgs pkgs);
    profile = "export FHS=1"; 
    runScript = "zsh";
    extraOutputsToInstall = ["dev"];
    }) 
  ];
}
