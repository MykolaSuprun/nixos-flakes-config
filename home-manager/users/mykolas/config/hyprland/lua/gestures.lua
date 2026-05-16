-- 3-finger gestures
hl.gesture({ fingers = 3, direction = "pinch", action = "float" })
local dirs_3f = { right = "r", left = "l", up = "u", down = "d" }
for gesture_dir, hypr_dir in pairs(dirs_3f) do
	hl.gesture({ fingers = 3, direction = gesture_dir, action = function()
		hl.dispatch(hl.dsp.window.move({ direction = hypr_dir }))
	end })
end

-- 4-finger gestures
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "pinch", action = function() hl.dispatch(hl.dsp.exec_cmd("hyprctl dispatch hyprexpo:expo toggle")) end })
hl.gesture({ fingers = 4, direction = "up",    action = function() hl.dispatch(hl.dsp.exec_cmd("hyprctl dispatch hyprexpo:expo on"))     end })
hl.gesture({ fingers = 4, direction = "down",  action = function() hl.dispatch(hl.dsp.exec_cmd("hyprctl dispatch hyprexpo:expo off"))    end })
