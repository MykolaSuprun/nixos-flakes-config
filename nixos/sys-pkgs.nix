{pkgs, config, lib, ...}: {
  options.myconf.nixos.syspkgs.enable = lib.mkEnableOption "system utility packages (nh, eza, fzf, etc.)";

  config = lib.mkIf config.myconf.nixos.syspkgs.enable {
  programs = {
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 10d --keep 10";
      flake = "/home/mykolas/workspaces/src/nixconf";
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
  };
}
