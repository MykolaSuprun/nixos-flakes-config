{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: {
  options.myconf.dms.enable = lib.mkEnableOption "DankMaterialShell";
  config = lib.mkIf config.myconf.dms.enable {
    programs.dank-material-shell = {
      enable = true;

      systemd = {
        enable = true; # Systemd service for auto-start
        restartIfChanged = true; # Auto-restart dms.service when dank-material-shell changes
      };

      plugins = {
        hyprlandSubmap.enable = true;
        dankHyprlandWindows.enable = true;
      };

      # Core features
      enableSystemMonitoring = true; # System monitoring widgets (dgop)
      enableVPN = true; # VPN management widget
      enableDynamicTheming = true; # Wallpaper-based theming (matugen)
      enableAudioWavelength = true; # Audio visualizer (cava)
      enableCalendarEvents = true; # Calendar integration (khal)
      enableClipboardPaste = true; # Pasting items from the clipboard (wtype)

      settings = {
        # Theme
        currentThemeName = "custom";
        currentThemeCategory = "registry";
        customThemeFile = "${config.home.homeDirectory}/.config/DankMaterialShell/themes/catppuccin/theme.json";
        registryThemeVariants = {catppuccin = config.catppuccin.flavor;};

        # Matugen / dynamic theming
        matugenScheme = "scheme-tonal-spot";
        runUserMatugenTemplates = true;
        runDmsMatugenTemplates = true;
        matugenTemplateGtk = true;
        matugenTemplateNiri = true;
        matugenTemplateHyprland = true;
        matugenTemplateMangowc = true;
        matugenTemplateQt5ct = true;
        matugenTemplateQt6ct = true;
        matugenTemplateFirefox = true;
        matugenTemplatePywalfox = true;
        matugenTemplateZenBrowser = true;
        matugenTemplateVesktop = true;
        matugenTemplateVencord = true;
        matugenTemplateEquibop = true;
        matugenTemplateGhostty = true;
        matugenTemplateKitty = true;
        matugenTemplateFoot = true;
        matugenTemplateAlacritty = true;
        matugenTemplateNeovim = false;
        matugenTemplateWezterm = true;
        matugenTemplateDgop = true;
        matugenTemplateKcolorscheme = true;
        matugenTemplateVscode = true;
        matugenTemplateEmacs = true;
        matugenTemplateZed = true;

        # Appearance
        cornerRadius = 12;
        blurEnabled = false;
        popupTransparency = 1;
        dockTransparency = 1;

        dockUseOverlayLayer = true;
        widgetBackgroundColor = "sch";
        widgetColorMode = "default";
        controlCenterTileColorMode = "primary";
        buttonColorMode = "primary";
        wallpaperFillMode = "Fill";
        animationSpeed = 1;
        enableRippleEffects = true;
        syncModeWithPortal = true;
        nightModeEnabled = false;
        screenPreferences = {
          wallpaper = [];
        };

        # Typography
        fontFamily = "JetBrains Mono";
        monoFontFamily = "JetBrainsMono Nerd Font";
        fontWeight = 400;
        fontScale = 1;

        # Clock
        use24HourClock = true;
        showSeconds = false;
        centeringMode = "index";

        # Bar widget visibility
        showLauncherButton = true;
        showWorkspaceSwitcher = true;
        showFocusedWindow = true;
        showWeather = true;
        showMusic = true;
        showClipboard = true;
        showCpuUsage = true;
        showMemUsage = true;
        showCpuTemp = true;
        showGpuTemp = true;
        showSystemTray = true;
        showClock = true;
        showNotificationButton = true;
        showBattery = true;
        showControlCenterButton = true;
        showCapsLockIndicator = true;
        showPrivacyButton = true;
        privacyShowMicIcon = false;
        privacyShowCameraIcon = false;
        privacyShowScreenShareIcon = false;

        # Control center
        controlCenterShowNetworkIcon = true;
        controlCenterShowBluetoothIcon = true;
        controlCenterShowAudioIcon = true;
        controlCenterShowAudioPercent = false;
        controlCenterShowVpnIcon = true;
        controlCenterShowBrightnessIcon = false;
        controlCenterShowBrightnessPercent = false;
        controlCenterShowMicIcon = false;
        controlCenterShowMicPercent = false;
        controlCenterShowBatteryIcon = false;
        controlCenterShowPrinterIcon = false;
        controlCenterShowScreenSharingIcon = true;
        controlCenterWidgets = [
          {
            id = "volumeSlider";
            enabled = true;
            width = 50;
          }
          {
            id = "brightnessSlider";
            enabled = true;
            width = 50;
          }
          {
            id = "wifi";
            enabled = true;
            width = 50;
          }
          {
            id = "bluetooth";
            enabled = true;
            width = 50;
          }
          {
            id = "audioOutput";
            enabled = true;
            width = 50;
          }
          {
            id = "audioInput";
            enabled = true;
            width = 50;
          }
          {
            id = "nightMode";
            enabled = true;
            width = 50;
          }
          {
            id = "darkMode";
            enabled = true;
            width = 50;
          }
        ];

        # Workspace switcher
        showWorkspaceIndex = true;
        showWorkspaceName = false;
        showWorkspacePadding = false;
        showWorkspaceApps = true;
        workspaceScrolling = true;
        showOccupiedWorkspacesOnly = false;
        workspaceDragReorder = true;
        maxWorkspaceIcons = 3;
        workspaceAppIconSizeOffset = 0;
        groupWorkspaceApps = true;
        workspaceFollowFocus = false;
        reverseScrolling = false;
        workspaceColorMode = "default";
        workspaceOccupiedColorMode = "none";
        workspaceUnfocusedColorMode = "default";
        workspaceUrgentColorMode = "default";
        workspaceFocusedBorderEnabled = true;
        workspaceFocusedBorderColor = "primary";
        workspaceFocusedBorderThickness = 2;

        # Audio / music widgets
        waveProgressEnabled = true;
        scrollTitleEnabled = true;
        audioVisualizerEnabled = true;
        audioScrollMode = "volume";
        audioWheelScrollAmount = 5;

        # Bar layout / running apps
        clockCompactMode = false;
        focusedWindowCompactMode = false;
        runningAppsCompactMode = true;
        barMaxVisibleApps = 0;
        barMaxVisibleRunningApps = 0;
        barShowOverflowBadge = true;
        runningAppsCurrentWorkspace = true;
        runningAppsGroupByApp = false;
        runningAppsCurrentMonitor = false;
        keyboardLayoutNameCompactMode = false;

        # App dock
        showDock = false;
        appsDockHideIndicators = false;
        appsDockColorizeActive = false;
        appsDockEnlargeOnHover = false;
        appsDockIconSizePercentage = 100;

        appIdSubstitutions = [
          {
            pattern = "Spotify";
            replacement = "spotify";
            type = "exact";
          }
          {
            pattern = "beepertexts";
            replacement = "beeper";
            type = "exact";
          }
          {
            pattern = "home assistant desktop";
            replacement = "homeassistant-desktop";
            type = "exact";
          }
          {
            pattern = "com.transmissionbt.transmission";
            replacement = "transmission-gtk";
            type = "contains";
          }
          {
            pattern = "^steam_app_(\\d+)$";
            replacement = "steam_icon_$1";
            type = "regex";
          }
        ];

        # Launcher
        appLauncherViewMode = "list";
        spotlightModalViewMode = "list";
        sortAppsAlphabetically = false;
        appLauncherGridColumns = 4;
        dankLauncherV2Size = "compact";
        dankLauncherV2ShowFooter = true;
        niriOverviewOverlayEnabled = true;
        launcherLogoMode = "os";
        launcherLogoCustomPath = "";
        launcherLogoColorOverride = "";
        launcherLogoColorInvertOnMode = false;
        launcherLogoBrightness = 0.5;
        launcherLogoContrast = 1;
        launcherLogoSizeOffset = 0;
        launchPrefix = "uwsm-app -- ";

        # Notifications
        notificationOverlayEnabled = false;
        notificationPopupShadowEnabled = true;
        notificationPopupPrivacyMode = false;
        notificationCompactMode = false;
        notificationPopupPosition = 0;
        notificationAnimationSpeed = 1;
        notificationTimeoutLow = 5000;
        notificationTimeoutNormal = 5000;
        notificationTimeoutCritical = 0;
        notificationHistoryEnabled = true;
        notificationHistoryMaxCount = 50;
        notificationHistoryMaxAgeDays = 7;
        notificationHistorySaveLow = true;
        notificationHistorySaveNormal = true;
        notificationHistorySaveCritical = true;
        notificationDedupeEnabled = true;

        # OSD
        osdAlwaysShowValue = false;
        osdPosition = 5;
        osdVolumeEnabled = true;
        osdMediaVolumeEnabled = true;
        osdMediaPlaybackEnabled = false;
        osdBrightnessEnabled = true;
        osdIdleInhibitorEnabled = true;
        osdMicMuteEnabled = true;
        osdCapsLockEnabled = true;
        osdPowerProfileEnabled = false;
        osdAudioOutputEnabled = true;

        # Power menu
        powerActionConfirm = true;
        powerActionHoldDuration = 0.5;
        powerMenuActions = ["reboot" "logout" "poweroff" "lock" "suspend" "restart"];
        powerMenuDefaultAction = "logout";
        powerMenuGridLayout = false;
        modalDarkenBackground = true;

        # Power timeouts (AC)
        acMonitorTimeout = 1800;
        acLockTimeout = 300;
        acSuspendTimeout = 7200;
        acSuspendBehavior = 0;
        batteryMonitorTimeout = 0;
        batteryLockTimeout = 0;
        batterySuspendTimeout = 0;
        batterySuspendBehavior = 0;

        # Lock screen
        lockBeforeSuspend = true;
        loginctlLockIntegration = false;
        fadeToLockEnabled = true;
        fadeToLockGracePeriod = 5;
        fadeToDpmsEnabled = true;
        fadeToDpmsGracePeriod = 5;
        lockAtStartup = false;
        enableFprint = true;
        enableU2f = false;
        lockScreenActiveMonitor = "all";
        lockScreenNotificationMode = 0;
        lockScreenShowPowerActions = true;
        lockScreenShowSystemIcons = true;
        lockScreenShowTime = true;
        lockScreenShowDate = true;
        lockScreenShowProfileImage = true;
        lockScreenShowPasswordField = true;
        lockScreenShowMediaPlayer = false;
        lockScreenPowerOffMonitorsOnLock = false;
        hideBrightnessSlider = false;

        # Sounds
        soundsEnabled = true;
        useSystemSoundTheme = false;
        soundNewNotification = true;
        soundVolumeChanged = true;
        soundPluggedIn = true;

        # Misc
        muxType = "tmux";
        weatherEnabled = true;
        useAutoLocation = false;
        networkPreference = "auto";
        iconTheme = "System Default";
        notepadUseMonospace = true;

        barConfigs = [
          {
            id = "default";
            name = "Main Bar";
            enabled = true;
            position = 0;
            screenPreferences = ["all"];
            leftWidgets = ["launcherButton" "workspaceSwitcher" "focusedWindow"];
            centerWidgets = [
              "music"
              "clock"
              {
                id = "hyprlandSubmap";
                enabled = true;
              }
            ];
            rightWidgets = [
              "systemTray"
              "cpuUsage"
              "memUsage"
              "notificationButton"
              "battery"
              "controlCenterButton"
            ];
            spacing = 4;
            innerPadding = 4;
            squareCorners = false;
            autoHide = false;
            useOverlayLayer = false;
          }
        ];
      };

      session = {
        isLightMode = config.catppuccin.flavor == "latte";
        perModeWallpaper = false;
        wallpaperPath = "${config.home.homeDirectory}/.config/wallpapers/catppuccin/${config.catppuccin.flavor}/first.jpg";
        includedTransitions = ["fade" "wipe" "disc" "stripes" "iris bloom" "pixelate" "portal"];
        nightModeEnabled = false;
        weatherLocation = "Warszawa, województwo mazowieckie";
        weatherCoordinates = "52.2333742,21.0711489";
        weatherHourlyDetailed = true;
        searchAppActions = true;
      };
    };
  };
}
