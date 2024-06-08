# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  inputs,
  config,
  pkgs,
  pkgs-stable,
  my-neovim,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
  ];

  # nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = ["mykolas"];
  # Bootloader.
  boot = {
    initrd.luks.devices."luks-16267be4-338a-4125-9e7f-ec112f3e166e".device = "/dev/disk/by-uuid/16267be4-338a-4125-9e7f-ec112f3e166e";
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

    # kernelPackages = pkgs.linuxPackages_zen;
    # kernelPackages = pkgs.linuxPackages_latest;
    kernelPackages = pkgs.linuxPackages;
    kernelModules = ["wl" "ecryptfs"];
    initrd.kernelModules = ["wl"];
    extraModulePackages = [config.boot.kernelPackages.broadcom_sta];
  };

  # networking
  networking = {
    hostName = "geks-nixos"; # Define your hostname.
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
    displayManager = {
      # defaultSession = "hyprland";
      sddm = {
        enable = true;
        wayland = {
          enable = true;
          # compositor = "kwin";
        };
        extraPackages = [
        ];
        # enableHidpi = true;
      };
    };
    xserver = {
      enable = false;
      videoDrivers = ["amdgpu"];

      # Enable the KDE Plasma Desktop Environment.
    };

    desktopManager.plasma6 = {
      enable = true;
    };

    flatpak.enable = true;

    fprintd = {
      # enable = true;
    };
    udev = {
      packages = [
        pkgs-stable.bazecor
      ];
    };
  };

  security = {
    pam = {
      enableEcryptfs = true;
      services = {
        # allow swaylock to unlock sessions
        swaylock = {};
        hyprlock = {};
      };
    };
    polkit.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  users.groups.plugdev = {};
  users.extraGroups.vboxusers.members = ["mykolas"];
  users.defaultUserShell = pkgs.fish;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    mykolas = {
      isNormalUser = true;
      shell = pkgs.fish;
      description = "Mykola Suprun";
      extraGroups = ["networkmanager" "wheel" "docker" "libvirtd" "kvm" "qemu-libvirtd" "plugdev" "gamemode"];
    };
    geks-home = {
      isNormalUser = true;
      shell = pkgs.fish;
      description = "Geks Home";
      extraGroups = ["networkmanager" "wheel" "docker" "libvirtd" "kvm" "plugdev"];
    };
  };

  virtualisation = {
    # libvirtd = {
    #   enable = true;
    #   qemu = {
    #     ovmf.enable = true;
    #     swtpm.enable = true;
    #   };
    # };
    # spiceUSBRedirection.enable = true;

    # disable vmware for now
    # vmware = {
    #   host.enable = true;
    #   host.extraPackages = with pkgs; [];
    # };
    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  programs = {
    fish = {
      enable = true;
      useBabelfish = true;
    };
    ecryptfs.enable = true;
    partition-manager.enable = true;
    gnupg.agent = {
      enable = true;
      # pinentryPackage = pkgs.pinentry-tty;
    };
    virt-manager.enable = true;
    java.enable = true;
    neovim = {
      defaultEditor = true;
      vimAlias = true;
    };
    dconf.enable = true;
    # nix-ld = {
    #   enable = true;
    #   libraries = with pkgs; [
    #     libglvnd
    #   ];
    # };
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  };

  # List packages installed in system profile.

  # List packages installed in system profile. To search, run:
  environment = {
    shells = with pkgs; [fish];

    sessionVariables = {
      LIBVIRT_DEFAULT_URI = ["qemu:///system"];
      NIXOS_OZONE_WL = "1";
    };

    systemPackages = with pkgs; [
      # dev tools
      my-neovim.packages.${system}.default
      vscode
      lazygit
      bottom

      # basic packages
      ecryptfs
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
      # wacomtablet
      # libwacom
      # xf86_input_wacom
      xsettingsd
      file
      wl-clipboard
      # wl-clipboard-x11
      xclip
      ncurses
      lsof
      gawk
      util-linux
      kdePackages.polkit-qt-1
      kdePackages.polkit-kde-agent-1

      #virtualisation
      libtpms
      virt-manager
      win-virtio
      qemu
      kvmtool
      tpm2-tools
      distrobox
      podman-compose

      # plasma
    ];
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
        # plasma-overdose-kde-theme
        # materia-kde-theme
        # graphite-kde-theme
        # arc-kde-theme
        # adapta-kde-theme
        # fluent-gtk-theme
        # adapta-gtk-theme
        # mojave-gtk-theme
        # numix-gtk-theme
        # whitesur-kde
        # whitesur-gtk-theme
        # whitesur-icon-theme
        # whitesur-cursors
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

  system.stateVersion = "24.05"; # Did you read the comment?
}
