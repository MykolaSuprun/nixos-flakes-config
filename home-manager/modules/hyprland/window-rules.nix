{...}: let
  makeHyprlandWindowRules = rule: targets:
    builtins.map (target: "${rule}, ${target}") targets;

  games = [
    "class:^(gamescope)$"
    "class:^(steam_app_1903340)$"
    "class:^(steam_app_990080)$"
    "class:^(steam_app_3489700)$"
    "class:^(steam_app_3564860)$"
    "class:^(titanfall)$"
    "class:^(bioshock)$"
    "class:^(helldivers)$"
    "class:^(overwatch)$"
    "class:^(steam_app_2767030)$"
  ];

  floating = [
    "class:^(steam)$"
    "class:^(nz\.co\.mega\.)$"
    "class:^(org\.cryptomator\.)$"
    "class:^(xwaylandvideobridge)$"
  ];

  priority_floating = [
    "class:^(org\.kde\.ksecretd)$"
  ];

  workspace_scratch_hidden = [
    "class:^(nz\.co\.mega\.)$"
    "class:^(org.cryptomator.launcher.Cryptomator$MainApp)$"
    "class:^(xwaylandvideobridge)$"

    "class:^(Filen)$"
  ];

  workspace_1 = [
    "class:^(zen-beta)$"
  ];

  workspace_7 = [
    "class:^(chromium-browser)$"
  ];

  workspace_12 = games;

  workspace_13 = [
    "initialTitle:^(steam)$"
    "initialTitle:^(Steam)$"
  ];
in {
  wayland.windowManager.hyprland.settings.windowrule =
    [
      "workspace 4 silent, class:^(org.telegram.desktop)$"
    ]
    # Run games fullscreen and allow tearing
    ++ makeHyprlandWindowRules "immediate" games
    ++ makeHyprlandWindowRules "fullscreen" games
    ++ makeHyprlandWindowRules "fullscreenstate 3" games
    ++ makeHyprlandWindowRules "workspace special:scratch_games" games
    # Configure always floating windows
    ++ makeHyprlandWindowRules "float" floating
    ++ makeHyprlandWindowRules "pseudotile" floating
    # Configure priority floating winodws
    ++ makeHyprlandWindowRules "float" priority_floating
    ++ makeHyprlandWindowRules "center" priority_floating
    ++ makeHyprlandWindowRules "pin" priority_floating
    ++ makeHyprlandWindowRules "stayfocused" priority_floating
    ++ makeHyprlandWindowRules "noscreenshare on" priority_floating
    # Configure winodw launch workspaces
    ++ makeHyprlandWindowRules "workspace 1" workspace_1
    ++ makeHyprlandWindowRules "workspace 7" workspace_7
    ++ makeHyprlandWindowRules "workspace 12" workspace_12
    ++ makeHyprlandWindowRules "workspace 13" workspace_13
    # Configure hidden winodws
    ++ makeHyprlandWindowRules "workspace special:scratch_hidden" workspace_scratch_hidden;
}
