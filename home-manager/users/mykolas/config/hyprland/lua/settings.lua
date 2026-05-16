local colors = require("lua/colors")

hl.config({
	general = {
		allow_tearing = true,
		border_size = 4,
		gaps_in = 2,
		gaps_out = 2,
		no_focus_fallback = true,
		resize_on_border = false,
		extend_border_grab_area = 0,
		layout = "scrolling",
		["col.inactive_border"] = colors.inactive_border,
		["col.nogroup_border"] = colors.nogroup_border,
		["col.active_border"] = colors.normal_active_border,
		["col.nogroup_border_active"] = colors.nogroup_border_active,
	},
	scrolling = {
		column_width = 0.5,
		focus_fit_method = 1,
	},
	decoration = {
		rounding = 20,
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
	},
	plugin = {},
})

-- Layer rules
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })
hl.layer_rule({ match = { namespace = "hyprpicker" }, no_anim = true })

-- Bezier curves
hl.curve("windowIn", { type = "bezier", points = { { 0.06, 0.71 }, { 0.25, 1 } } })
hl.curve("windowResize", { type = "bezier", points = { { 0.04, 0.67 }, { 0.38, 1 } } })
hl.curve("workspacesMove", { type = "bezier", points = { { 0.1, 0.75 }, { 0.15, 1 } } })

-- Animations
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "windowIn", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "windowIn", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.5, bezier = "windowResize" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "workspacesMove", style = "slide" })
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
