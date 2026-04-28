-- NOTE: These are catppuccin macchiato defaults as a fallback.
-- Ideally noctalia would generate a colors.lua file alongside its noctalia/*.conf.
-- Until then, update these manually when the theme changes.
local c = {
  accent    = "rgb(8aadf4)", -- blue
  primary   = "rgb(8aadf4)",
  peach     = "rgb(f5a97f)",
  teal      = "rgb(8bd5ca)",
  flamingo  = "rgb(f0c6c6)",
  red       = "rgb(ed8796)",
  lavender  = "rgb(b7bdf8)",
  surface1  = "rgb(363a4f)",
  crust     = "rgb(181926)",
  subtext1  = "rgb(b8c0e0)",
  overlay1  = "rgb(6e738d)",
  overlay2  = "rgb(939ab7)",
  rosewater = "rgb(f4dbd6)",
}

c.normal_active_border          = c.primary
c.normal_nogroup_active_border  = { colors = { c.accent, c.peach }, angle = 45 }
c.resize_active_border          = { colors = { c.teal, c.flamingo }, angle = 45 }
c.fit_active_border             = { colors = { c.red, c.lavender }, angle = 45 }
c.inactive_border               = { colors = { c.surface1, c.crust }, angle = 45 }
c.nogroup_border                = { colors = { c.subtext1, c.surface1 }, angle = 45 }
c.nogroup_border_active         = c.normal_nogroup_active_border

return c
