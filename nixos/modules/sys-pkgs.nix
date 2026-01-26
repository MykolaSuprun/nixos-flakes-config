{pkgs, ...}: {
  programs = {
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 10d --keep 10";
      flake = "/home/user/my-nixos-config";
    };
  };

  environment.systemPackages = with pkgs; [
    nix-output-monitor
    nvd
    eza
    fzf
    xclip
    tree
    ripgrep
    git
    git-crypt
    gnupg
    fd
    bat
    fh
    lf
    killall
    bottom
  ];
}
