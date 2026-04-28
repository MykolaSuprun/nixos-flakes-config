-- Hyprland Lua entry point (requires Hyprland >= 0.55)
-- Modules are loaded from ~/.config/hypr/lua/ via symlinks managed by home-manager.
-- lua/monitors.lua is symlinked to the host-specific monitors file by settings.nix.

require("lua/settings")
require("lua/monitors")
require("lua/workspaces")
require("lua/gestures")
require("lua/startup")
require("lua/binds")
require("lua/window-rules")
