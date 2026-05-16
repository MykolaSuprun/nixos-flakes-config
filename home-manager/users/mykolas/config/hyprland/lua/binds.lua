local colors = require("lua/colors")

local mod = "SUPER"
local terminal = "uwsm app -- kitty"
local filemanager = "uwsm app -- kitty -e yazi"
local menu = "run_menu"

-- Launch apps
hl.bind(mod .. " + SHIFT + SPACE", hl.dsp.exec_cmd("pypr toggle term"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("pypr toggle volume"))
hl.bind(mod .. " + N", hl.dsp.exec_cmd("swaync-client -t"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd(filemanager))
hl.bind(mod .. " + CTRL + S", hl.dsp.exec_cmd("hyprctl dispatch hyprexpo:expo toggle"))
hl.bind(mod .. " + C", hl.dsp.exec_cmd("kitty --class clipse -e clipse"))

-- Window management
hl.bind(mod .. " + W", hl.dsp.window.close())
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + SHIFT + TAB", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Session
hl.bind(mod .. " + SHIFT + Q", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mod .. " + CTRL + SHIFT + M", hl.dsp.exec_cmd("uwsm stop"))

-- Launch terminal
hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(terminal))

-- Monitor focus (scroll wheel)
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ monitor = "+1" }))
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ monitor = "-1" }))

-- Scrolling layout promote
hl.bind(mod .. " + T", hl.dsp.layout("promote"))

-- Focus movement
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "d" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "r" }))

-- Window movement
hl.bind(mod .. " + SHIFT + H", hl.dsp.layout("swapcol l"))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.layout("swapcol r"))

-- Screenshot submap
hl.bind(mod .. " + CTRL + SHIFT + P", hl.dsp.submap("screenshot"))
hl.bind("Print", hl.dsp.submap("screenshot"))

hl.define_submap("screenshot", function()
	hl.bind("S", hl.dsp.exec_cmd("grimblast -t png copysave area"))
	hl.bind("E", hl.dsp.exec_cmd("grimblast -t png edit area"))
	-- Note: S (screen) overrides S (area) - matching original behaviour
	hl.bind("S", hl.dsp.exec_cmd("grimblast -t png copysave screen"))
	hl.bind("A", hl.dsp.exec_cmd("grimblast -t png copysave active"))
	-- With delay
	hl.bind(mod .. " + S", hl.dsp.exec_cmd("grimblast -w 3 -t png copysave area"))
	hl.bind(mod .. " + E", hl.dsp.exec_cmd("grimblast -w 3 -t png edit area"))
	hl.bind(mod .. " + S", hl.dsp.exec_cmd("grimblast -w 3 -t png copysave screen"))
	hl.bind(mod .. " + A", hl.dsp.exec_cmd("grimblast -w 3 -t png copysave active"))
	hl.bind("catchall", hl.dsp.submap("reset"))
	hl.bind("escape", hl.dsp.submap("reset"))
end)

-- Resize submap
hl.bind(mod .. " + R", function()
	hl.exec_cmd("hyprctl keyword general:col.active_border 'rgba(8bd5caff) rgba(f0c6c6ff) 45deg'")
	hl.dispatch(hl.dsp.submap("resize"))
end)

hl.define_submap("resize", function()
	hl.bind(mod .. " + H", hl.dsp.focus({ direction = "l" }))
	hl.bind(mod .. " + J", hl.dsp.focus({ direction = "d" }))
	hl.bind(mod .. " + K", hl.dsp.focus({ direction = "u" }))
	hl.bind(mod .. " + L", hl.dsp.focus({ direction = "r" }))

	hl.bind("L", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
	hl.bind("H", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
	hl.bind("K", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
	hl.bind("J", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
	hl.bind("1", hl.dsp.exec_cmd("hyprctl dispatch resizeactive exact 100% 100%"), { repeating = true })
	hl.bind("2", hl.dsp.exec_cmd("hyprctl dispatch resizeactive exact 50% 100%"), { repeating = true })
	hl.bind("3", hl.dsp.exec_cmd("hyprctl dispatch resizeactive exact 33% 100%"), { repeating = true })
	hl.bind("4", hl.dsp.exec_cmd("hyprctl dispatch resizeactive exact 25% 100%"), { repeating = true })

	hl.bind("U", hl.dsp.layout("colresize -conf"), { repeating = true })
	hl.bind("I", hl.dsp.layout("colresize +conf"), { repeating = true })

	hl.bind("escape", function()
		hl.exec_cmd("hyprctl keyword general:col.active_border 'rgba(8aadf4ff)'")
		hl.dispatch(hl.dsp.submap("reset"))
	end)
end)

-- Scrolling fit submap
hl.bind(mod .. " + CTRL + F", function()
	hl.exec_cmd("hyprctl keyword general:col.active_border 'rgba(ed8796ff) rgba(b7bdf8ff) 45deg'")
	hl.dispatch(hl.dsp.submap("fit"))
end)

hl.define_submap("fit", function()
	hl.bind("F", hl.dsp.layout("fit all"))
	hl.bind("V", hl.dsp.layout("fit visible"))
	hl.bind("A", hl.dsp.layout("fit active"))
	hl.bind("B", hl.dsp.layout("fit tobeg"))
	hl.bind("E", hl.dsp.layout("fit toend"))

	hl.bind("escape", function()
		hl.exec_cmd("hyprctl keyword general:col.active_border 'rgba(8aadf4ff)'")
		hl.dispatch(hl.dsp.submap("reset"))
	end)
end)

-- Move workspace to monitor
hl.bind(mod .. " + CTRL + SHIFT + H", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(mod .. " + CTRL + SHIFT + J", hl.dsp.workspace.move({ monitor = "d" }))
hl.bind(mod .. " + CTRL + SHIFT + K", hl.dsp.workspace.move({ monitor = "u" }))
hl.bind(mod .. " + CTRL + SHIFT + L", hl.dsp.workspace.move({ monitor = "r" }))

-- Special workspaces
hl.bind(mod .. " + B", hl.dsp.workspace.toggle_special("scratch_hidden"))
hl.bind(mod .. " + SHIFT + B", hl.dsp.window.move({ workspace = "special:scratch_hidden" }))
hl.bind(mod .. " + G", hl.dsp.workspace.toggle_special("scratch_games"))
hl.bind(mod .. " + SHIFT + G", hl.dsp.window.move({ workspace = "special:scratch_games" }))

-- Relative workspace navigation
hl.bind(mod .. " + right", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mod .. " + left", hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind(mod .. " + SHIFT + left", hl.dsp.window.move({ workspace = "r-1" }))

-- Named workspace shortcuts
hl.bind(mod .. " + U", hl.dsp.focus({ workspace = 1 }))
hl.bind(mod .. " + I", hl.dsp.focus({ workspace = 2 }))
hl.bind(mod .. " + O", hl.dsp.focus({ workspace = 3 }))
hl.bind(mod .. " + P", hl.dsp.focus({ workspace = 4 }))
hl.bind(mod .. " + M", hl.dsp.focus({ workspace = 11 }))

hl.bind(mod .. " + SHIFT + U", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mod .. " + SHIFT + I", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mod .. " + SHIFT + O", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mod .. " + SHIFT + P", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mod .. " + SHIFT + M", hl.dsp.window.move({ workspace = 11 }))

hl.bind(mod .. " + comma", hl.dsp.focus({ workspace = 12 }))
hl.bind(mod .. " + period", hl.dsp.focus({ workspace = 13 }))
hl.bind(mod .. " + slash", hl.dsp.focus({ workspace = 14 }))
hl.bind(mod .. " + SHIFT + comma", hl.dsp.window.move({ workspace = 12 }))
hl.bind(mod .. " + SHIFT + period", hl.dsp.window.move({ workspace = 13 }))
hl.bind(mod .. " + SHIFT + slash", hl.dsp.window.move({ workspace = 14 }))

-- Numeric workspace shortcuts (1–10)
for i = 1, 9 do
	hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }))
	hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Launchers
hl.bind("ALT + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + CTRL + SPACE", hl.dsp.exec_cmd("hyprlauncher"))

-- Audio / media
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))
hl.bind("XF86audiostop", hl.dsp.exec_cmd("playerctl stop"))

-- Brightness (zenbook)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 5%+"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))
