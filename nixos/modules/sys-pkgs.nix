{
  config,
  pkgs,
  my-neovim,
  ...
}: {
  console = {
    catppuccin.enable = true;
  };
  programs = {
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 14d --keep 5";
      flake = "/home/user/my-nixos-config";
    };
  };

  environment.systemPackages = with pkgs; [
    nix-output-monitor
    nvd
  ];
}
