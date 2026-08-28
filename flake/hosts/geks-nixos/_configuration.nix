# NixOS system configuration for geks-nixos (AMD desktop + Hyprland + gaming).
# Hardware is imported separately via hardware.nix.
# Feature modules (nixos/*.nix) are auto-imported by import-tree in default.nix;
# enable flags below activate them.
{
  inputs,
  config,
  pkgs,
  pkgs-stable,
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
    inputMethod.enable = false;
    syspkgs.enable = true;
    xdg.enable = true;
    catppuccin.enable = true;
    desktop.enable = true;
    secrets.enable = true;
    ollama.enable = true;
    moshi-hook.enable = true;
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
      limine = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        maxGenerations = 50;
      };
    };

    plymouth.enable = true;

    # ZFS is not used on this host (ext4 + LUKS). Explicitly disabled so that
    # zfs-kernel (currently broken for linux-zen) is never pulled in — including
    # when building installer ISOs via nixos-rebuild build-image.
    supportedFilesystems.zfs = false;

    # kernelPackages = pkgs.linuxPackages_zen;
    kernelPackages = pkgs.linuxPackages;
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
    # AMD GPU suspend/resume stability: disable runtime PM (prevents GPU
    # suspend/resume crashes, hyprwm/hyprlock#953) and force deep sleep (S3)
    # instead of s2idle on this desktop.
    kernelParams = [
      "amdgpu.runpm=0"
      "mem_sleep_default=deep"
    ];
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

    i2c.enable = true;

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

  networking.firewall.trustedInterfaces = ["tailscale0"];

  # ── Services ──────────────────────────────────────────────────────────────────
  services = {
    tuned.enable = true;
    upower.enable = true;
    openssh = {
      enable = true;
    };
    greetd = {
      enable = true;
    };
    # Noctalia greeter owns greetd's default_session (see programs.noctalia-greeter below).

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

    tailscale = {
      enable = true;
      # extraUpFlags only applies with authKeyFile; extraSetFlags runs
      # `tailscale set --ssh` on every boot so Tailscale SSH stays enabled.
      extraSetFlags = ["--ssh"];
    };

    resolved.enable = true;

    xserver = {
      enable = true;
      videoDrivers = ["amdgpu"];
    };

    desktopManager.plasma6 = {enable = true;};

    flatpak.enable = true;

    # fprintd = {
    #   enable = true;
    #   tod = {
    #     enable = true;
    #     driver = pkgs.libfprint-2-tod1-elan;
    #   };
    # };
    udev = {
      packages = [pkgs-stable.bazecor pkgs.bazecor];
      extraRules = ''
        SUBSYSTEM=="kvmfr", OWNER="mykolas", GROUP="kvm", MODE="0660"
        # Permanent symlink for the Raphael iGPU
        KERNEL=="card*", KERNELS=="0000:59:00.0", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/igpu"

        # Permanent symlink for the Navi 31 dGPU (7900 XTX)
        KERNEL=="card*", KERNELS=="0000:03:00.0", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/dgpu"
      '';
    };
    spice-vdagentd.enable = true;
    spice-autorandr.enable = true;
  };

  # ── Security ──────────────────────────────────────────────────────────────────
  security = {
    pam = {
      services = {
        swaylock = {
          # fprintAuth = true;
        };
        hyprlock = {
          # fprintAuth = true;
        };
        # Auto-unlock KWallet at login so ProtonVPN (and other Secret Service
        # clients under Hyprland) retrieve credentials without an extra prompt.
        # Requires login password == kdewallet password. pam_kwallet_init,
        # run as a Hyprland systemd oneshot (settings.nix), consumes the
        # PAM_KWALLET5_LOGIN token this injects. Plasma handles its own unlock.
        greetd.kwallet = {
          enable = true;
          package = pkgs.kdePackages.kwallet-pam;
        };
        # login.fprintAuth = true;
        # sudo.fprintAuth = true;
        # greetd.fprintAuth = true; # Enforces fingerprint fallback at the DM stage
      };
    };
    polkit.enable = true;
    # Allow wheel users to lock their own session via loginctl without a password
    # dialog. This is required for session_lock to work from terminals and keybinds
    # when DMS or any other session-lock utility calls loginctl.
    polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id === "org.freedesktop.login1.lock-session" &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';
  };

  # ── Users ─────────────────────────────────────────────────────────────────────
  users.groups.plugdev = {};
  users.extraGroups.vboxusers.members = ["mykolas"];
  users.defaultUserShell = pkgs.zsh;

  users.mutableUsers = true; # passwords set via passwd; initialPassword is only used on first user creation
  users.users.root.initialPassword = "nixos";

  users.users = {
    mykolas = {
      isNormalUser = true;
      initialPassword = "nixos";
      shell = pkgs.zsh;
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
        "input"
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
    noctalia-greeter.enable = true; # Noctalia login greeter
    partition-manager.enable = true;
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
    # SSH agent is handled by HM's gpg-agent with enableSshSupport.
    # The NixOS ssh-agent is disabled to avoid conflicting SSH_AUTH_SOCK values.
    ssh = {
      startAgent = false;
      enableAskPassword = false;
    };
    mosh = {
      enable = true;
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
      xhost
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
