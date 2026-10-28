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
    # Fingerprint reader (FeinTech FPS00201) via the pinned elanpress
    # libfprint fork — the module, package pin and sudo PAM wiring all
    # live in nixconf-private (fingerprint-elanpress).
    fingerprint-elanpress.enable = true;
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
  # zram only. The 64G loop-backed btrfs file (gen 237, 2026-10-11 → removed
  # 2026-10-20) was the freeze path: once zram filled, swap-out had to allocate
  # memory through loop → btrfs → dm-crypt while memory was exhausted, and the
  # box livelocked instead of OOM-killing (incidents #3/#4, strata at 50–71 GiB
  # RSS, cliff right as swap passed ~21 GiB). Its 89 GiB of swap headroom also
  # kept earlyoom's swap condition from ever tripping. A plain btrfs swapfile
  # stays impossible (2-device pool), so overflow now ends in a kill, not a
  # freeze. Leftover /var/swap/swapfile (64G) can be deleted by hand.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
    priority = 100;
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
      # 2026-10-20 freeze postmortem: full magic SysRq so a wedged box can be
      # walked down with Alt+PrintScreen REISUB instead of a hard power cut —
      # every power-button reset is a corruption lottery for the btrfs pool.
      "kernel.sysrq" = 1;
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
    # 2026-10-20 freeze postmortem: the Oct 15/16 DMCUB/DMUB display-engine
    # storms (Raphael iGPU 0000:59:00.0) are in a constant upstream DC fix
    # stream — test latest before any structural display rerouting.
    # Revert to pkgs.linuxPackages on regression.
    kernelPackages = pkgs.linuxPackages_latest;
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

  # ── Freeze attribution probes (2026-10-20 freeze postmortem) ────────────────
  # Full evidence chain in task_backlog/nixconf_stability_backlog.md.
  # Minutely memory snapshot: the next wedge names its killer in
  # `journalctl -u rss-watch.service` instead of costing another postmortem.
  systemd.services.rss-watch = {
    description = "Freeze attribution: memory snapshot + top RSS processes";
    serviceConfig = {
      Type = "oneshot";
      # Best-effort under thrash — a missed tick costs nothing.
      TimeoutStartSec = "10s";
    };
    script = ''
      ${pkgs.procps}/bin/free -m | ${pkgs.coreutils}/bin/head -n 3
      ${pkgs.procps}/bin/ps -eo rss=,pid=,comm= --sort=-rss \
        | ${pkgs.coreutils}/bin/head -n 11 \
        | ${pkgs.gawk}/bin/awk '{printf "rss_mib=%-8.0f pid=%-8s comm=%s\n", $1/1024, $2, $3}'
    '';
  };
  systemd.timers.rss-watch = {
    description = "Minutely rss-watch (freeze attribution)";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "minutely";
      AccuracySec = "10s";
      Unit = "rss-watch.service";
    };
  };

  networking.firewall.trustedInterfaces = ["tailscale0"];

  # ── Services ──────────────────────────────────────────────────────────────────
  services = {
    # 2026-10-20 freeze postmortem: the kernel OOM killer never fired in 30d
    # (87G of swap means allocations never fail — the box comas instead) and
    # oomd starved with zero kills despite the 20%/20s tuning (no kill
    # contracts outside comfyui). earlyoom is a tiny, mlock-all'd userspace
    # killer that survives the thrash — turns the next memory catastrophe into
    # a killed + journal-named offender instead of a 20-minute coma.
    # oomd stays for cgroup-level granular work.
    earlyoom = {
      enable = true;
      # Memory-only trigger: earlyoom kills only when BOTH mem and swap are
      # under threshold, so swap thresholds of 100% make swap always "low"
      # and avail mem alone decides. With swap at 10% it never fired —
      # incident #4 sat at 9.9% avail with 77% swap free right before the
      # cliff. SIGTERM at 10% avail, SIGKILL at 5%.
      freeMemThreshold = 10;
      freeMemKillThreshold = 5;
      freeSwapThreshold = 100;
      freeSwapKillThreshold = 100;
      # Kill the model runners first; never the compositor or shell.
      extraArgs = [
        "--prefer"
        "^(strata|strata-vision-h|comfyui|llama-server|ollama|python3?)$"
        "--avoid"
        "^(\\.Hyprland-wrapp|Xwayland|\\.quickshell-wra|systemd|sshd|greetd|uwsm)$"
      ];
    };
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
      # --operator: OpenClaw's gateway (user systemd unit, from
      # nixconf-private homeManagerModules.openclaw) runs tailnet Serve
      # (gateway.tailscale.mode="serve") as this user — route claims, claim
      # cleanup, and `tailscale whois` for identity-header auth all need
      # operator rights, without sudo. Idempotent; self-heals every boot.
      # NOTE: this must stay in the host config — an HM user module cannot
      # reach the system-level services.tailscale namespace (verified:
      # setting extraSetFlags from the openclaw HM module has no effect).
      extraSetFlags = ["--ssh" "--operator=mykolas"];
    };

    resolved.enable = true;

    xserver = {
      enable = true;
      videoDrivers = ["amdgpu"];
    };

    desktopManager.plasma6 = {enable = true;};

    flatpak.enable = true;

    # fprintd/fingerprint setup moved to nixconf-private
    # (nixosModules.fingerprint-elanpress) — hardware-specific details
    # stay out of the public repo.
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
        # Fingerprint PAM wiring lives in nixconf-private
        # (fingerprint-elanpress): sudo accepts the enrolled print via
        # pam_fprintd (sufficient — password falls through). Lock
        # screens / login can follow once the print proves itself in
        # daily use.
        # Auto-unlock KWallet at login so ProtonVPN (and other Secret Service
        # clients under Hyprland) retrieve credentials without an extra prompt.
        # Requires login password == kdewallet password. pam_kwallet_init,
        # run as a Hyprland systemd oneshot (settings.nix), consumes the
        # PAM_KWALLET5_LOGIN token this injects. Plasma handles its own unlock.
        greetd.kwallet = {
          enable = true;
          package = pkgs.kdePackages.kwallet-pam;
        };
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
        "dialout"
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

  # ── ROCm GPU isolation ────────────────────────────────────────────────────────
  # The Raphael iGPU (gfx1036) drives the displays and is unsupported by ROCm
  # (AMD: disable the iGPU or select the target GPU via env vars). Unset, every
  # ROCm process (ComfyUI, strata, ...) also attaches to the display GPU, whose
  # KFD queue evict/restore cycles under memory pressure are the freeze suspect.
  # The UUID is the 7900 XTX's (stable across enumeration order); Mesa/Hyprland
  # rendering is unaffected. Verify: no *_54953 entries in
  # /sys/class/kfd/kfd/proc/<pid>/ for ROCm processes.
  environment.variables.ROCR_VISIBLE_DEVICES = "GPU-8fd17aa5c99ca2b1";
  systemd.globalEnvironment.ROCR_VISIBLE_DEVICES = "GPU-8fd17aa5c99ca2b1";
  systemd.user.settings.Manager.DefaultEnvironment = "ROCR_VISIBLE_DEVICES=GPU-8fd17aa5c99ca2b1";

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
