local colors = require("lua/colors")

hl.config({
	general = {
		allow_tearing = true,
		border_size = 4,
		-- Aligned with the qs-flow convex shell contract (reserved [8,40,8,8],
		-- frame cutout radius 40): gaps_out 8 matches the bezel, and rounding
		-- 32 = 40 - 8 keeps window corner arcs concentric inside the cutout so
		-- borders never overlap the shell frame.
		gaps_in = 4,
		gaps_out = 8,
		no_focus_fallback = true,
		resize_on_border = false,
		extend_border_grab_area = 0,
		-- lua:tape = custom layout (tape-layout.lua). scrolling/master/dwindle/
		-- monocle remain available per-workspace via hypr-layout-picker.
		layout = "lua:tape",
		["col.inactive_border"] = colors.inactive_border,
		["col.nogroup_border"] = colors.nogroup_border,
		["col.active_border"] = colors.normal_active_border,
		["col.nogroup_border_active"] = colors.nogroup_border_active,
	},
	scrolling = {
		column_width = 0.5,
		focus_fit_method = 1,
	},
	master = {
		allow_small_split = true,
		orientation = "center",
		mfact = 0.5,
	},
	decoration = {
		rounding = 32,
		inactive_opacity = 0.98,
		blur = {
			enabled = true,
			size = 7,
			passes = 4,
			noise = 0.008,
			contrast = 0.8916,
			brightness = 0.8,
			input_methods = true,
		},
		shadow = {
			enabled = true,
		},
	},
	animations = {
		enabled = true,
	},
	input = {
		follow_mouse = 1,
		sensitivity = -0.75,
		touchpad = {
			natural_scroll = true,
			disable_while_typing = true,
			tap_to_click = true,
			drag_lock = false,
			clickfinger_behavior = true,
			middle_button_emulation = false,
		},
	},
	gestures = {
		workspace_swipe_distance = 300,
		workspace_swipe_invert = true,
		workspace_swipe_min_speed_to_force = 30,
		workspace_swipe_cancel_ratio = 0.5,
		workspace_swipe_create_new = true,
		workspace_swipe_direction_lock = true,
		workspace_swipe_forever = false,
	},
	misc = {
		vrr = 1,
		disable_hyprland_logo = true,
		-- Let a session lock be restored/re-grabbed after compositor or lock
		-- client restarts instead of dropping the lock state.
		allow_session_lock_restore = 1,
	},
	plugin = {},
})

-- Layer rules
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })
hl.layer_rule({ match = { namespace = "hyprpicker" }, no_anim = true })
-- The palette owns its in-place reveal; a layer slide would move the whole surface.
hl.layer_rule({ match = { namespace = "^qs-flow-command-palette$" }, no_anim = true })

-- Bezier curves
hl.curve("windowIn", { type = "bezier", points = { { 0.06, 0.71 }, { 0.25, 1 } } })
hl.curve("windowResize", { type = "bezier", points = { { 0.04, 0.67 }, { 0.38, 1 } } })
hl.curve("workspacesMove", { type = "bezier", points = { { 0.1, 0.75 }, { 0.15, 1 } } })

-- Animations
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "windowIn", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "windowIn", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.5, bezier = "windowResize" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "workspacesMove", style = "slidevert" })
hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "windowIn", style = "slide" })

-- Devices
hl.device({
	name = "apple-inc.-magic-trackpad-1",
	sensitivity = 0.1,
	accel_profile = "adaptive",
	scroll_factor = 0.35,
})
hl.device({
	name = "apple-inc.-magic-trackpad",
	sensitivity = 0.1,
	accel_profile = "adaptive",
	scroll_factor = 0.35,
})
hl.device({
	name = "asue1212:00-04f3:3233-touchpad",
	sensitivity = 0.25,
	accel_profile = "adaptive",
	scroll_factor = 0.35,
})
