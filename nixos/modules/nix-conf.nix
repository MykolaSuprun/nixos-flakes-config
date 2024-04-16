{
  inputs,
  pkgs,
  ...
}: {
  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    settings.auto-optimise-store = true;
    package = pkgs.nixFlakes;
    gc = {
      automatic = true;
      options = "--delete-older-than 10d";
    };
  };
}
