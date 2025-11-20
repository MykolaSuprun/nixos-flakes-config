{...}: let
  makeHyprlandWindowRules = rule: targets:
    builtins.map (target: "match:${target}, ${rule}") targets;

  games = [
    "class ^(gamescope)$"
    "class ^(steam_app_1903340)$"
    "class ^(steam_app_990080)$"
    "class ^(steam_app_3489700)$"
    "class ^(steam_app_3564860)$"
    "class ^(titanfall)$"
    "class ^(bioshock)$"
    "class ^(helldivers)$"
    "class ^(overwatch)$"
    "class ^(steam_app_2767030)$"
  ];

  floating = [
    "class ^(steam)$"
    "class ^(nz\.co\.mega\.)$"
    "class ^(org\.cryptomator\.)$"
    "class ^(xwaylandvideobridge)$"
    "class ^(kitty-dropterm)$"
    "class ^(com\.saivert\.pwvucontrol)$"
  ];

  priority_floating = [
    "class ^(org\.kde\.ksecretd)$"
  ];

  workspace_scratch_hidden = [
    "class ^(nz\.co\.mega\.)$"
    "initial_title Cryptomator"
    "class ^(xwaylandvideobridge)$"
    "class ^(Filen)$"
  ];

  workspace_1 = [
    "class ^(zen-beta)$"
  ];

  workspace_4 = [
    "class ^(zen-beta)$"
    "class ^(org\.telegram\.desktop)$"
  ];

  workspace_7 = [
    "class ^(chromium-browser)$"
  ];

  workspace_12 = games;

  workspace_13 = [
    "initial_title ^((s|S)team)$"
  ];
in {
  wayland.windowManager.hyprland.settings.windowrule =
    [
    ]
    # Run games fullscreen and allow tearing
    ++ makeHyprlandWindowRules "immediate on" games
    ++ makeHyprlandWindowRules "fullscreen on" games
    ++ makeHyprlandWindowRules "fullscreen_state internal 3" games
    ++ makeHyprlandWindowRules "workspace special:scratch_games" games
    # Configure always floating windows
    ++ makeHyprlandWindowRules "float on" floating
    ++ makeHyprlandWindowRules "pseudo on" floating
    # Configure priority floating winodws
    ++ makeHyprlandWindowRules "float on" priority_floating
    ++ makeHyprlandWindowRules "center on" priority_floating
    ++ makeHyprlandWindowRules "pin on" priority_floating
    ++ makeHyprlandWindowRules "stay_focused on" priority_floating
    # ++ makeHyprlandWindowRules "noscreenshare on" priority_floating
    # Configure winodw launch workspaces
    ++ makeHyprlandWindowRules "workspace 1" workspace_1
    ++ makeHyprlandWindowRules "workspace 4" workspace_4
    ++ makeHyprlandWindowRules "workspace 7" workspace_7
    ++ makeHyprlandWindowRules "workspace 12" workspace_12
    ++ makeHyprlandWindowRules "workspace 13" workspace_13
    # Configure hidden winodws
    ++ makeHyprlandWindowRules "workspace special:scratch_hidden" workspace_scratch_hidden;
}
