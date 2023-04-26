# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ inputs, outputs, lib, config, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ] ++ outputs.nixosModules;

  nixpkgs = {
    # Add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.unstable
      outputs.overlays.additions
    ];
    config = { allowUnfree = true; };
  };

  # backup system configuration
  # system.copySystemConfiguration = true;

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelModules = [ "wl" ];
  boot.initrd.kernelModules = [ "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  # boot.extraModulePackages = with config.boot.kernelPackages; [ broadcom_sta ];

  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
    settings.auto-optimise-store = true;
    package = pkgs.nixFlakes;
  };

  # security
  security.tpm2.enable = true;
  security.tpm2.pkcs11.enable = true;
  networking.enableB43Firmware = true;

  networking.hostName = "Geks-Nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.wireless.iwd.enable = true;
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  # networking.networkmanager.wifi.backend = "wpa_supplicant";

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
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.desktopManager.plasma5.phononBackend = "vlc";
  services.xserver.desktopManager.plasma5.useQtScaling = true;
  services.xserver.desktopManager.plasma5.excludePackages =
    with pkgs.libsForQt5; [
      elisa
      khelpcenter
    ];

  # Enable proprietary nvidia drivers.
  services.xserver.videoDrivers = [ "nvidia" ];

  # hardware settings
  hardware = {
    enableAllFirmware = true;

    nvidia.nvidiaSettings = true;
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

    # pulseaudio.extraConfig = "unload-module module-role-cork"; # prevent audiostreams from stopping when another stream is started

    bluetooth = {
      enable = true;
      settings = { General = { Enable = "Source,Sink,Media,Socket"; }; };
    };
    ledger.enable = true; # udev rules for ledger
  };

  # virtualization and containers
  virtualisation = {
    libvirtd.enable = true;
    libvirtd.qemu.swtpm.enable = true;
    libvirtd.qemu.ovmf.enable = true;
    spiceUSBRedirection.enable = true;

    # Enable Docker 
    docker = {
      enable = true;
      enableOnBoot = true;
      enableNvidia = true;
    };
  };

  #Enable flatpak
  services.flatpak.enable = true;
  # XDG portal
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal
      pkgs.libsForQt5.xdg-desktop-portal-kde
      pkgs.xdg-utils
    ];
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

  environment.shells = with pkgs; [ zsh ];
  users.groups.plugdev = { };
  users.defaultUserShell = pkgs.zsh;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    mykolas = {
      isNormalUser = true;
      shell = pkgs.zsh;
      description = "Mykola Suprun";
      extraGroups =
        [ "networkmanager" "wheel" "docker" "libvirtd" "kvm" "plugdev" ];
    };
    geks-home = {
      isNormalUser = true;
      shell = pkgs.zsh;
      description = "Geks Home";
      extraGroups =
        [ "networkmanager" "wheel" "docker" "libvirtd" "kvm" "plugdev" ];
    };
  };

  # Docker SearXNG instance
  virtualisation.oci-containers.containers.searxng = {
    image = "searxng/searxng:latest";
    ports = [ "127.0.0.1:80:8080" ];
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    # basic packages
    neovim
    sublime4
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
  ];

  system.stateVersion = "22.11";

}
