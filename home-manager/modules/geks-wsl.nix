{
  pkgs,
  pkgs-stable,
  ...
}: {
  home.sessionVariables = {
    NIXOS_CONF_DIR = "$HOME/.nixconf";
    NIXOS_TARGET = "geks-wsl";
    FLAKE = "/home/mykolas/.nixconf";
  };
}
