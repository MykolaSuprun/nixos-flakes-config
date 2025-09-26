{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: {
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
      # package = pkgs.nixVersions.stable;
    };
  };
}
