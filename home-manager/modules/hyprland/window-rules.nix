{...}: let
  makeHyprlandWindowRules = rule: classes:
    builtins.map (class: "${rule}, class:^(${class}.*)$") classes;

  games = [
    "gamescope"
    "steam_app_1903340"
    "steam_app_990080"
    "steam_app_3489700"
    "steam_app_3564860"
    "titanfall"
    "bioshock"
    "helldivers"
    "overwatch"
    "steam_app_2767030"
  ];

  floating = [
    "steam"
    "nz.co.mega."
    "org.cryptomator."
    "xwaylandvideobridge"
  ];

  workspace_12 = games;
  workspace_13 = ["steam"];

  workspace_scratch_hidden = [
    "nz\.co\.mega\."
    "org\.cryptomator"
    "xwaylandvideobridge"
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
    # Configure always floating windows
    ++ makeHyprlandWindowRules "float" floating
    ++ makeHyprlandWindowRules "pseudotile" floating
    # Configure winodw launch workspaces
    ++ makeHyprlandWindowRules "workspace 12" workspace_12
    ++ makeHyprlandWindowRules "workspace 13" workspace_13
    # Configure hidden winodws
    ++ makeHyprlandWindowRules "workspace special:scratch_hidden" workspace_scratch_hidden;
}
