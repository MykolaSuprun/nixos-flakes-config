-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

config.window_decorations = 'RESIZE'
config.display_pixel_geometry = "RGB"
config.freetype_load_target = "Light"
config.freetype_render_target = 'VerticalLcd'

-- For example, changing the color scheme:
config.color_scheme = 'Catppuccin Mocha'
config.font_size = 10
config.font = wezterm.font(
  'JetBrainsMono Nerd Font'
)
-- config.font = wezterm.font_with_fallback ({
--   "JetBrainsMono Nerd Font",
--   {
--     family = "Symbols Nerd Font Mono",
--     scale = 0.75
--     -- weight = 'Medium',
--     -- harfbuzz_features = { 'calt=0', 'clig=0', 'liga=1' },
--   },
-- })
use_cap_height_to_scale_fallback_fonts = true
-- window size on open
config.initial_rows = 70
config.initial_cols = 260
-- disable close window confirmation
config.window_close_confirmation = 'NeverPrompt'

-- and finally, return the configuration to wezterm
return config
