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

return {
  main      = monitor_main,
  secondary = monitor_secondary,
}
