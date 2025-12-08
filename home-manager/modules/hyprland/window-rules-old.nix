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
    "class:^(steam_app_2623190)$"
  ];

  floating = [
    "class:^(steam)$"
    "class:^(nz\.co\.mega\.)$"
    "class:^(org\.cryptomator\.)$"
    "class:^(xwaylandvideobridge)$"
    "class:^(kitty-dropterm)$"
    "class:^(com\.saivert\.pwvucontrol)$"
    "class:^(clipse)$"
  ];

  priority_floating = [
    "class:^(org\.kde\.ksecretd)$"
    "class:^(nm-applet)$"
  ];

  floating_size_m = [
    "class:^(clipse)$"
  ];

  floating_position_center = [
    "class:^(steam)$"
    "class:^(clipse)$"
  ];

  workspace_scratch_hidden = [
    "class:^(nz\.co\.mega\.)$"
    "initialTitle:Cryptomator"
    "class:^(xwaylandvideobridge)$"
    "class:^(Filen)$"
  ];

  workspace_1 = [
    "class:^(zen-beta)$"
  ];

  workspace_4 = [
    "class:^(org\.telegram\.desktop)$"
  ];

  workspace_7 = [
    "class:^(chromium-browser)$"
  ];

  workspace_12 = games;

  workspace_13 = [
    "initialTitle:^((s|S)team)$"
  ];
in {
  wayland.windowManager.hyprland.settings.windowrule =
    []
    ++ makeHyprlandWindowRules "immediate" games
    ++ makeHyprlandWindowRules "fullscreen" games
    ++ makeHyprlandWindowRules "fullscreenstate 3 2" games
    ++ makeHyprlandWindowRules "workspace special:scratch_games" games
    ++ makeHyprlandWindowRules "float" floating
    ++ makeHyprlandWindowRules "pseudo" floating
    ++ makeHyprlandWindowRules "size 40% 30%" floating_size_m
    ++ makeHyprlandWindowRules "center" floating_position_center
    ++ makeHyprlandWindowRules "float" priority_floating
    ++ makeHyprlandWindowRules "center" priority_floating
    ++ makeHyprlandWindowRules "pin" priority_floating
    ++ makeHyprlandWindowRules "stayfocused" priority_floating
    ++ makeHyprlandWindowRules "workspace 1" workspace_1
    ++ makeHyprlandWindowRules "workspace 4" workspace_4
    ++ makeHyprlandWindowRules "workspace 7" workspace_7
    ++ makeHyprlandWindowRules "workspace 12" workspace_12
    ++ makeHyprlandWindowRules "workspace 13" workspace_13
    ++ makeHyprlandWindowRules "workspace special:scratch_hidden" workspace_scratch_hidden;
}
