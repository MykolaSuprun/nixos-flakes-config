local colors = require("lua/colors")

local mod = "SUPER"
local terminal = "uwsm app -- ghostty"
local filemanager = "uwsm app -- ghostty -e superfile"
local menu = "run_menu"

-- Launch apps
hl.bind(mod .. " + SHIFT + SPACE", hl.dsp.exec_cmd("pypr toggle term"), { description = "Toggle scratchpad terminal" })
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("pypr toggle volume"), { description = "Toggle volume scratchpad" })
hl.bind(mod .. " + N", hl.dsp.exec_cmd("swaync-client -t"), { description = "Toggle notification panel" })
hl.bind(mod .. " + E", hl.dsp.exec_cmd(filemanager), { description = "Open file manager" })
hl.bind(
	mod .. " + CTRL + S",
	hl.dsp.exec_cmd("hyprctl dispatch hyprexpo:expo toggle"),
	{ description = "Toggle workspace overview" }
)
hl.bind(mod .. " + C", hl.dsp.exec_cmd("kitty --class clipse -e clipse"), { description = "Open clipboard manager" })

-- Window management
hl.bind(mod .. " + W", hl.dsp.window.close(), { description = "Close focused window" })
hl.bind(mod .. " + SHIFT + TAB", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
hl.bind(mod .. " + TAB", hl.dsp.exec_cmd("hyprctl dispatch cyclenext"), { description = "Cycle to next window" })
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "Toggle maximized" })
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen(), { description = "Toggle fullscreen" })
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Drag window" })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window (mouse)" })

-- Session
hl.bind(mod .. " + SHIFT + Q", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Lock screen" })
hl.bind(mod .. " + CTRL + SHIFT + M", hl.dsp.exec_cmd("uwsm stop"), { description = "Stop UWSM session (logout)" })

-- Launch terminal
hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(terminal), { description = "Open terminal" })

-- Monitor focus (scroll wheel)
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ monitor = "+1" }), { mouse = true, description = "Focus next monitor" })
hl.bind(
	mod .. " + mouse_down",
	hl.dsp.focus({ monitor = "-1" }),
	{ mouse = true, description = "Focus previous monitor" }
)

-- Scrolling layout: promote and column moves
hl.bind(mod .. " + SHIFT + T", hl.dsp.layout("promote"), { description = "Promote window (scrolling layout)" })
hl.bind(mod .. " + CTRL + H", hl.dsp.layout("movewindow l"), { description = "Move window left one column" })
hl.bind(mod .. " + CTRL + L", hl.dsp.layout("movewindow r"), { description = "Move window right one column" })

-- Focus movement
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "l" }), { description = "Focus window left" })
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "d" }), { description = "Focus window below" })
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "u" }), { description = "Focus window above" })
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "r" }), { description = "Focus window right" })

-- Window movement / column swaps
hl.bind(mod .. " + SHIFT + H", hl.dsp.layout("swapcol l"), { description = "Swap column left" })
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }), { description = "Move window down" })
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }), { description = "Move window up" })
hl.bind(mod .. " + SHIFT + L", hl.dsp.layout("swapcol r"), { description = "Swap column right" })

-- Screenshot submap
hl.bind(mod .. " + CTRL + SHIFT + P", hl.dsp.submap("screenshot"), { description = "Enter screenshot mode" })
hl.bind("Print", hl.dsp.submap("screenshot"), { description = "Enter screenshot mode" })

hl.define_submap("screenshot", function()
	hl.bind("S", hl.dsp.exec_cmd("grimblast -t png copysave area"), { description = "[Screenshot] Copy/save area" })
	hl.bind("E", hl.dsp.exec_cmd("grimblast -t png edit area"), { description = "[Screenshot] Edit area" })
	hl.bind(
		"A",
		hl.dsp.exec_cmd("grimblast -t png copysave active"),
		{ description = "[Screenshot] Copy/save active window" }
	)
	-- With delay
	hl.bind(
		mod .. " + S",
		hl.dsp.exec_cmd("grimblast -w 3 -t png copysave area"),
		{ description = "[Screenshot] Copy/save area (3s delay)" }
	)
	hl.bind(
		mod .. " + E",
		hl.dsp.exec_cmd("grimblast -w 3 -t png edit area"),
		{ description = "[Screenshot] Edit area (3s delay)" }
	)
	hl.bind(
		mod .. " + A",
		hl.dsp.exec_cmd("grimblast -w 3 -t png copysave active"),
		{ description = "[Screenshot] Copy/save active (3s delay)" }
	)
	hl.bind("catchall", hl.dsp.submap("reset"))
	hl.bind("escape", hl.dsp.submap("reset"), { description = "[Screenshot] Exit screenshot mode" })
end)

-- Resize submap
hl.bind(mod .. " + R", hl.dsp.submap("resize"), { description = "Enter resize mode" })

hl.define_submap("resize", function()
	hl.bind(mod .. " + H", hl.dsp.focus({ direction = "l" }), { description = "[Resize] Focus left" })
	hl.bind(mod .. " + J", hl.dsp.focus({ direction = "d" }), { description = "[Resize] Focus below" })
	hl.bind(mod .. " + K", hl.dsp.focus({ direction = "u" }), { description = "[Resize] Focus above" })
	hl.bind(mod .. " + L", hl.dsp.focus({ direction = "r" }), { description = "[Resize] Focus right" })

	hl.bind(
		"L",
		hl.dsp.window.resize({ x = 25, y = 0, relative = true }),
		{ repeating = true, description = "[Resize] Grow width" }
	)
	hl.bind(
		"H",
		hl.dsp.window.resize({ x = -25, y = 0, relative = true }),
		{ repeating = true, description = "[Resize] Shrink width" }
	)
	hl.bind(
		"K",
		hl.dsp.window.resize({ x = 0, y = -25, relative = true }),
		{ repeating = true, description = "[Resize] Shrink height" }
	)
	hl.bind(
		"J",
		hl.dsp.window.resize({ x = 0, y = 25, relative = true }),
		{ repeating = true, description = "[Resize] Grow height" }
	)

	-- Column width presets via layoutmsg colresize (reliable in scrolling layout)
	hl.bind("1", hl.dsp.layout("colresize 100"), { repeating = true, description = "[Resize] Column width 100%" })
	hl.bind("2", hl.dsp.layout("colresize 50"), { repeating = true, description = "[Resize] Column width 50%" })
	hl.bind("3", hl.dsp.layout("colresize 33"), { repeating = true, description = "[Resize] Column width 33%" })
	hl.bind("4", hl.dsp.layout("colresize 25"), { repeating = true, description = "[Resize] Column width 25%" })

	hl.bind("U", hl.dsp.layout("colresize -conf"), { repeating = true, description = "[Resize] Decrease column width" })
	hl.bind("I", hl.dsp.layout("colresize +conf"), { repeating = true, description = "[Resize] Increase column width" })

	hl.bind("escape", hl.dsp.submap("reset"), { description = "[Resize] Exit resize mode" })
end)

-- Scrolling fit submap
hl.bind(mod .. " + CTRL + F", hl.dsp.submap("fit"), { description = "Enter fit mode" })

hl.define_submap("fit", function()
	hl.bind("F", hl.dsp.layout("fit all"), { description = "[Fit] Fit all windows" })
	hl.bind("V", hl.dsp.layout("fit visible"), { description = "[Fit] Fit visible windows" })
	hl.bind("A", hl.dsp.layout("fit active"), { description = "[Fit] Fit active window" })
	hl.bind("B", hl.dsp.layout("fit tobeg"), { description = "[Fit] Fit to beginning" })
	hl.bind("E", hl.dsp.layout("fit toend"), { description = "[Fit] Fit to end" })

	hl.bind("escape", hl.dsp.submap("reset"), { description = "[Fit] Exit fit mode" })
end)

-- Tab groups submap
hl.bind(mod .. " + T", hl.dsp.submap("tabgroups"), { description = "Enter tab groups mode" })

hl.define_submap("tabgroups", function()
	hl.bind("T", hl.dsp.exec_cmd("hyprctl dispatch togglegroup"), { description = "[Tabs] Create / dissolve group" })
	hl.bind(
		"U",
		hl.dsp.exec_cmd("hyprctl dispatch moveoutofgroup"),
		{ description = "[Tabs] Extract window from group" }
	)

	-- Cycle tabs (h/k = previous, l/j = next)
	hl.bind("H", hl.dsp.exec_cmd("hyprctl dispatch changegroupactive b"), { description = "[Tabs] Previous tab" })
	hl.bind("K", hl.dsp.exec_cmd("hyprctl dispatch changegroupactive b"), { description = "[Tabs] Previous tab" })
	hl.bind("L", hl.dsp.exec_cmd("hyprctl dispatch changegroupactive f"), { description = "[Tabs] Next tab" })
	hl.bind("J", hl.dsp.exec_cmd("hyprctl dispatch changegroupactive f"), { description = "[Tabs] Next tab" })

	-- Move window into adjacent group
	hl.bind(
		"SHIFT + H",
		hl.dsp.exec_cmd("hyprctl dispatch movewindoworgroup l"),
		{ description = "[Tabs] Move window into left group" }
	)
	hl.bind(
		"SHIFT + J",
		hl.dsp.exec_cmd("hyprctl dispatch movewindoworgroup d"),
		{ description = "[Tabs] Move window into group below" }
	)
	hl.bind(
		"SHIFT + K",
		hl.dsp.exec_cmd("hyprctl dispatch movewindoworgroup u"),
		{ description = "[Tabs] Move window into group above" }
	)
	hl.bind(
		"SHIFT + L",
		hl.dsp.exec_cmd("hyprctl dispatch movewindoworgroup r"),
		{ description = "[Tabs] Move window into right group" }
	)

	hl.bind("escape", hl.dsp.submap("reset"), { description = "[Tabs] Exit tab groups mode" })
end)

-- Move workspace to monitor
hl.bind(
	mod .. " + CTRL + SHIFT + H",
	hl.dsp.workspace.move({ monitor = "l" }),
	{ description = "Move workspace to left monitor" }
)
hl.bind(
	mod .. " + CTRL + SHIFT + J",
	hl.dsp.workspace.move({ monitor = "d" }),
	{ description = "Move workspace to monitor below" }
)
hl.bind(
	mod .. " + CTRL + SHIFT + K",
	hl.dsp.workspace.move({ monitor = "u" }),
	{ description = "Move workspace to monitor above" }
)
hl.bind(
	mod .. " + CTRL + SHIFT + L",
	hl.dsp.workspace.move({ monitor = "r" }),
	{ description = "Move workspace to right monitor" }
)

-- Special workspaces
hl.bind(
	mod .. " + B",
	hl.dsp.workspace.toggle_special("scratch_hidden"),
	{ description = "Toggle hidden scratch workspace" }
)
hl.bind(
	mod .. " + SHIFT + B",
	hl.dsp.window.move({ workspace = "special:scratch_hidden" }),
	{ description = "Move window to hidden scratch workspace" }
)
hl.bind(
	mod .. " + G",
	hl.dsp.workspace.toggle_special("scratch_games"),
	{ description = "Toggle games scratch workspace" }
)
hl.bind(
	mod .. " + SHIFT + G",
	hl.dsp.window.move({ workspace = "special:scratch_games" }),
	{ description = "Move window to games scratch workspace" }
)
hl.bind(
	mod .. " + X",
	hl.dsp.workspace.toggle_special("scratch_messaging"),
	{ description = "Toggle messaging scratch workspace" }
)
hl.bind(
	mod .. " + SHIFT + X",
	hl.dsp.window.move({ workspace = "special:scratch_messaging" }),
	{ description = "Move window to messaging scratch workspace" }
)

-- Relative workspace navigation
hl.bind(mod .. " + right", hl.dsp.focus({ workspace = "r+1" }), { description = "Switch to next workspace" })
hl.bind(mod .. " + left", hl.dsp.focus({ workspace = "r-1" }), { description = "Switch to previous workspace" })
hl.bind(
	mod .. " + SHIFT + right",
	hl.dsp.window.move({ workspace = "r+1" }),
	{ description = "Move window to next workspace" }
)
hl.bind(
	mod .. " + SHIFT + left",
	hl.dsp.window.move({ workspace = "r-1" }),
	{ description = "Move window to previous workspace" }
)

-- Named workspace shortcuts
local named_workspaces = {
	U = 1,
	I = 2,
	O = 3,
	P = 4,
	M = 11,
	comma = 12,
	period = 13,
	slash = 14,
}
for key, ws in pairs(named_workspaces) do
	hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = ws }), { description = "Switch to workspace " .. ws })
	hl.bind(
		mod .. " + SHIFT + " .. key,
		hl.dsp.window.move({ workspace = ws }),
		{ description = "Move window to workspace " .. ws }
	)
end

-- Numeric workspace shortcuts (1–10)
for i = 1, 9 do
	hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }), { description = "Switch to workspace " .. i })
	hl.bind(
		mod .. " + SHIFT + " .. i,
		hl.dsp.window.move({ workspace = i }),
		{ description = "Move window to workspace " .. i }
	)
end
hl.bind(mod .. " + 0", hl.dsp.focus({ workspace = 10 }), { description = "Switch to workspace 10" })
hl.bind(mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }), { description = "Move window to workspace 10" })

-- Launchers
hl.bind("ALT + SPACE", hl.dsp.exec_cmd(menu), { description = "Open application launcher" })
hl.bind(mod .. " + CTRL + SPACE", hl.dsp.exec_cmd("hyprlauncher"), { description = "Open Hypr launcher" })

-- Audio / media
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ description = "Volume up" }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ description = "Volume down" }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { description = "Toggle mute" })
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ description = "Toggle microphone mute" }
)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { description = "Play / pause media" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { description = "Next media track" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { description = "Previous media track" })
hl.bind("XF86audiostop", hl.dsp.exec_cmd("playerctl stop"), { description = "Stop media" })

-- Brightness (zenbook)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { description = "Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { description = "Brightness down" })

-- Submap border colour: driven by the keybinds.submap event to avoid the
-- async race condition of exec_cmd (which fires before the submap changes).
-- The event fires on every submap transition; name == "" means default (reset).
local submap_colors = {
	resize = colors.resize_active_border,
	fit = colors.fit_active_border,
	tabgroups = colors.fit_active_border,
}
hl.on("keybinds.submap", function(name)
	hl.config({ general = {
		["col.active_border"] = submap_colors[name] or colors.normal_active_border,
	} })
end)
