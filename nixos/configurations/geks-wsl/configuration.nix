# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # include NixOS-WSL modules
  ];

  wsl.enable = true;
  wsl.defaultUser = "mykolas";

  users.defaultUserShell = pkgs.fish;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    mykolas = {
      isNormalUser = true;
      shell = pkgs.fish;
      description = "Mykola Suprun";
      extraGroups = ["wheel" "docker"];
    };
  };

  programs = {
    fish = {
      enable = true;
      useBabelfish = true;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      wslu
      wsl-open
    ];
  };
  networking.hostName = "geks-wsl"; # Define your hostname.

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
