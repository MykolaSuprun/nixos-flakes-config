{ inputs, config, pkgs, pkgs-stable, lib, my-neovim, ... }:
let
  pkgs-hyprland =
    inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [ ];

  nix = {
    settings.trusted-users = [ "mykolas" ];
    gc = {
      # automatic = true;
      randomizedDelaySec = "14m";
      options = "--delete-older-than 10d";
    };
  };

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
        devices = [ "nodev" ];
        useOSProber = true;
      };
    };

    plymouth.enable = true;

    kernelPackages = pkgs.linuxPackages_zen;
    extraModulePackages = with config.boot.kernelPackages;
      [
        # kvmfr
      ];
    kernelModules = [
      "ecryptfs"
      "btintel"
      "btusb"
      "vfio_virqfd"
      "vfio_pci"
      "vfio_iommu_type1"
      "vfi"
      "kvmfr"
    ];
    initrd = {
      # kernelModules = ["wl"];
      luks.devices."luks-b6082ebc-6403-4f61-9a2b-fce8c51233e6".device =
        "/dev/disk/by-uuid/b6082ebc-6403-4f61-9a2b-fce8c51233e6";
    };
    kernelParams = [ "amd_iommu=on" ];
    extraModprobeConfig = "options vfio-pci ids=1002:164e";
    postBootCommands = ''
      DEVS="0000:59:00.0"

      for DEV in $DEVS; do
        echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
      done
      modprobe -i vfio-pci
    '';
  };

  hardware = {
    enableAllFirmware = true;
    cpu.amd.updateMicrocode =
      lib.mkDefault config.hardware.enableRedistributableFirmware;

    graphics = {
      package = pkgs-hyprland.mesa.drivers;
      package32 = pkgs-hyprland.pkgsi686Linux.mesa.drivers;
      enable32Bit = true; # For 32 bit applications
      extraPackages = with pkgs; [ rocmPackages.clr.icd ];
      extraPackages32 = with pkgs; [ ];
    };

    ledger.enable = true; # udev rules for ledger
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
      defaultSession = "hyprland";
      sddm = {
        enable = true;
        wayland = {
          enable = true;
          # compositor = "kwin";
        };
        extraPackages = [ ];
      };
    };
    xserver = {
      enable = false;
      videoDrivers = [ "amdgpu" ];
    };

    # Enable the KDE Plasma Desktop Environment.
    desktopManager.plasma6 = { enable = true; };

    flatpak.enable = true;

    fprintd = { enable = true; };
    udev = {
      packages = [ pkgs.bazecor ];
      extraRules = ''
        SUBSYSTEM=="kvmfr", OWNER="mykolas", GROUP="kvm", MODE="0660"
      '';
    };
    spice-vdagentd.enable = true;
    spice-autorandr.enable = true;
  };

  security = {
    pam = {
      enableEcryptfs = true;
      krb5.enable = true;
      services = {
        # allow swaylock to unlock sessions
        swaylock = { };
        hyprlock = { };
      };
    };
    krb5 = {
      enable = true;
      package = pkgs-stable.krb5;
    };
    polkit.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  users.groups.plugdev = { };
  users.extraGroups.vboxusers.members = [ "mykolas" ];
  users.defaultUserShell = pkgs.fish;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    mykolas = {
      isNormalUser = true;
      shell = pkgs.fish;
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
    geks-home = {
      isNormalUser = true;
      shell = pkgs.fish;
      description = "Geks Home";
      extraGroups =
        [ "networkmanager" "wheel" "docker" "libvirtd" "kvm" "plugdev" ];
    };
  };

  virtualisation = {
    docker = {
      enable = true;
      rootless.enable = true;
      enableOnBoot = true;
    };
    # podman = {
    #   enable = true;
    #   dockerCompat = true;
    #   dockerSocket.enable = true;
    #   defaultNetwork.settings.dns_enabled = true;
    #   extraOptions = "--iptables=False";
    # };
    libvirtd = {
      enable = true;
      extraConfig = "";
      qemu = {
        package = pkgs-stable.qemu_kvm;
        swtpm.enable = true;
        ovmf.enable = true;
      };
    };
  };

  programs = {
    fish = {
      enable = true;
      useBabelfish = true;
    };
    ecryptfs.enable = true;
    partition-manager.enable = true;
    gnupg.agent = { enable = true; };
    virt-manager.enable = true;
    java.enable = true;
    neovim = {
      defaultEditor = true;
      vimAlias = true;
    };
    dconf.enable = true;
    nix-ld = {
      enable = true;
      libraries = with pkgs; [ libGL libGLU libglibutil ];
    };
  };

  systemd.tmpfiles.rules = [ "f /dev/shm/looking-glass 0660 mykolas kvm -" ];

  environment = {
    shells = with pkgs; [ fish ];

    sessionVariables = {
      LIBVIRT_DEFAULT_URI = [ "qemu:///system" ];
      NIXOS_OZONE_WL = "1";
    };

    systemPackages = with pkgs; [
      # dev tools
      my-neovim.packages.${system}.default
      vscode
      lazygit
      bottom

      # sensors, fan control, etc
      lm_sensors
      fanctl

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

      tpm2-tools
      distrobox
      docker-compose
      lazydocker
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

  system.fsPackages = [ pkgs.bindfs ];
  fileSystems = let
    mkRoSymBind = path: {
      device = path;
      fsType = "fuse.bindfs";
      options = [ "ro" "resolve-symlinks" "x-gvfs-hide" ];
    };
    aggregatedIcons = pkgs.buildEnv {
      name = "system-icons";
      paths = with pkgs; [ ];
      pathsToLink = [ "/share/icons" ];
    };
    aggregatedFonts = pkgs.buildEnv {
      name = "system-fonts";
      paths = config.fonts.packages;
      pathsToLink = [ "/share/fonts" ];
    };
  in {
    "/usr/share/icons" = mkRoSymBind "${aggregatedIcons}/share/icons";
    "/usr/local/share/fonts" = mkRoSymBind "${aggregatedFonts}/share/fonts";
  };

  system.stateVersion = "24.05"; # Did you read the comment?
}
