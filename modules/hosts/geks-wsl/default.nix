# geks-wsl — WSL2 minimal environment.
# Host config: configuration.nix (NixOS) and home.nix (Home Manager).
_: {
  configurations.nixos.geks-wsl.home = {pkgs, ...}: {
    home.packages = [pkgs.nixconf.nix-update];
  };
}
