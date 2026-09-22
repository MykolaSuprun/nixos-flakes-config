-- tape-layout.lua — custom tiling layout registered as "lua:tape".
--
-- An infinite horizontal "tape" of columns (niri / built-in scrolling style),
-- implemented via hl.layout.register. Each column stacks its member windows
-- vertically. Windows off the visible portion simply live on the tape.
--
-- Width rules (automatic, per monitor):
--   budget   = 3 on ultrawide work areas (aspect >= 2.0, e.g. geks-nixos main),
--              2 on all other displays (e.g. both zenbook panels)
--   1 column           -> fills the screen
--   n <= budget        -> every column is 1/n (even squash, whole screen)
--   n > budget         -> every column is 1/budget, the tape scrolls
-- colresize / fit active set per-column manual overrides; the rules above only
-- ever repack columns without an override. "reset" / "fit" clear overrides.
--
-- Mod+F "maximize": pins the active column to 100% width and brings it fully
-- into view. Toggling again restores the exact pre-maximize width (works
-- around hyprwm/Hyprland#14380, where the built-in scrolling layout cannot
-- unmaximize). Stack members are maximized together, niri-style.
--
-- layout_msg vocabulary mirrors the built-in "scrolling" layout so existing
-- binds keep working, plus two additions:
--   maximize          toggle column maximize with width restore (see above)
--   move l|r          niri smart move: out of a stack into the adjacent column,
--                     or as its own new column at the tape end/edge
--   move u|d          reorder the window within its column stack
--   movecol l|r       whole-column swap (alias of swapcol)
--   reset             clear all width overrides, re-apply the width rules
--   fit_active_view   internal: scroll the viewport to the focused column
--                     (driven by the window.active event below)
--
-- Commands shared with scrolling: focus l|r|u|d, swapcol l|r, consume,
-- expel, promote, center, move <±px|±col>, colresize <v|±v|+conf|-conf|all v>,
-- fit active|visible|all|toend|tobeg.

local PRESETS = { 0.25, 1 / 3, 0.5, 2 / 3, 0.75, 1.0 }
local ULTRAWIDE_ASPECT = 2.0 -- work-area w/h at or above this counts as ultrawide
local WIDE_BUDGET = 3
local NARROW_BUDGET = 2
local MIN_WIDTH = 0.1

-- Per-workspace layout state. ctx only carries the current frame's targets, so
-- ordering, stacks, widths, overrides and the viewport live here, keyed by
-- workspace id (targets are authoritative for which windows still exist).
local workspaces = {}

local function clamp(x, lo, hi)
	return math.max(lo, math.min(hi, x))
end

local function target_id(target)
	local w = target.window
	return w and w.stable_id or ("tmp:" .. tostring(target.index))
end

local function budget(area)
	if area.h > 0 and area.w / area.h >= ULTRAWIDE_ASPECT then
		return WIDE_BUDGET
	end
	return NARROW_BUDGET
end

-- Rule width for a monitor with n columns: 1/n up to the budget, 1/budget past it.
local function rule_width(area, n)
	return 1 / math.max(1, math.min(n, budget(area)))
end

local function col_width_px(st, area, col)
	return (col.width or rule_width(area, #st.columns)) * area.w
end

local function col_left_px(st, area, ci)
	local left = 0
	for i = 1, ci - 1 do
		left = left + col_width_px(st, area, st.columns[i])
	end
	return left
end

local function tape_width_px(st, area)
	return col_left_px(st, area, #st.columns + 1)
end

local function clamp_view(st, area)
	local total = tape_width_px(st, area)
	st.view = clamp(st.view, 0, math.max(0, total - area.w))
end

-- Minimal viewport shift so column ci is fully visible (focus_fit_method = 1).
local function fit_view(st, area, ci)
	local col = st.columns[ci]
	if not col then
		return
	end
	local left = col_left_px(st, area, ci)
	local right = left + col_width_px(st, area, col)
	if st.view > left then
		st.view = left
	end
	if st.view + area.w < right then
		st.view = right - area.w
	end
	clamp_view(st, area)
end

local function center_view(st, area, ci)
	local col = st.columns[ci]
	if not col then
		return
	end
	st.view = col_left_px(st, area, ci) + col_width_px(st, area, col) / 2 - area.w / 2
	clamp_view(st, area)
end

-- Column and member index of a window id (nil when absent).
local function column_of(st, id)
	for ci, col in ipairs(st.columns) do
		for mi, mid in ipairs(col.members) do
			if mid == id then
				return ci, mi
			end
		end
	end
end

-- Column containing the currently focused window; also refreshes last_active.
-- Returns nil when the focused window is not tiled here (e.g. a floater).
local function active_column(st, ctx)
	for ci, col in ipairs(st.columns) do
		for _, id in ipairs(col.members) do
			for _, t in ipairs(ctx.targets) do
				if target_id(t) == id and t.window and t.window.active then
					col.last_active = id
					return ci
				end
			end
		end
	end
end

-- Focused column, falling back to the last-seen one while a floating window
-- holds focus (so colresize/fit/maximize/move act on the intended column).
local function current_ci(st, ctx)
	local ci = active_column(st, ctx)
	if ci then
		st.last_ci = ci
	else
		ci = st.last_ci
	end
	return ci or 1
end

local function focus_window(ctx, id)
	for _, t in ipairs(ctx.targets) do
		if target_id(t) == id and t.window then
			hl.dispatch(hl.dsp.focus({ window = "address:" .. t.window.address }))
			return
		end
	end
end

-- Reconcile state with ctx.targets: drop closed windows, insert new windows
-- as their own column right after the focused column.
local function sync(st, ctx)
	local ids = {}
	-- nil-window targets (transient construction, some groups) are skipped:
	-- their tmp fallback id is index-based and would churn columns every recalc.
	for _, t in ipairs(ctx.targets) do
		if t.window then
			ids[target_id(t)] = true
		end
	end

	local kept = {}
	for _, col in ipairs(st.columns) do
		local members = {}
		for _, id in ipairs(col.members) do
			if ids[id] then
				members[#members + 1] = id
			end
		end
		if #members > 0 then
			col.members = members
			kept[#kept + 1] = col
		end
	end
	st.columns = kept

	local active_ci = active_column(st, ctx)
	local insert_at = active_ci or #st.columns
	local present = {}
	for _, col in ipairs(st.columns) do
		for _, id in ipairs(col.members) do
			present[id] = true
		end
	end
	for _, t in ipairs(ctx.targets) do
		if t.window then
			local id = target_id(t)
			if not present[id] then
				insert_at = insert_at + 1
				table.insert(st.columns, insert_at, { members = { id }, override = false })
			end
		end
	end
end

-- Apply the automatic width rules. Repacks on column-count or budget change;
-- columns with a manual override keep their width.
local function rebalance(st, area)
	local n = #st.columns
	local b = budget(area)
	local changed = (n ~= st.last_n) or (b ~= st.last_budget)
	st.last_n, st.last_budget = n, b
	if n == 0 then
		return
	end
	local w = rule_width(area, n)
	for _, col in ipairs(st.columns) do
		if col.width == nil or (changed and not col.override) then
			col.width = w
		end
	end
end

local function recalculate(ctx)
	if #ctx.targets == 0 then
		return
	end

	local first = ctx.targets[1].window
	local key = (first and first.workspace and first.workspace.id) or -1
	local st = workspaces[key]
	if not st then
		st = { columns = {}, view = 0, last_n = 0, last_budget = 0 }
		workspaces[key] = st
	end

	sync(st, ctx)
	rebalance(st, ctx.area)
	clamp_view(st, ctx.area)

	local targets = {}
	for _, t in ipairs(ctx.targets) do
		targets[target_id(t)] = t
	end

	local area = ctx.area
	local x = -st.view
	for _, col in ipairs(st.columns) do
		local wpx = col_width_px(st, area, col)
		local hpx = area.h / #col.members
		for mi, id in ipairs(col.members) do
			local t = targets[id]
			if t then
				t:place({ x = area.x + x, y = area.y + (mi - 1) * hpx, w = wpx, h = hpx })
			end
		end
		x = x + wpx
	end
end

local function layout_msg(ctx, msg)
	local cmd, arg = msg:match("^(%S+)%s*(.-)%s*$")
	if not cmd then
		return "tape: empty message"
	end

	local first = ctx.targets[1] and ctx.targets[1].window
	local key = (first and first.workspace and first.workspace.id) or -1
	local st = workspaces[key]
	if not st or #st.columns == 0 then
		return true
	end
	local area = ctx.area

	-- ── Focus ────────────────────────────────────────────────────────────────
	if cmd == "focus" then
		local ci = current_ci(st, ctx)
		if arg == "l" or arg == "r" then
			local n = #st.columns
			local ni = ((ci - 1 + (arg == "r" and 1 or -1)) % n) + 1 -- wrap, like scrolling
			local col = st.columns[ni]
			focus_window(ctx, col.last_active or col.members[1])
			fit_view(st, area, ni)
		elseif arg == "u" or arg == "d" then
			local col = st.columns[ci]
			local _, mi = column_of(st, col.last_active or col.members[1])
			local n = #col.members
			if mi and n > 1 then
				local ni = ((mi - 1 + (arg == "d" and 1 or -1)) % n) + 1
				focus_window(ctx, col.members[ni])
			end
			fit_view(st, area, ci)
		else
			return "tape: focus expects l|r|u|d"
		end
		return true
	end

	-- ── Column ordering ──────────────────────────────────────────────────────
	if cmd == "swapcol" or cmd == "movecol" then
		local ci = current_ci(st, ctx)
		local n = #st.columns
		local ni = ((ci - 1 + (arg == "r" and 1 or -1)) % n) + 1
		st.columns[ci], st.columns[ni] = st.columns[ni], st.columns[ci]
		fit_view(st, area, ni)
		return true
	end

	-- ── Window movement between columns ──────────────────────────────────────
	if cmd == "move" or cmd == "consume" or cmd == "expel" or cmd == "promote" then
		local aci = current_ci(st, ctx)
		local col = st.columns[aci]
		local id = col and (col.last_active or col.members[1])
		if not id then
			return true
		end
		local _, mi = column_of(st, id)

		-- Validate BEFORE detaching: an invalid arg must not mutate state.
		if cmd == "move" and not (arg == "l" or arg == "r" or arg == "u" or arg == "d") then
			return "tape: move expects l|r|u|d"
		end

		-- u/d: reorder the window within its own column stack (no detach)
		if cmd == "move" and (arg == "u" or arg == "d") then
			local n = #col.members
			if mi and n > 1 then
				local ni = clamp(mi + (arg == "d" and 1 or -1), 1, n)
				col.members[mi], col.members[ni] = col.members[ni], col.members[mi]
			end
			return true
		end

		-- Detach the window from its column (empty columns disappear).
		table.remove(col.members, mi)
		-- After removing the source column, old index aci+1 now sits at aci;
		-- earlier indices are unaffected. Track the shift explicitly.
		local removed = #col.members == 0
		if removed then
			table.remove(st.columns, aci)
		end

		local dest_col -- insert into an existing column...
		local dest_new -- ...or create a new column before this index
		if cmd == "move" then
			if arg == "l" then
				if aci == 1 then
					-- Left edge: stacked member becomes its own column before
					-- the edge; a sole-member column is already at the edge
					-- (insert at 1 after removal = structural no-op).
					dest_new = 1
				else
					-- Left neighbor's index is unaffected by any removal shift.
					dest_col = st.columns[aci - 1]
					dest_new = aci - 1
				end
			else -- arg == "r"
				-- Removal-shifted right neighbor now sits at aci, not aci + 1.
				local r = removed and aci or aci + 1
				dest_col = st.columns[r]
				dest_new = math.min(#st.columns + 1, r)
			end
		elseif cmd == "consume" then
			dest_col = st.columns[aci - 1]
			dest_new = aci
		elseif cmd == "expel" or cmd == "promote" then
			-- A sole-member column already IS its own column; re-inserting at
			-- aci keeps it in place (at aci + 1 it would creep right by one).
			dest_new = removed and aci or aci + 1
		end

		if dest_col then
			table.insert(dest_col.members, id)
		else
			table.insert(st.columns, dest_new, { members = { id }, override = false })
		end

		local nci = select(1, column_of(st, id))
		if nci then
			st.columns[nci].last_active = id
			fit_view(st, area, nci)
		end
		return true
	end

	-- ── Viewport ─────────────────────────────────────────────────────────────
	if cmd == "fit_active_view" then
		-- Only nudge the viewport when a TILED window holds focus; with a
		-- floater focused (active_column = nil) the tape must stay put.
		local ci = active_column(st, ctx)
		if ci then
			fit_view(st, area, ci)
		end
		return true
	end

	if cmd == "center" then
		center_view(st, area, current_ci(st, ctx))
		return true
	end

	-- Viewport shift (scrolling layout calls this "move ±px/±col"; we use
	-- "view"/"scroll" because "move l|r" is the smart window move above).
	if cmd == "view" or cmd == "scroll" then
		if arg:match("col$") then
			local ci = current_ci(st, ctx)
			local step = col_width_px(st, area, st.columns[ci])
			st.view = st.view + (arg:sub(1, 1) == "-" and -step or step)
		else
			st.view = st.view + (tonumber(arg) or 0)
		end
		clamp_view(st, area)
		return true
	end

	-- ── Column widths ────────────────────────────────────────────────────────
	if cmd == "colresize" then
		local allw = arg:match("^all%s+(%S+)$")
		if allw then
			local v = clamp(tonumber(allw) or 0.5, MIN_WIDTH, 1.0)
			for _, col in ipairs(st.columns) do
				col.width, col.override, col.saved = v, true, nil
			end
			clamp_view(st, area)
			return true
		end

		local ci = current_ci(st, ctx)
		local col = st.columns[ci]
		if not col then
			return true
		end
		local w = col_width_px(st, area, col) / area.w

		if arg == "+conf" or arg == "-conf" then
			local best
			for _, p in ipairs(PRESETS) do
				if arg == "+conf" and p > w + 0.01 and (not best or p < best) then
					best = p
				elseif arg == "-conf" and p < w - 0.01 and (not best or p > best) then
					best = p
				end
			end
			col.width = best or (arg == "+conf" and PRESETS[#PRESETS] or PRESETS[1])
		elseif arg:match("^[+-]") then
			col.width = clamp(w + tonumber(arg), MIN_WIDTH, 1.0)
		else
			col.width = clamp(tonumber(arg) or w, MIN_WIDTH, 1.0)
		end
		col.override, col.saved = true, nil
		fit_view(st, area, ci)
		return true
	end

	-- ── Fit operations ───────────────────────────────────────────────────────
	if cmd == "fit" then
		local ci = current_ci(st, ctx)
		local n = #st.columns

		if arg == "active" then
			local col = st.columns[ci]
			col.width, col.override, col.saved = 1.0, true, nil
			fit_view(st, area, ci)
			return true
		end

		local lo, hi
		if arg == "all" then
			lo, hi = 1, n
		elseif arg == "tobeg" then
			lo, hi = 1, ci
		elseif arg == "toend" then
			lo, hi = ci, n
		elseif arg == "visible" then
			lo, hi = n, 1
			for i = 1, n do
				local left = col_left_px(st, area, i)
				local right = left + col_width_px(st, area, st.columns[i])
				if left < st.view + area.w and right > st.view then
					lo, hi = math.min(lo, i), math.max(hi, i)
				end
			end
			if lo > hi then
				lo, hi = ci, ci -- view drifted outside the tape: fit active column
			end
		else
			return "tape: fit expects active|visible|all|toend|tobeg"
		end

		local w = clamp(1 / (hi - lo + 1), MIN_WIDTH, 1.0)
		for i = lo, hi do
			local col = st.columns[i]
			col.width, col.override, col.saved = w, false, nil
		end
		st.view = col_left_px(st, area, lo) -- align the fitted range to the left edge
		clamp_view(st, area)
		return true
	end

	if cmd == "reset" then
		for _, col in ipairs(st.columns) do
			col.width, col.override, col.saved = nil, false, nil
		end
		st.last_n = -1 -- force the width rules to re-apply on this recalc
		return true
	end

	-- ── Maximize (column) with width restore ────────────────────────────────
	if cmd == "maximize" then
		local ci = current_ci(st, ctx)
		local col = st.columns[ci]
		if not col then
			return true
		end
		if col.saved then
			col.width, col.override = col.saved.width, col.saved.override
			col.saved = nil
		else
			col.saved = { width = col.width, override = col.override }
			col.width, col.override = 1.0, true
		end
		fit_view(st, area, ci)
		return true
	end

	return "tape: unknown command '" .. msg .. "'"
end

hl.layout.register("tape", {
	recalculate = recalculate,
	layout_msg = layout_msg,
})

-- Focus-follow: scroll the tape so a newly focused column is fully visible.
-- recalculate is not guaranteed to run on focus changes, so the viewport is
-- nudged through the layout's own message handler.
hl.on("window.active", function()
	local ws = hl.get_active_workspace()
	if ws and ws.tiled_layout == "lua:tape" then
		hl.dispatch(hl.dsp.layout("fit_active_view"))
	end
end)
