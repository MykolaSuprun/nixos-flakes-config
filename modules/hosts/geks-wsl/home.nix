# Home Manager configuration for mykolas on geks-wsl (minimal, no GUI).
# Shared user settings: modules/users/mykolas.nix.
_: {
  configurations.nixos.geks-wsl.home = {pkgs, ...}: {
    myconf = {
      shell.enable = true;
      ssh.enable = true;
      dev.enable = true;
      git.enable = true;
      nix-index.enable = true;
      catppuccin.enable = true;
      gpg.pinentry = pkgs.pinentry-tty;
    };

    home.sessionVariables.NIXOS_CONF_DIR = "$HOME/.nixconf";
    home.stateVersion = "23.11";
  };
}
