# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  inputs,
  config,
  pkgs,
  my-neovim,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./../../modules/fonts.nix
    ./../../modules/input_method.nix
    ./../../modules/desktop-packages.nix
  ];

  # nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot = {
    loader = {
      systemd-boot.enable = false;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot"; # ← use the same mount point here.
      };
      grub = {
        enable = true;
        efiSupport = true;
        #efiInstallAsRemovable = true; # in case canTouchEfiVariables doesn't work for your system
        devices = ["nodev"];
        useOSProber = true;
      };
    };

    kernelPackages = pkgs.linuxPackages_zen;
    kernelModules = ["wl" "ecryptfs"];
    initrd.kernelModules = ["wl"];
    extraModulePackages = [config.boot.kernelPackages.broadcom_sta];
  };

  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    settings.auto-optimise-store = true;
    package = pkgs.nixFlakes;
    gc = {
      automatic = true;
      options = "--delete-older-than 10d";
    };
  };

  # networking
  networking = {
    hostName = "Geks-Nixos"; # Define your hostname.
    wireless.iwd.enable = true;
    enableB43Firmware = true;
    networkmanager.enable = true;
    networkmanager.wifi.backend = "iwd";
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

  # Enable the X11 windowing system.
  services = {
    xserver = {
      enable = true;
      videoDrivers = ["amdgpu"];

      # Enable the KDE Plasma Desktop Environment.
      displayManager.defaultSession = "plasmawayland";
      desktopManager.plasma5 = {
        enable = true;
        phononBackend = "vlc";
        useQtScaling = true;
      };

      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        enableHidpi = true;
        theme = "catppuccin-sddm-corners";
      };
      xkbOptions = "caps:swapescape";
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    flatpak.enable = true;

    fprintd = {
      enable = true;
    };
  };

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security = {
    rtkit.enable = true;
    pam = {
      enableEcryptfs = true;
    };
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  users.groups.plugdev = {};
  users.extraGroups.vboxusers.members = ["mykolas"];
  users.defaultUserShell = pkgs.zsh;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    mykolas = {
      isNormalUser = true;
      shell = pkgs.zsh;
      description = "Mykola Suprun";
      extraGroups = ["networkmanager" "wheel" "docker" "libvirtd" "kvm" "qemu-libvirtd" "plugdev" "gamemode"];
    };
    geks-home = {
      isNormalUser = true;
      shell = pkgs.zsh;
      description = "Geks Home";
      extraGroups = ["networkmanager" "wheel" "docker" "libvirtd" "kvm" "plugdev"];
    };
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        ovmf.enable = true;
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
    vmware = {
      host.enable = true;
      host.extraPackages = with pkgs; [];
    };
  };

  programs = {
    zsh.enable = true;
    ecryptfs.enable = true;
    gnupg.agent.pinentryFlavor = "tty";
    virt-manager.enable = true;
    java.enable = true;
    neovim = {
      defaultEditor = true;
      vimAlias = true;
    };
    hyprland = {
      enable = true;
      package = inputs.hyprland.packages."${pkgs.system}".hyprland;
      portalPackage = inputs.hyprland.packages."${pkgs.system}".xdg-desktop-portal-hyprland;
      xwayland.enable = true;
    };
  };

  # List packages installed in system profile.

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    shells = with pkgs; [zsh];
    sessionVariables = {
      LIBVIRT_DEFAULT_URI = ["qemu:///system"];
      NIXOS_OZONE_WL = "1";
    };

    systemPackages = with pkgs; [
      # dev tools
      my-neovim.packages.${system}.default
      sublime4
      vscode
      lazygit

      libGL
      libGLU
      libglvnd

      # basic packages
      ecryptfs
      git
      gh
      helix
      wezterm
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
      wacomtablet
      libwacom
      xf86_input_wacom
      xsettingsd
      file
      wl-clipboard
      # wl-clipboard-x11
      xclip
      ncurses

      #virtualisation
      libtpms
      virt-manager
      win-virtio
      qemu
      kvmtool
      tpm2-tools
    ];
  };

  # XDG portal
  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        inputs.hyprland.packages."${pkgs.system}".xdg-desktop-portal-hyprland
        libsForQt5.xdg-desktop-portal-kde
      ];
      xdgOpenUsePortal = true;
    };
    mime.enable = true;
    menus.enable = true;
    sounds.enable = true;
    icons.enable = true;
    autostart.enable = true;
  };

  #Flatpak fix for themes and fonts
  # system.fsPackages = [pkgs.bindfs];
  # fileSystems = let
  #   mkRoSymBind = path: {
  #     device = path;
  #     fsType = "fuse.bindfs";
  #     options = ["ro" "resolve-symlinks" "x-gvfs-hide"];
  #   };
  #   aggregatedFonts = pkgs.buildEnv {
  #     name = "system-fonts";
  #     paths = config.fonts.packages;
  #     pathsToLink = ["/share/fonts"];
  #   };
  # in {
  #   # Create an FHS mount to support flatpak host icons/fonts
  #   "/usr/share/icons" = mkRoSymBind (config.system.path + "/share/icons");
  #   "/usr/share/fonts" = mkRoSymBind (aggregatedFonts + "/share/fonts");
  # };
  #

  system.fsPackages = [pkgs.bindfs];
  fileSystems = let
    mkRoSymBind = path: {
      device = path;
      fsType = "fuse.bindfs";
      options = ["ro" "resolve-symlinks" "x-gvfs-hide"];
    };
    aggregatedIcons = pkgs.buildEnv {
      name = "system-icons";
      paths = with pkgs; [
        libsForQt5.breeze-qt5 # for plasma
        plasma-overdose-kde-theme
        materia-kde-theme
        graphite-kde-theme
        arc-kde-theme
        adapta-kde-theme
        fluent-gtk-theme
        adapta-gtk-theme
        mojave-gtk-theme
        numix-gtk-theme
        whitesur-kde
        whitesur-gtk-theme
        whitesur-icon-theme
        whitesur-cursors
        # gnome.gnome-themes-extra
      ];
      pathsToLink = ["/share/icons"];
    };
    aggregatedFonts = pkgs.buildEnv {
      name = "system-fonts";
      paths = config.fonts.packages;
      pathsToLink = ["/share/fonts"];
    };
  in {
    "/usr/share/icons" = mkRoSymBind "${aggregatedIcons}/share/icons";
    "/usr/local/share/fonts" = mkRoSymBind "${aggregatedFonts}/share/fonts";
  };

  system.stateVersion = "23.11"; # Did you read the comment?
}
