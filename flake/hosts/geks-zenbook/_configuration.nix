# NixOS system configuration for geks-zenbook (Intel laptop + Hyprland).
# Feature modules (nixos/*.nix) are hand-listed in the host's default.nix
# (import-tree is NOT used for them); enable flags below activate them.
{
  inputs,
  config,
  pkgs,
  pkgs-stable,
  lib,
  ...
}: {
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
    flatpak.enable = true; # bindfs/theme Flatpak setup – enabled for zenbook
  };

  hyprconf = {
    target = "geks-zenbook";
    hyprland.enable = true;
  };

  # ── Theming ───────────────────────────────────────────────────────────────────
  catppuccin = {
    flavor = lib.mkDefault "mocha";
    accent = "mauve";
  };

  # Mocha specialisation, scoped to THIS host.
  #
  # nixos/specialisations.nix keeps the shared 4-flavour block disabled: on
  # geks-nixos each specialisation is a full toplevel with its own ~37 MiB
  # initrd, which does not fit the 511 MiB ESP with limine (162 MiB/generation).
  # That rationale does NOT apply here — zenbook uses GRUB with
  # copyKernels = false, so the kernel and initrd are read from /nix/store and
  # never copied to the ESP. Verified: the specialisation's bootspec references
  # the SAME kernel (linux-6.18.56/bzImage) and initrd
  # (initrd-linux-6.18.56) store paths as the base system → ~0 ESP cost.
  #
  # Gives: a boot-menu entry and `nixos-rebuild switch --specialisation mocha`
  # (and a non-empty list for specialisation-picker, which is otherwise a no-op).
  # Note the base flavour is already mocha, so this is redundancy-by-design:
  # it stays correct if the base flavour is ever changed to something else.
  specialisation.mocha.configuration = {
    catppuccin.flavor = lib.mkForce "mocha";
    home-manager.users.mykolas = {
      catppuccin.flavor = lib.mkForce "mocha";
      myconf.catppuccin.flavor = lib.mkForce "mocha";
    };
  };

  # ── Boot ──────────────────────────────────────────────────────────────────────
  boot = {
    loader = {
      systemd-boot.enable = false;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      grub = {
        enable = true;
        efiSupport = true;
        devices = ["nodev"];
        useOSProber = true;
        memtest86.enable = true;
        configurationLimit = 50;
      };
    };
    plymouth.enable = true;

    # ZFS is not used on this host (ext4 + LUKS).
    supportedFilesystems.zfs = false;
  };

  boot.initrd.luks.devices."luks-585372bc-c88f-4e15-ada1-9bca0c43bd29".device = "/dev/disk/by-uuid/585372bc-c88f-4e15-ada1-9bca0c43bd29";

  hardware.enableAllFirmware = true;

  # Intel iGPU VA-API — required for Hyprland rendering on the Zenbook's
  # Intel Iris/Xe graphics, including when booting from the live USB.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [intel-media-driver];
  };

  # ── Networking ────────────────────────────────────────────────────────────────
  networking = {
    hostName = "geks-zenbook";
    networkmanager = {
      enable = true;
      wifi.powersave = true;
    };
  };

  # Tailnet traffic arrives on tailscale0; without this the default firewall
  # drops it (services.tailscale does NOT open the firewall — only
  # openFirewall opens UDP 41641 for the tunnel itself). Mirrors geks-nixos.
  networking.firewall.trustedInterfaces = ["tailscale0"];

  # ── Locale ────────────────────────────────────────────────────────────────────
  time.timeZone = "Europe/Warsaw";

  i18n.defaultLocale = "en_IE.UTF-8";
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

  # ── Services ──────────────────────────────────────────────────────────────────
  services = {
    desktopManager.plasma6.enable = true;

    # Plain SSH over the tailnet (reachable via tailscale0/trustedInterfaces).
    # Client-side SSH_AUTH_SOCK is owned by gpg-agent (see home-zenbook.nix);
    # the NixOS ssh-agent stays disabled (programs.ssh.startAgent = false).
    openssh = {
      enable = true;
    };

    # Tailscale. extraSetFlags runs `tailscale set --ssh` on every boot so
    # Tailscale SSH stays enabled (`extraUpFlags` only applies with
    # authKeyFile, which this host does not use — login is interactive:
    # `sudo tailscale up`). --operator lets the user run tailscale commands
    # (incl. `tailscale ssh`-related state) without sudo. Mirrors geks-nixos.
    tailscale = {
      enable = true;
      extraSetFlags = ["--ssh" "--operator=mykolas"];
    };

    # SDDM: shows both Plasma and Hyprland session entries in the greeter,
    # and avoids the sysc-greet/Hyprland compositor hang on Intel iGPU
    # (the greeter itself now runs under KWin Wayland, not Hyprland).
    greetd = {
      enable = false;
    };
    sysc-greet = {
      enable = false;
      compositor = "hyprland";
      settings = {
        terminal = {
          vt = 1;
        };
      };
    };

    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    displayManager.defaultSession = "hyprland-uwsm";

    xserver.xkb = {
      layout = "us";
      variant = "";
    };

    keyd = {
      enable = true;
      keyboards.default = {
        ids = ["0001:0001"];
        settings = {
          main = {
            capslock = "overload(control, esc)";
          };
        };
      };
    };

    printing.enable = true;

    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  # ── Security ──────────────────────────────────────────────────────────────────
  security = {
    rtkit.enable = true;
    pam.services = {
      swaylock = {};
      hyprlock = {};
      # Auto-unlock KWallet at login so ProtonVPN (and other Secret Service
      # clients under Hyprland) retrieve credentials without an extra prompt.
      # Requires login password == kdewallet password. pam_kwallet_init,
      # run as a Hyprland systemd oneshot (settings.nix), consumes the
      # PAM_KWALLET5_LOGIN token this injects. Plasma handles its own unlock.
      sddm.kwallet = {
        enable = true;
        package = pkgs.kdePackages.kwallet-pam;
      };
    };
    polkit.enable = true;
  };

  # ── Users ─────────────────────────────────────────────────────────────────────
  users.defaultUserShell = pkgs.zsh;

  users.mutableUsers = true; # passwords set via passwd; initialPassword is only used on first user creation
  users.users.root.initialPassword = "nixos";

  users.users.mykolas = {
    isNormalUser = true;
    initialPassword = "nixos";
    description = "Mykola Suprun";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "kvm"
      "qemu-libvirtd"
      "plugdev"
      "gamemode"
    ];
  };

  # ── Programs ──────────────────────────────────────────────────────────────────
  programs = {
    fish = {
      enable = true;
      useBabelfish = true;
    };
    zsh.enable = true;
    appimage = {
      enable = true;
      binfmt = true;
    };
    neovim = {
      defaultEditor = true;
      vimAlias = true;
    };
    dconf.enable = true;
    partition-manager.enable = true;
    # SSH agent is handled by HM's gpg-agent with enableSshSupport.
    # The NixOS ssh-agent is disabled to avoid conflicting SSH_AUTH_SOCK values.
    ssh = {
      startAgent = false;
      enableAskPassword = false;
    };
  };

  # ── System ────────────────────────────────────────────────────────────────────
  environment = {
    enableAllTerminfo = true;
    shells = with pkgs; [zsh fish nushell];
    systemPackages = with pkgs; [
      keyd
      brightnessctl
    ];
    sessionVariables = {
      SYS_THEME =
        if config.catppuccin.enable
        then "catppuccin-${config.catppuccin.flavor}"
        else "";
    };
  };

  system.stateVersion = "25.05";
}
