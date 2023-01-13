 # Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

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


  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
    settings.auto-optimise-store = true;
    package = pkgs.nixFlakes;
  };




  # security
  security.tpm2.enable = true;
  # security.tpm2.abrmd.enable = true;
  security.tpm2.pkcs11.enable = true;

  networking.hostName = "Geks-Nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

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
  services.xserver.desktopManager.plasma5.excludePackages = with pkgs.libsForQt5; [
    elisa
    khelpcenter
  ];

  # Enable proprietary nvidia drivers.
  services.xserver.videoDrivers = [ "nvidia" ];

  # hardware settings
  hardware = {
    enableAllFirmware = true;

    nvidia.nvidiaSettings = true;
    cpu.amd.updateMicrocode = true; #needs unfree

    opengl = {
      enable = true;
      #Enable other graphical drivers
      driSupport = true;
      driSupport32Bit = true;
      extraPackages32 = with pkgs.pkgsi686Linux; [libva];
      setLdLibraryPath = true;
    };

    bluetooth = {
      enable = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
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


  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx.engines = with pkgs.fcitx-engines; [ mozc hangul m17n unikey table-other rime ];
    fcitx5.addons = with pkgs; [ 
      fcitx5-rime 
      fcitx5-gtk 
      libsForQt5.fcitx5-qt 
      fcitx5-with-addons
      fcitx5-chinese-addons
      fcitx5-table-other
      fcitx5-configtool
      fcitx5-hangul
      fcitx5-unikey
      fcitx5-m17n
      fcitx5-mozc
    ];
  };


  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
 
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.mykolas = {
    isNormalUser = true;
    description = "Mykola Suprun";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # basic packages
    neovim
    wget
    sublime4
    p7zip
    rar
    xorg.xhost
    ntfs3g
    tpm2-tools
    libtpms
    swtpm

    #fcitx
    libsForQt5.fcitx-qt5
    fcitx-configtool
    librime
    libhangul
    rime-data
    vimPlugins.fcitx-vim
    fcitx5-gtk

    # plasma packages
    libsForQt5.sddm-kcm
    libsForQt5.ark
    libsForQt5.yakuake
  ];


  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    inconsolata
  ];
  fonts.fontDir.enable = true;


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}
