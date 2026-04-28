-- Load monitor descriptors so workspace→monitor assignments stay in sync.
local monitors = require("lua/monitors")
local monitor_main      = monitors.main
local monitor_secondary = monitors.secondary

-- Workspaces 1–10 on the main monitor
if monitor_main then
  for i = 1, 10 do
    hl.workspace_rule({
      workspace = tostring(i),
      monitor   = monitor_main,
      default   = (i == 1) or nil,
    })
  end
end

-- Workspaces 11–14 on the secondary monitor
if monitor_secondary then
  for i = 11, 14 do
    hl.workspace_rule({ workspace = tostring(i), monitor = monitor_secondary })
  end
end

-- on-created-empty launchers
hl.workspace_rule({ workspace = "4",  on_created_empty = "pidof AyuGram || uwsm app AyuGram" })
hl.workspace_rule({ workspace = "11", on_created_empty = "pidof obsidian || uwsm app obsidian" })
