{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: {
  options.myconf.nixos.nixConf.enable = lib.mkEnableOption "nix daemon configuration";

  config = lib.mkIf config.myconf.nixos.nixConf.enable {
    nix = {
      gc = {
        # automatic = true;
        # randomizedDelaySec = "14m";
        # options = "--delete-older-than 10d";
      };
      settings = {
        trusted-users = ["mykolas"];
        experimental-features = ["nix-command" "flakes"];
        auto-optimise-store = true;
        # Single-sourced: cache.nix at the repo root
        substituters = (import ../cache.nix).trusted-substituters;
        trusted-public-keys = (import ../cache.nix).trusted-public-keys;
      };
    };
  };
}
