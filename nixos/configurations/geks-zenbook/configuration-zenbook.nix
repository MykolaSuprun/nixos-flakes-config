{
  inputs,
  config,
  pkgs,
  pkgs-stable,
  wrappedPkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration-zenbook.nix
  ];

  boot.initrd.luks.devices."luks-585372bc-c88f-4e15-ada1-9bca0c43bd29".device = "/dev/disk/by-uuid/585372bc-c88f-4e15-ada1-9bca0c43bd29";

  hardware.enableAllFirmware = true;

  boot = {
    loader = {
      systemd-boot.enable = false;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      grub = {
        enable = true;
        efiSupport = true;
        devices = ["nodev"];
        useOSProber = true;
        memtest86.enable = true;
        configurationLimit = 50;
      };
    };
    plymouth.enable = true;
  };

  networking.hostName = "geks-zenbook";

  networking = {
    networkmanager = {
      enable = true;
      wifi.powersave = true;
    };
  };

  time.timeZone = "Europe/Warsaw";

  i18n.defaultLocale = "en_IE.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IE.UTF-8";
    LC_IDENTIFICATION = "en_IE.UTF-8";
    LC_MEASUREMENT = "en_IE.UTF-8";
    LC_MONETARY = "en_IE.UTF-8";
    LC_NAME = "en_IE.UTF-8";
    LC_NUMERIC = "en_IE.UTF-8";
    LC_PAPER = "en_IE.UTF-8";
    LC_TELEPHONE = "en_IE.UTF-8";
    LC_TIME = "en_IE.UTF-8";
  };

  # Display manager - sysc-greet with Hyprland
  services = {
    greetd = {
      enable = true;
      useTextGreeter = true;
    };
    sysc-greet = {
      enable = true;
      compositor = "hyprland";
      settings = {
        terminal = {
          vt = 1;
        };
      };
    };

    xserver.xkb = {
      layout = "us";
      variant = "";
    };

    keyd = {
      enable = true;
      keyboards.default = {
        ids = ["0001:0001"];
        settings = {
          main = {
            capslock = "overload(control, esc)";
          };
        };
      };
    };

    printing.enable = true;

    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  security = {
    rtkit.enable = true;
    pam.services = {
      swaylock = {};
      hyprlock = {};
    };
    polkit.enable = true;
  };

  users.defaultUserShell = wrappedPkgs.zsh;

  users.users.mykolas = {
    isNormalUser = true;
    description = "Mykola Suprun";
    shell = wrappedPkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "kvm"
      "qemu-libvirtd"
      "plugdev"
      "gamemode"
    ];
  };

  programs = {
    fish = {
      enable = true;
      useBabelfish = true;
    };
    zsh.enable = true;
    appimage = {
      enable = true;
      binfmt = true;
    };
    gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-tty;
    };
    neovim = {
      defaultEditor = true;
      vimAlias = true;
    };
    dconf.enable = true;
  };

  environment = {
    enableAllTerminfo = true;
    shells = with pkgs; [zsh fish nushell];
    systemPackages = with pkgs; [
      keyd
      brightnessctl
    ];
  };

  system.stateVersion = "25.05";
}
