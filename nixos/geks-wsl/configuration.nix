{ pkgs, ... }:
{
  imports = [
  ];

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    defaultUser = "mykolas";
    startMenuLaunchers = true;
    nativeSystemd = true;

    # Enable native Docker support
    # docker-native.enable = true;

    # Enable integration with Docker Desktop (needs to be installed)
    # docker-desktop.enable = true;

  };

  environment.shells = with pkgs; [zsh];

  programs = {
    zsh.enable = true;
    gnupg.agent.pinentryFlavor = "tty";
  };

  users.users = {
    mykolas = {
      isNormalUser = true;
      shell = pkgs.zsh;
      description = "Mykola Suprun";
      extraGroups = ["networkmanager" "wheel" "docker" "libvirtd" "kvm" "plugdev"];
    };
  };

  # Enable nix flakes
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  system.stateVersion = "23.05";
}
