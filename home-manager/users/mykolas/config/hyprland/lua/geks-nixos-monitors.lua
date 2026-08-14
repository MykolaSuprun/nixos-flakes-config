local monitor_main = "desc:ASUSTek COMPUTER INC ASUS VG34V R1LMTF004674"
local monitor_secondary = "desc:GWD ARZOPA 0x48310206"

-- Runtime-toggleable disabled state. The `monitor-toggle` script flips these
-- in $XDG_STATE_HOME/hypr/monitor-state and applies the change live via
-- `hyprctl keyword monitor`, so monitors can be disabled/enabled without
-- editing this config. Read at startup so toggles survive restarts/reloads.
local state_home = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") or "") .. "/.local/state"
local state_file = state_home .. "/hypr/monitor-state"

local function read_disabled(key)
	local f = io.open(state_file, "r")
	if not f then
		return false
	end
	for line in f:lines() do
		local k, v = line:match("^(%w+)=(true|false)$")
		if k == key then
			f:close()
			return v == "true"
		end
	end
	f:close()
	return false
end

local monitor_main_disabled = read_disabled("main_disabled")
local monitor_secondary_disabled = read_disabled("secondary_disabled")

hl.monitor({
	output = monitor_main,
	mode = "3440x1440@165",
	position = "0x0",
	scale = 1,
	bitdepth = 10,
	disabled = monitor_main_disabled,
})

hl.monitor({
	output = monitor_secondary,
	mode = "2560x1600@60",
	position = "704x1440",
	scale = 1.6,
	bitdepth = 10,
	disabled = monitor_secondary_disabled,
})

return {
	main = monitor_main,
	secondary = monitor_secondary,
}
