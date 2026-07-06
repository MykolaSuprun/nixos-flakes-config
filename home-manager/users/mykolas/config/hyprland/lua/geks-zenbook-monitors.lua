local monitor_main      = "desc:Samsung Display Corp. 0x4190"
local monitor_secondary = "desc:BOE 0x0A8D"

hl.monitor({
  output   = monitor_main,
  mode     = "2880x1800@120",
  position = "0x0",
  scale    = 1.5,
  bitdepth = 10,
})

hl.monitor({
  output   = monitor_secondary,
  mode     = "2880x864@120",
  position = "0x1200",
  scale    = 1.5,
  bitdepth = 10,
  cm       = "hdr",
  sdrbrightness = 1.4,
  sdrsaturation = 1.0,
})

-- Map the secondary display's built-in touch sensor to its output so that
-- touch input is constrained to the correct monitor.
-- Run `hyprctl devices` to find the exact touch device name, then update this entry.
hl.device({
  name   = "ILTouch0001:00 222A:0001",
  output = monitor_secondary,
})

return {
  main      = monitor_main,
  secondary = monitor_secondary,
}
