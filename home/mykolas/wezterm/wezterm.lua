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

-- For example, changing the color scheme:
config.color_scheme = 'Catppuccin Mocha'
config.font_size = 10
config.font = wezterm.font_with_fallback {
  {
    family = 'JetBrains Mono',
    weight = 'Medium',
    -- harfbuzz_features = { 'calt=0', 'clig=0', 'liga=1' },
  },
  { family = 'Terminus', weight = 'Bold' },
  'Noto Color Emoji',
}
-- window size on open
config.initial_rows = 70
config.initial_cols = 260
-- disable close window confirmation
config.window_close_confirmation = 'NeverPrompt'

-- and finally, return the configuration to wezterm
return config
