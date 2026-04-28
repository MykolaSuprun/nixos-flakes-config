# NixOS system configuration for geks-nixos (AMD desktop + Hyprland + gaming).
# Hardware is imported separately via hardware.nix.
# Feature modules (nixos/*.nix) are auto-imported by import-tree in default.nix;
# enable flags below activate them.
{
  inputs,
  config,
  pkgs,
  pkgs-stable,
  wrappedPkgs,
  lib,
  ...
}: let
  # pkgs-hyprland =
  #   inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  # ── Feature-module enable flags ──────────────────────────────────────────────
  myconf.nixos = {
    nixConf.enable = true;
    fonts.enable = true;
    pipewire.enable = true;
    inputMethod.enable = true;
    syspkgs.enable = true;
    xdg.enable = true;
    catppuccin.enable = true;
    desktop.enable = true;
    # flatpak.enable = false;  # bindfs/theme Flatpak setup – zenbook only
  };

  hyprconf = {
    target = "geks-nixos";
    monitorsConf = "geks-nixos-monitors.conf";
    hyprland = {
      enable = true;
      flake.enable = true;
    };
  };

  # ── Theming ───────────────────────────────────────────────────────────────────
  catppuccin = {
    flavor = "latte";
    accent = "mauve";
  };

  # ── Boot ──────────────────────────────────────────────────────────────────────
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

    kernelPackages = pkgs.linuxPackages_zen;
    extraModulePackages = with config.boot.kernelPackages; [
      # kvmfr
    ];
    kernelModules = [
      "btintel"
      "btusb"
      # "vfio_virqfd"
      # "vfio_pci"
      # "vfio_iommu_type1"
      # "vfi"
      "kvmfr"
    ];

    # kernelParams = [ "amd_iommu=on" ];
    # extraModprobeConfig = "options vfio-pci ids=1002:164e";
    # postBootCommands = ''
    #   DEVS="0000:59:00.0"
    #   for DEV in $DEVS; do
    #     echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
    #   done
    #   modprobe -i vfio-pci
    # '';
  };

  # ── Hardware ──────────────────────────────────────────────────────────────────
  hardware = {
    enableAllFirmware = true;
    cpu.amd.updateMicrocode =
      lib.mkDefault config.hardware.enableRedistributableFirmware;

    graphics = {
      # package = pkgs-hyprland.mesa.drivers;
      # package32 = pkgs-hyprland.pkgsi686Linux.mesa.drivers;
      enable32Bit = true;
      extraPackages = with pkgs; [rocmPackages.clr.icd];
      extraPackages32 = with pkgs; [];
    };

    ledger.enable = true;
  };

  # ── Networking ────────────────────────────────────────────────────────────────
  networking = {
    hostName = "geks-nixos";
    wireless.iwd.enable = true;
    enableB43Firmware = true;
    networkmanager.enable = true;
    networkmanager.wifi.backend = "iwd";
  };

  # ── Locale ────────────────────────────────────────────────────────────────────
  time.timeZone = "Europe/Warsaw";

  i18n.defaultLocale = "en_US.UTF-8";
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

  # ── Services ──────────────────────────────────────────────────────────────────
  services = {
    tuned.enable = true;
    upower.enable = true;

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

    keyd = {
      enable = true;
      keyboards.default = {
        ids = ["046d:405b"];
        settings = {
          main = {
            capslock = "overload(control, esc)";
          };
        };
      };
    };

    resolved.enable = true;

    xserver = {
      enable = true;
      videoDrivers = ["amdgpu"];
    };

    desktopManager.plasma6 = {enable = true;};

    flatpak.enable = true;

    fprintd = {enable = true;};
    udev = {
      packages = [pkgs-stable.bazecor pkgs.bazecor];
      extraRules = ''
        SUBSYSTEM=="kvmfr", OWNER="mykolas", GROUP="kvm", MODE="0660"
      '';
    };
    spice-vdagentd.enable = true;
    spice-autorandr.enable = true;
  };

  # ── Security ──────────────────────────────────────────────────────────────────
  security = {
    pam = {
      services = {
        swaylock = {};
        hyprlock = {};
      };
    };
    polkit.enable = true;
  };

  # ── Users ─────────────────────────────────────────────────────────────────────
  users.groups.plugdev = {};
  users.extraGroups.vboxusers.members = ["mykolas"];
  users.defaultUserShell = wrappedPkgs.zsh;

  users.users = {
    mykolas = {
      isNormalUser = true;
      shell = wrappedPkgs.zsh;
      description = "Mykola Suprun";
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
        "libvirtd"
        "kvm"
        "qemu-libvirtd"
        "plugdev"
        "gamemode"
      ];
    };
  };

  # ── Virtualisation ────────────────────────────────────────────────────────────
  virtualisation = {
    docker = {
      enable = true;
      rootless.enable = true;
      enableOnBoot = true;
    };
    # podman = { ... };
    libvirtd = {
      enable = true;
      extraConfig = "";
      qemu = {
        package = pkgs-stable.qemu_kvm;
        swtpm.enable = true;
      };
    };
  };

  # ── Programs ──────────────────────────────────────────────────────────────────
  programs = {
    fish = {
      enable = true;
      useBabelfish = true;
    };
    zsh.enable = true;
    partition-manager.enable = true;
    gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-tty;
    };
    virt-manager.enable = true;
    java.enable = true;
    neovim = {
      defaultEditor = true;
      vimAlias = true;
    };
    dconf.enable = true;
    nix-ld = {
      enable = true;
      libraries = with pkgs; [libGL libGLU libglibutil];
    };
    usbtop.enable = true;
    appimage = {
      enable = true;
      binfmt = true;
    };
    ssh = {
      startAgent = true;
      enableAskPassword = true;
    };
  };

  # ── System ────────────────────────────────────────────────────────────────────
  systemd.tmpfiles.rules = ["f /dev/shm/looking-glass 0660 mykolas kvm -"];

  environment = {
    enableAllTerminfo = true;
    shells = with pkgs; [zsh fish nushell];
    variables = {
      MESA_SHADER_CACHE_MAX_SIZE = "16G";
      __GL_SHADER_DISK_CACHE_SIZE = "16G";
    };
    sessionVariables = {
      SSH_ASKPASS_REQUIRE = "prefer";
      IGPU_ADDR = "pci-0000_59_00_0";
      DGPU_ADDR = "pci-0000_03_00_0";
      SYS_THEME =
        if config.catppuccin.enable
        then "catppuccin-${config.catppuccin.flavor}"
        else "";
      LIBVIRT_DEFAULT_URI = ["qemu:///system"];
      NIXOS_OZONE_WL = "1";
    };

    systemPackages = with pkgs; [
      vscode
      bottom
      lm_sensors
      fanctl
      gperftools
      keyd
      cryptsetup
      git
      gh
      wezterm
      kitty
      wget
      p7zip
      rar
      xorg.xhost
      ntfs3g
      spice
      spice-gtk
      appimage-run
      x264
      x265
      xsettingsd
      file
      wl-clipboard
      wl-clipboard-x11
      xclip
      ncurses
      lsof
      gawk
      util-linux
      kdePackages.polkit-qt-1
      kdePackages.polkit-kde-agent-1
      tpm2-tools
      distrobox
      docker-compose
      lazydocker
    ];
  };

  system.stateVersion = "24.05";
}
