{
  pkgs,
  pkgs-stable,
  ...
}: {
  imports = [
    ./shell.nix
    ./tmux.nix
    ./dev-pkgs.nix
    ./catppuccin.nix
  ];

  home.sessionVariables = {
    NIXOS_CONF_DIR = "$HOME/.nixconf";
    NIXOS_TARGET = "geks-wsl";
    NH_FLAKE = "/home/mykolas/.nixconf";
  };
}
