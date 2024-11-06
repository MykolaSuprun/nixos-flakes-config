{pkgs, ...}: {
  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    settings.auto-optimise-store = true;
    package = pkgs.nixVersions.stable;
  };
}
