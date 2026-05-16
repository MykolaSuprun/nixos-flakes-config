-- Catppuccin color palette for Hyprland borders and accents.
-- Source of truth: ~/.config/hypr/lua/catppuccin-palette.lua (Nix-generated, flavor/accent aware).
local p = require("lua/catppuccin-palette")
local c = {
  accent    = p.accent,
  primary   = p.primary,
  peach     = p.peach,
  teal      = p.teal,
  flamingo  = p.flamingo,
  red       = p.red,
  lavender  = p.lavender,
  surface1  = p.surface1,
  crust     = p.crust,
  subtext1  = p.subtext1,
  overlay1  = p.overlay1,
  overlay2  = p.overlay2,
  rosewater = p.rosewater,
}

c.normal_active_border          = c.primary
c.normal_nogroup_active_border  = { colors = { c.accent, c.peach }, angle = 45 }
c.resize_active_border          = { colors = { c.teal, c.flamingo }, angle = 45 }
c.fit_active_border             = { colors = { c.red, c.lavender }, angle = 45 }
c.inactive_border               = { colors = { c.surface1, c.crust }, angle = 45 }
c.nogroup_border                = { colors = { c.subtext1, c.surface1 }, angle = 45 }
c.nogroup_border_active         = c.normal_nogroup_active_border

return c
