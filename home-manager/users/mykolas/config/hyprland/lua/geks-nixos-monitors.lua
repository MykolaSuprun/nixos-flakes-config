local monitor_main      = "desc:ASUSTek COMPUTER INC ASUS VG34V R1LMTF004674"
local monitor_secondary = "desc:GWD ARZOPA 0x48310206"

hl.monitor({
  output   = monitor_main,
  mode     = "3440x1440@165",
  position = "0x0",
  scale    = 1,
  bitdepth = 10,
})

hl.monitor({
  output   = monitor_secondary,
  mode     = "2560x1600@60",
  position = "704x1440",
  scale    = 1.6,
  bitdepth = 10,
})

return {
  main      = monitor_main,
  secondary = monitor_secondary,
}
