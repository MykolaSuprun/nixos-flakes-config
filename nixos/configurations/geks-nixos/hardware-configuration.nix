# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/hardware/network/broadcom-43xx.nix")
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = ["nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod"];
      kernelModules = ["amdgpu"];
    };
    kernelModules = ["kvm-amd" "ecryptfs"];
    extraModulePackages = [];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/676048a0-af75-451e-a38e-4d85237043a3";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/6D64-EB17";
      fsType = "vfat";
    };

    "/mnt/shared" = {
      device = "/dev/disk/by-uuid/ea91ac02-a1d0-46af-833e-908c6f5931df";
      fsType = "btrfs";
    };
  };

  swapDevices = [];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp6s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp5s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    enableAllFirmware = true;
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    opengl = {
      driSupport = true; # This is already enabled by default
      driSupport32Bit = true; # For 32 bit applications
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
        amdvlk
        libGL
        libGLU
        libglvnd
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        vaapiVdpau
        libvdpau-va-gl
      ];
      extraPackages32 = with pkgs; [
        pkgsi686Linux.libva
        pkgsi686Linux.intel-media-driver
        pkgsi686Linux.vaapiIntel
        pkgsi686Linux.vaapiVdpau
        pkgsi686Linux.libvdpau-va-gl
        driversi686Linux.amdvlk
      ];
    };

    bluetooth = {
      enable = true;
      settings = {General = {Enable = "Source,Sink,Media,Socket";};};
    };
    ledger.enable = true; # udev rules for ledger
  };
}
