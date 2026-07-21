{
  inputs,
  pkgs,
  pkgs-stable,
  lib,
  config,
  ...
}: {
  options.myconf.desktop.enable = lib.mkEnableOption "desktop apps";
  config = lib.mkIf config.myconf.desktop.enable {
    xdg = {
      enable = true;
    };

    programs = {
      zen-browser = {
        enable = true;
        # Mirror Firefox's portal picker setting (zen-browser HM module is
        # built on mkFirefoxModule, so the schema is identical). Zen is the
        # DEFAULT_BROWSER on these hosts, so this matters more than the
        # Firefox block below for day-to-day use.
        profiles.default.settings = {
          "widget.use-xdg-desktop-portal.file-picker" = 1;
          "widget.use-xdg-desktop-portal" = true;
        };
      };
      firefox = {
        enable = true;
        policies = {
          ExtensionSettings = {
            # Sidebery's official Extension ID
            "{3c078156-979c-498b-8990-85f7987dd929}" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/sidebery/latest.xpi";
              installation_mode = "force_installed";
              private_browsing = true;
            };
            # uBlock Origin
            "uBlock0@raymondhill.net" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              installation_mode = "normal_installed";
            };
            # Kagi search
            "search@kagi.com" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/kagi-search-for-firefox/latest.xpi";
              installation_mode = "normal_installed";
            };
            # Kagi search
            "{bd6be57d-91d7-41d2-b61d-3ba20f7942e5}" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/kagi-translate/latest.xpi";
              installation_mode = "normal_installed";
            };
            # Tab Stash
            "tab-stash@condordes.net" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/tab-stash/latest.xpi";
              installation_mode = "normal_installed";
            };
            # Proton VPN
            "vpn@proton.ch" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/proton-vpn-firefox-extension/latest.xpi";
              installation_mode = "normal_installed";
            };
            # Proton Pass
            "78272b6fa58f4a1abaac99321d503a20@proton.me" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/proton-pass/latest.xpi";
              installation_mode = "normal_installed";
            };
            # Privacy Badger
            "jid1-MnnxcxisBPnSXQ@jetpack" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
              installation_mode = "normal_installed";
            };
          };
        };
        profiles.default = {
          isDefault = true;

          # 1. Flip the required about:config flags declaratively
          settings = {
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            # Optional: Often needed for custom UI svgs/themes to render correctly in userChrome
            "svg.context-properties.content.enabled" = true;
            # Use the XDG desktop portal's file picker (Dolphin via
            # xdg-desktop-portal-kde, see nixos/xdg.nix) instead of Firefox's
            # bundled GTK dialog. Value must be a number, not a string.
            "widget.use-xdg-desktop-portal.file-picker" = 1;
            "widget.use-xdg-desktop-portal" = true;
          };
          extensions = {
            force = true;
          };

          # 2. Inject the auto-hide CSS directly
          userChrome =
            # css
            ''
              /* Hide the native top tab bar */
              #TabsToolbar {
                  visibility: collapse !important;
              }

              /* Remove the Sidebery interface header entirely */
                  #sidebar-box #sidebar-header {
                  display: none !important;
              }

              /* 1. Base container — collapsed to a hairline; only the trigger
                 zone below is interactive. */
              #sidebar-box {
                position: relative !important;
                min-width: 0px !important;
                max-width: 0px !important;
                z-index: 100 !important;
                overflow: visible !important;
              }

              /* 2. Invisible trigger zone — 6px strip flush with the screen
                 edge, full height. Deliberate: the cursor must dwell right at
                 the edge, so a grazing motion passes through without firing. */
              #sidebar-box::after {
                content: "" !important;
                position: absolute !important;
                top: 0 !important;
                left: 0 !important;
                width: 6px !important;
                height: 100% !important;
                z-index: 99 !important;
              }

              /* 3. The sidebar — off-canvas by default. Retract path uses the
                 0s delay here, so it folds back the instant the cursor leaves. */
              #sidebar {
                position: absolute !important;
                left: 0px !important;
                width: 260px !important;
                height: 100vh !important;
                margin-left: -260px !important;
                opacity: 0.85 !important;
                transition:
                  margin-left 0.16s cubic-bezier(0.22, 1, 0.36, 1) 0s,
                  opacity 0.16s cubic-bezier(0.22, 1, 0.36, 1) 0s !important;
                z-index: 101 !important; /* Above the trigger buffer */
                background: var(--lwt-accent-color) !important;
              }

              /* 4. Reveal on hover / drag-over. A small 0.12s open delay makes
                 the trigger deliberate despite the narrow zone — a fast swipe
                 across the 6px strip won't fire. Retraction falls back to the
                 rule above (no delay), so it's immediate. */
              #sidebar-box:hover #sidebar,
              #sidebar-box:-moz-drag-over #sidebar {
                margin-left: 0px !important;
                opacity: 1 !important;
                transition:
                  margin-left 0.16s cubic-bezier(0.22, 1, 0.36, 1) 0.12s,
                  opacity 0.16s cubic-bezier(0.22, 1, 0.36, 1) 0.12s !important;
              }
            '';
        };
      };
    };

    home.packages = with pkgs; [
      # plasma packages and basic applications
      # kdePackages.sddm-kcm
      kdePackages.ark
      kdePackages.yakuake
      kdePackages.dolphin
      kdePackages.kservice
      kdePackages.qtstyleplugin-kvantum
      krusader
      #krusader dependencies
      xxdiff
      kdiff3
      krename
      kdePackages.okular
      kdePackages.gwenview
      kdePackages.kde-cli-tools
      kdePackages.kio-extras
      pkgs-stable.zoom-us

      nemo-with-extensions

      clipse
      pkgs.kdePackages.qttools
      krita-unwrapped

      # icon themes
      catppuccin-papirus-folders

      # internet
      mullvad-browser
      proton-vpn
      proton-pass
      protonmail-desktop
      proton-authenticator-bin
      lbry
      vivaldi
      floorp-bin
      filen-desktop
      impala # tui wifi manager

      # social
      discord
      signal-desktop
      ayugram-desktop
      telegram-desktop
      viber
      tg

      # other
      onlyoffice-desktopeditors
      bluetui
      pkgs-stable.megasync
      cryptomator
      qbittorrent
      libreoffice-qt
      ledger-live-desktop
      protonup-qt
      protonplus
      protonup-ng
      ldacbt
      spotify-player
      ffmpeg-full

      obsidian
      basalt

      # virtualization
      distrobox
      docker-compose

      # wine, steam and other gaming related packages
      # bottles
      mangohud

      # media
      spotify
      gimp
      vlc
      cider-2

      # gaming
      pkgs-stable.limo
      umu-launcher
      # steamtinkerlaunch dependencies
      xdotool
      xwininfo
      yad
      unzip
      unixtools.xxd
      bemenu
      pkgs.freerdp
      pkgs-stable.gtk-frdp
    ];
  };
}
