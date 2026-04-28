# NixOS-WSL system configuration for geks-wsl (minimal, no GUI).
# Feature modules (nixos/*.nix) are auto-imported by import-tree in default.nix;
# enable flags below activate them.
{
  config,
  lib,
  pkgs,
  wrappedPkgs,
  ...
}: {
  # ── Feature-module enable flags ──────────────────────────────────────────────
  myconf.nixos = {
    nixConf.enable = true;
    syspkgs.enable = true;
    catppuccin.enable = true;
  };

  # ── Theming ───────────────────────────────────────────────────────────────────
  catppuccin = {
    flavor = "latte";
    accent = "mauve";
  };

  # ── WSL ───────────────────────────────────────────────────────────────────────
  wsl.enable = true;
  wsl.defaultUser = "mykolas";

  # ── Users ─────────────────────────────────────────────────────────────────────
  users.defaultUserShell = wrappedPkgs.zsh;

  users.users = {
    mykolas = {
      isNormalUser = true;
      shell = wrappedPkgs.zsh;
      description = "Mykola Suprun";
      extraGroups = ["wheel" "docker"];
    };
  };

  # ── Programs ──────────────────────────────────────────────────────────────────
  programs = {
    fish = {
      enable = true;
      useBabelfish = true;
    };
    zsh.enable = true;
  };

  # ── System ────────────────────────────────────────────────────────────────────
  environment = {
    systemPackages = with pkgs; [
      wsl-open
    ];
  };

  networking.hostName = "geks-wsl";

  system.stateVersion = "23.11";
}
