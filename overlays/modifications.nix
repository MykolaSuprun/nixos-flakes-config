# This file defines overlays
{ inputs, pkgs-unstable, ... }: {

  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays

  home_modifications = final: prev: {
    steam = (pkgs-unstable.pkgs.steam.override {
      extraPkgs = pkgs-unstable: with pkgs-unstable; [ pango harfbuzz libthai ];
    });
    discord = pkgs-unstable.discord.override { withOpenASAR = true; };
  };
}
