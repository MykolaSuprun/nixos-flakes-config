-- Detect the current host by reading /etc/hostname and require the matching
-- monitor config. Each host file calls hl.monitor() and returns { main, secondary }.
-- Falls back to nil (Hyprland auto-detects) on unknown hosts.

local host_configs = {
  ["geks-nixos"]   = "lua/geks-nixos-monitors",
  ["geks-zenbook"]  = "lua/geks-zenbook-monitors",
}

local hostname = ""
local f = io.open("/etc/hostname", "r")
if f then
  hostname = f:read("*l") or ""
  f:close()
end
-- strip any trailing whitespace
hostname = hostname:match("^(.-)%s*$")

local module = host_configs[hostname]
if module then
  return require(module)
end

-- Unknown host: let Hyprland auto-detect monitors.
return { main = nil, secondary = nil }
