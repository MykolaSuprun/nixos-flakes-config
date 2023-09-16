# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  pkgs-stable,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./../../modules/nixos/pipewire.nix
    ./../../modules/nixos/input_method.nix
    ./../../modules/nixos/fonts.nix
  ];

  nixpkgs = {
    # Add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
    ];
    config = {allowUnfree = true;};
  };

  # backup system configuration
  # system.copySystemConfiguration = true;

  # Bootloader.
  boot = {
    loader = {
      timeout = 5;
      efi = {
        efiSysMountPoint = "/boot";
        canTouchEfiVariables = true;
      };
      grub = {
        enable = true;
        efiSupport = true;
        # efiInstallAsRemovable = true;
        devices = ["nodev"];
        useOSProber = true;
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = ["wl"];
    initrd.kernelModules = ["wl"];
    extraModulePackages = [config.boot.kernelPackages.broadcom_sta];
  };

  # Script to run on wake from sleep
  powerManagement.resumeCommands = ''
    echo "This should show up in the journal after resuming."
  '';

  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    settings.auto-optimise-store = true;
    package = pkgs.nixFlakes;
    gc = {
      automatic = true;
      options = "--delete-older-than 10d";
    };
  };

  # security
  security = { 
    tpm2 = {
      enable = true;
      abrmd.enable = true;
    }; 
    pam.services.swaylock.text = ''
      # PAM configuration file for the swaylock screen locker. By default, it includes
      # the 'login' configuration file (see /etc/pam.d/login)
      auth include login
    '';
  };
  # security.tpm2.pkcs11.enable = true;

  # networking
  networking = {
    hostName = "Geks-Nixos"; # Define your hostname.
    wireless.iwd.enable = true;
    enableB43Firmware = true;
    networkmanager.enable = true;
    networkmanager.wifi.backend = "iwd";
  };

  systemd = {
    services.NetworkManager-wait-online = {
      serviceConfig = {
        ExecStart = ["" "${pkgs.networkmanager}/bin/nm-online -q"];
      };
    };
    targets = {
      sleep.enable = true;
      # suspend.enable = true;
      # wake up from hibernate is bugged atm, disable or find a slution
      hibernate.enable = true;
      hybrid-sleep.enable = false;
    };
  };

  # Set your time zone.
  time.timeZone = "Europe/Warsaw";

  # Select internationalisation properties.
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

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.desktopManager.plasma5.phononBackend = "gstreamer";
  services.xserver.desktopManager.plasma5.useQtScaling = true;
  # Remap caps-lock to esc
  services.xserver.xkbOptions = "caps:escape_shifted_capslock";
  # Enable proprietary nvidia drivers.
  services.xserver.videoDrivers = ["nvidia"];
  # Fix for NVME devices instantly waking up pc from sleep
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="pcieport", ATTR{power/wakeup}="disabled"
    ACTION=="add" SUBSYSTEM=="pci" ATTR{vendor}=="0x1022" ATTR{device}=="0x1483" ATTR{power/wakeup}="disabled"
  '';

  # hardware settings
  hardware = {
    enableAllFirmware = true;
    nvidia.open = true;
    nvidia.nvidiaSettings = true;
    nvidia.modesetting.enable = true;
    nvidia.forceFullCompositionPipeline = true;
    cpu.amd.updateMicrocode = true; # needs unfree

    opengl = {
      enable = true;
      #Enable other graphical drivers
      driSupport = true;
      driSupport32Bit = true;
      extraPackages32 = with pkgs.pkgsi686Linux; [
        libva
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        vaapiVdpau
        libvdpau-va-gl
      ];
      setLdLibraryPath = true;
    };

    bluetooth = {
      enable = true;
      settings = {General = {Enable = "Source,Sink,Media,Socket";};};
    };
    ledger.enable = true; # udev rules for ledger
  };

  # virtualization and containers
  virtualisation = {
    libvirtd.enable = true;
    libvirtd.qemu.swtpm.enable = true;
    libvirtd.qemu.ovmf.enable = true;
    kvmgt.enable = true;
    spiceUSBRedirection.enable = true;
    virtualbox.host.enable = true;
    # TODO pin version to avoid constand recompilations
    virtualbox.host.enableExtensionPack = true;
    # vmware.host.package = pkgs-stable.vmware-workstation;
    # vmware.host.enable = true;

    # Enable Podman
    podman = {
      enable = true;
      enableNvidia = true;
      dockerCompat = true;
    };
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;
  # wacom tablet server
  services.xserver.wacom.enable = true;

  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
    enableExcludeWrapper = false;
  };

  environment.shells = with pkgs; [zsh];
  users.groups.plugdev = {};
  users.extraGroups.vboxusers.members = [ "mykolas" ];
  users.defaultUserShell = pkgs.zsh;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    mykolas = {
      isNormalUser = true;
      shell = pkgs.zsh;
      description = "Mykola Suprun";
      extraGroups = ["networkmanager" "wheel" "docker" "libvirtd" "kvm" "plugdev" "gamemode"];
    };
    geks-home = {
      isNormalUser = true;
      shell = pkgs.zsh;
      description = "Geks Home";
      extraGroups = ["networkmanager" "wheel" "docker" "libvirtd" "kvm" "plugdev"];
    };
  };

  # Docker SearXNG instance (prevents sleep)
  # virtualisation.oci-containers.containers.searxng = {
  #   image = "searxng/searxng:latest";
  #   ports = ["127.0.0.1:80:8080"];
  # };

  programs = {
    zsh.enable = true;
    kdeconnect.enable = true;
    # tmux = {
    #   enable = true;
    #   terminal = "xterm-256color";
    #   escapeTime = 10;
    #   keyMode = "vi";
    #   plugins = with pkgs.tmuxPlugins; [
    #     yank
    #     resurrect
    #     continuum
    #     vim-tmux-navigator
    #     tmux-fzf
    #     better-mouse-mode
    #     fzf-tmux-url
    #     sidebar
    #     sysstat
    #   ];
    # };
    gnupg.agent.pinentryFlavor = "tty";
    gamemode = {
      enable = true;
      enableRenice = true;
    };
    hyprland = {
      enable = true;
      enableNvidiaPatches = true;
      xwayland.enable = true;
    };
  };

  # List packages installed in system profile.
  environment = {
    plasma5 = {
      excludePackages = with pkgs.libsForQt5; [elisa khelpcenter];
    };

    systemPackages = with pkgs; [
      waybar
      dunst
      libnotify
      rofi-wayland
      rofi-bluetooth
      rofi-power-menu
      networkmanagerapplet
      swww
      waypaper
      swaylock-effects

      # basic packages
      git
      gh
      helix
      wezterm
      wget
      p7zip
      rar
      xorg.xhost
      ntfs3g
      tpm2-tools
      libtpms
      swtpm
      virt-manager
      qemu
      kvmtool
      spice
      spice-gtk
      appimage-run
      x264
      x265
      wacomtablet
      libwacom
      xf86_input_wacom
      xsettingsd
      file
      wl-clipboard
      # wl-clipboard-x11
      xclip
      ncurses

      # QT and GTK themes
      plasma-overdose-kde-theme
      materia-kde-theme
      graphite-kde-theme
      arc-kde-theme
      adapta-kde-theme
      fluent-gtk-theme
      adapta-gtk-theme
      mojave-gtk-theme
      numix-gtk-theme
      whitesur-gtk-theme
      whitesur-icon-theme
      # sddm theme
      catppuccin-sddm-corners
    ];
  };

  # Enable flatpak
  services.flatpak.enable = true;
  # XDG portal
  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
        libsForQt5.xdg-desktop-portal-kde
        xdg-utils
      ];
      xdgOpenUsePortal = true;
    };
    mime.enable = true;
    menus.enable = true;
    sounds.enable = true;
    icons.enable = true;
  };

  #Flatpak fix for themes and fonts
  system.fsPackages = [pkgs.bindfs];
  fileSystems = let
    mkRoSymBind = path: {
      device = path;
      fsType = "fuse.bindfs";
      options = ["ro" "resolve-symlinks" "x-gvfs-hide"];
    };
    aggregatedFonts = pkgs.buildEnv {
      name = "system-fonts";
      paths = config.fonts.fonts;
      pathsToLink = ["/share/fonts"];
    };
  in {
    # Create an FHS mount to support flatpak host icons/fonts
    "/usr/share/icons" = mkRoSymBind (config.system.path + "/share/icons");
    "/usr/share/fonts" = mkRoSymBind (aggregatedFonts + "/share/fonts");
  };

  system.stateVersion = "23.11";
}
