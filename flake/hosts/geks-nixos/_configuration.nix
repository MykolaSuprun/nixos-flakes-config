# NixOS system configuration for geks-nixos (AMD desktop + Hyprland + gaming).
# Feature modules (nixos/*.nix) are hand-listed in the host's default.nix
# (import-tree is NOT used for them); enable flags below activate them.
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
    # fcitx5 is HM-owned only (home-manager/modules/fcitx5.nix) — the NixOS-side
    # module was removed (dual daemon/config conflict).
    syspkgs.enable = true;
    xdg.enable = true;
    catppuccin.enable = true;
    desktop.enable = true;
    secrets.enable = true;
    ollama.enable = true;
    moshi-hook.enable = true;
    # Lian Li HydroShift LCD 360R (HSLCD36RW) + UNI FAN SL V2 hub: fan curves,
    # pump, ARGB, 480x480 LCD streaming via lian-li-linux (udev + user daemon).
    lianli.enable = true;
    # btrfs dedup (bees) — 2026-09-11 storage baseline, see
    # task_backlog/storage_backlog.md. 2GB mlocked hash table, 4 workers,
    # loadavg ceiling 4 (polite defaults; 16/16 HOT during the 2026-09-12
    # initial crawl, reverted on settlement).
    bees.enable = true;
    bees.hashTableSizeMB = 2048;
    # flatpak.enable = false;  # bindfs/theme Flatpak setup – zenbook only
  };

  # ── Swap ────────────────────────────────────────────────────────────────────
  # Layered swap: zram first (fast, compressed RAM), loop-backed disk file as
  # the deep overflow. A PLAIN btrfs swapfile is kernel-forbidden here — the
  # pool spans 2 devices (2026-09-15, gen 207: "swapfile must be on one
  # device") — so the 64G NOCOW file is attached with `losetup --direct-io=on`
  # and the kernel swaps on the loop BLOCK device, which carries no such
  # restriction. Priority zram 100 > file 10: pressure lands on zram first,
  # the file catches true overflow.
  # One-time file setup (sudo):
  #   mkdir -p /var/swap && chattr +C /var/swap
  #   dd if=/dev/zero of=/var/swap/swapfile bs=1M count=65536 status=progress
  #   chmod 600 /var/swap/swapfile && mkswap /var/swap/swapfile
  # (+C on the dir → file is NOCOW/uncompressed, no CoW overhead under swap
  # IO.) Service fails soft: a missing file never blocks boot. Hibernation
  # NOT wired (a loop swap cannot resume — accepted).
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
    priority = 100;
  };

  systemd.services.swap-loopfile = let
    util = pkgs.util-linux;
    file = "/var/swap/swapfile";
  in {
    description = "Swap on a loop-backed btrfs file (multi-device pool forbids plain swapfiles)";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    unitConfig.RequiresMountsFor = [ "/var/swap" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "swap-loopfile-up" ''
        PATH=${pkgs.coreutils}/bin:${util}/bin:${pkgs.gnugrep}/bin
        if [ ! -f "${file}" ]; then
          echo "swap-loopfile: ${file} missing — create it once (see host _configuration.nix)" >&2
          exit 1
        fi
        dev=$(losetup -j "${file}" -n --output NAME 2>/dev/null | head -n1)
        if [ -z "$dev" ]; then
          dev=$(losetup -f --show --direct-io=on "${file}")
        fi
        if ! grep -qs "^$dev " /proc/swaps; then
          swapon -p 10 "$dev"
        fi
      '';
      ExecStop = pkgs.writeShellScript "swap-loopfile-down" ''
        PATH=${pkgs.coreutils}/bin:${util}/bin:${pkgs.gnugrep}/bin
        dev=$(losetup -j "${file}" -n --output NAME 2>/dev/null | head -n1)
        if [ -n "$dev" ]; then
          swapoff "$dev" 2>/dev/null || true
          losetup -d "$dev" 2>/dev/null || true
        fi
      '';
    };
  };

  hyprconf = {
    target = "geks-nixos";
    hyprland.enable = true;
  };

  # ── Theming ───────────────────────────────────────────────────────────────────
  catppuccin = {
    flavor = lib.mkDefault "latte";
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
        # Sized from a MEASURED per-generation footprint — not a guess.
        # 2026-10-16 ENOSPC on switch (kernel 6.18.55 -> 6.18.56): the
        # "~10-15M per kernel+initrd" this line was originally based on was
        # ~12x too small. Measured reality on this host:
        #   kernel bzImage                                    13.2 MiB
        #   initrd x4 (one per Catppuccin specialisation)    148.8 MiB  (37.2 each)
        #   ----------------------------------------------------------
        #   PER GENERATION                                    162.0 MiB
        # The 4x multiplier is the specialisations in nixos/specialisations.nix:
        # each is its own toplevel, so each gets its own 37 MiB initrd.
        # The kernel is shared and deduped by store path.
        #
        # limine's installer COPIES NEW FILES BEFORE PRUNING OLD ONES, so the
        # ESP must transiently hold (maxGenerations + 1) generations.
        # On the 511 MiB ESP that means:
        #   maxGenerations=2 -> 486 MiB transient  (fits, ~10 MiB headroom)
        #   maxGenerations=5 -> 972 MiB transient  DO NOT REACH THIS STATE
        # This cap is therefore NOT self-enforcing: it only bounds how many
        # generations limine will *write*, and any value above 2 cannot fit.
        # Safety comes from keeping the profile pruned to ~2 generations:
        #   nix-env --delete-generations <old...> -p /nix/var/nix/profiles/system
        #   sudo nix-collect-garbage -d
        # plus deleting unreferenced files in /boot/limine/kernels (the prune
        # step only runs after a SUCCESSFUL install, so it never fires while
        # you are out of space).
        #
        # Re-measure before changing:
        #   du -sh /boot/limine/kernels ; df -h /boot
        maxGenerations = 5;
      };
    };

    # zram-first layering reclaim tuning (Fedora zram-generator guidance; the
    # NixOS zram module sets no sysctls itself — verified in pinned nixpkgs):
    # aggressive anon swap-out lands on high-prio zram first, then the file;
    # readahead is meaningless on compressed-RAM swap.
    kernel.sysctl = {
      "vm.swappiness" = 180;
      "vm.page-cluster" = 0;
    };

    plymouth.enable = true;

    # Second pool disk (SPCC 477G, whole-disk LUKS, pool-add 2026-09-12 — see
    # task_backlog/storage_backlog.md). Same passphrase as root `crypted`;
    # stage-1 retries entered passwords automatically → single boot prompt.
    # by-uuid: kernel nvme numbering is unstable across boots, never use it.
    initrd.luks.devices.crypted2.device = "/dev/disk/by-uuid/f4aed711-b947-4570-b0f2-df8b0d26b915";

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
      # Rootless container networking (podman netavark/cni) — previously
      # injected by the docker daemon module. All four are =m, so they
      # must be explicitly loaded or container networking breaks after reboot.
      "bridge"
      "veth"
      "br_netfilter"
      "xt_nat"
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
      # Fail-safe for the 2026-10-15/16 box freezes (DMCUB/DMUB storm on the
      # iGPU display engine under heavy dGPU compute): on an amdgpu hang, the
      # driver RESETS the GPU instead of hanging the whole display stack.
      "amdgpu.gpu_recovery=1"
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

  # ── GPU-workload host hardening (2026-10-15/16 freeze postmortem) ──────────
  # oomd was running with an EMPTY /etc/systemd/oomd.conf and did nothing in
  # both incidents. Give it real defaults: kill a pressure-generating cgroup
  # after 20% memory pressure for 20s — BEFORE the box thrashes/fails.
  environment.etc."systemd/oomd.conf.d/10-geks-geks.conf".text = ''
    [OOM]
    DefaultMemoryPressureLimit=20%
    DefaultMemoryPressureDurationSec=20s
  '';
  # Opt the comfyui service into oomd management (its MemoryMax comes from the
  # private flake's comfyui module; this adds the oomd kill contract on top).
  systemd.services.comfyui.serviceConfig.ManagedOOMMemoryPressure = "kill";

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
        "libvirtd"
        "kvm"
        "qemu-libvirtd"
        "plugdev"
        "gamemode"
        "input"
      ];
      # Keep user services (rootless containers etc.) running after logout —
      # without linger podman user services stop when the user logs out.
      linger = true;
    };
  };

  # ── Virtualisation ────────────────────────────────────────────────────────────
  virtualisation = {
    # Podman (daemonless) — replaced rootless docker on 2026-09-20 (user
    # decision; the windows VM compose was dropped in favor of winboat).
    # dockerCompat gives tools that hard-code /var/run/docker.sock a compat
    # socket; rootless use is native podman (distrobox picks it up
    # automatically). dns_enabled gives compose-style projects service-name
    # DNS on the default network. Docker images/containers stay dormant in
    # /var/lib/docker until the migration session — see the docker backlog.
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
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
    # usbtop is enabled in nixos/sys-pkgs.nix (syspkgs module) — no per-host duplicate.
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
      # btrfs visibility (2026-09-11): btdu (CoW-aware usage TUI, shared extents
      # counted once), compsize (per-dir compression ratios), btrfs-assistant
      # (snapper/scrub/balance GUI — no compression/dedup stats). NOTE: no
      # `bees` package here — verified it ships no status CLI, only beesd +
      # bees-service-wrapper which the service already uses internally.
      btdu
      compsize
      btrfs-assistant
    ];
  };

  system.stateVersion = "24.05";
}
