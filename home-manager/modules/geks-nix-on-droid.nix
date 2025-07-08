{pkgs, ...}: {
  imports = [
    ./shell.nix
    ./tmux.nix
  ];

  home.sessionVariables = {
    NIXOS_CONF_DIR = "$HOME/.nixconf";
    NIXOS_TARGET = "nix-on-droid";
    # FLAKE = "/home/mykolas/.nixconf";
    # BROWSER = "${pkgs.vivaldi}/bin/vivaldi";
    # DEFAULT_BROWSER = "${pkgs.vivaldi}/bin/vivaldi";
  };
}
