-- 3-finger gestures
hl.gesture({ fingers = 3, direction = "pinch", action = "float" })
hl.gesture({ fingers = 3, direction = "right", action = function() hl.dispatch(hl.dsp.window.move({ direction = "r" })) end })
hl.gesture({ fingers = 3, direction = "left",  action = function() hl.dispatch(hl.dsp.window.move({ direction = "l" })) end })
hl.gesture({ fingers = 3, direction = "up",    action = function() hl.dispatch(hl.dsp.window.move({ direction = "u" })) end })
hl.gesture({ fingers = 3, direction = "down",  action = function() hl.dispatch(hl.dsp.window.move({ direction = "d" })) end })

-- 4-finger gestures
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "pinch", action = function() hl.dispatch(hl.dsp.exec_cmd("hyprctl dispatch hyprexpo:expo toggle")) end })
hl.gesture({ fingers = 4, direction = "up",    action = function() hl.dispatch(hl.dsp.exec_cmd("hyprctl dispatch hyprexpo:expo on"))     end })
hl.gesture({ fingers = 4, direction = "down",  action = function() hl.dispatch(hl.dsp.exec_cmd("hyprctl dispatch hyprexpo:expo off"))    end })
