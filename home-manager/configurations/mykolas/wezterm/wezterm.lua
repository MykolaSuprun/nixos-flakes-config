-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action

-- This table will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- Tab bar configuration
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true -- render tab bar using terminal font
config.tab_max_width = 32

-- Appearance
config.color_scheme = "Catppuccin Latte"
config.window_decorations = "NONE"
config.window_background_opacity = 1
config.macos_window_background_blur = 20
config.display_pixel_geometry = "RGB"
config.freetype_load_target = "Light"
config.window_padding = {
  left = 2,
  right = 2,
  top = 0,
  bottom = 0,
}

config.font_size = 10
config.font = wezterm.font({
  family = "JetBrainsMono Nerd Font",
  weight = "Medium",
  harfbuzz_features = { "calt=1", "clig=1", "liga=1" },
})
use_cap_height_to_scale_fallback_fonts = true
-- window size on open
config.initial_rows = 60
config.initial_cols = 200
-- disable close window confirmation
config.window_close_confirmation = "NeverPrompt"

config.enable_wayland = true
config.enable_kitty_graphics = true
config.front_end = "WebGpu" -- Options: "OpenGL", "Software", "WebGpu"

config.term = "wezterm"
config.set_environment_variables = {
  TERM = "wezterm",
  COLORTERM = "truecolor",
}

return config
