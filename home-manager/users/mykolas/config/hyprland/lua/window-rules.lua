local fullscreen_apps = {
	["steam"] = true,
	["cider"] = true,
	["LM-Studio"] = true,
}

-- Only run once per window
local done = {}

hl.on("window.active", function(w)
	if fullscreen_apps[w.class] and not done[w.address] then
		done[w.address] = true
		hl.dispatch(hl.dsp.window.fullscreen())
	end
end)

hl.on("window.close", function(w)
	done[w.address] = nil
end)

-- ── Scratchpad Assignments ────────────────────────────────────────────────────
-- Define just the identifier; the logic prepends 'special:scratch_'
local scratchpad_assignments = {
	-- Format: { match = {...}, id = "suffix" }
	{ match = { class = "^(org\\.telegram\\.desktop)$" }, id = "messaging" },
	{ match = { class = "^(com.ayugram.desktop)$" }, id = "messaging" },
	{ match = { class = "^(discord|vesktop|webcord)$" }, id = "messaging" },
	{ match = { class = "^LM-Studio$" }, id = "llm" },
	{ match = { class = "^(cider)$" }, id = "music" },
	{ match = { class = "^(nz\\.co\\.mega\\.)$" }, id = "hidden" },
	{ match = { initial_title = "Cryptomator" }, id = "hidden" },
	{ match = { initial_title = "^(Filen)$" }, id = "hidden", pseudo = true },
	{ match = { class = "^(steam)$" }, id = "games" },
	{ match = { class = "^(zen-beta)$" }, id = "zen" },
}

for _, entry in ipairs(scratchpad_assignments) do
	hl.window_rule({
		match = entry.match,
		float = false,
		tile = true,
		workspace = "special:scratch_" .. entry.id .. " silent",
		no_initial_focus = true,
		-- pseudo = entry.pseudo or false,
	})
end

-- ── Game Workspaces ───────────────────────────────────────────────────────────
local games = {
	{ match = { class = "^(gamescope)$" } },
	{ match = { class = "^(steam_app_1903340)$" } },
	{ match = { class = "^(steam_app_990080)$" } },
	{ match = { class = "^(steam_app_3489700)$" } },
	{ match = { class = "^(steam_app_3564860)$" } },
	{ match = { class = "^(titanfall)$" } },
	{ match = { class = "^(bioshock)$" } },
	{ match = { class = "^(helldivers)$" } },
	{ match = { class = "^(overwatch)$" } },
	{ match = { class = "^(steam_app_2767030)$" } },
	{ match = { class = "^(steam_app_2623190)$" } },
}

for _, entry in ipairs(games) do
	hl.window_rule({
		match = entry.match,
		immediate = true,
		fullscreen = true,
		-- fullscreen_state = "3 3",
		workspace = "special:scratch_games",
	})
end

-- ── App workspace assignments (Non-Scratch) ──────────────────────────────────
local workspace_assignments = {
	{ match = { class = "^(zen-beta)$" }, workspace = "1" },
	{ match = { class = "^(chromium-browser)$" }, workspace = "7" },
}

for _, entry in ipairs(workspace_assignments) do
	hl.window_rule({ match = entry.match, workspace = entry.workspace })
end

-- ── Floating/Utility Rules ───────────────────────────────────────────────────
hl.window_rule({ match = { class = "^(steam)$" }, float = true, center = true })
hl.window_rule({ match = { class = "^(kitty-dropterm)$" }, float = true, pseudo = true })
hl.window_rule({ match = { class = "^(com\\.saivert\\.pwvucontrol)$" }, float = true, pseudo = true })

-- ── Priority & Portals ───────────────────────────────────────────────────────
local priority = {
	{ match = { class = "^(org\\.kde\\.ksecretd)$" } },
	{ match = { class = "^(nm-applet)$" } },
	{ match = { class = "^(clipse)$" }, size = { 800, 560 } },
}

for _, entry in ipairs(priority) do
	hl.window_rule({
		match = entry.match,
		float = true,
		center = true,
		pin = true,
		stay_focused = true,
		size = entry.size,
	})
end

hl.window_rule({
	match = { class = "^(org\\.freedesktop\\.impl\\.portal\\.desktop\\.kde)$" },
	float = true,
	center = true,
	size = { "60%", "60%" },
	suppress_event = "maximize",
})

-- ── XWaylandVideoBridge ──────────────────────────────────────────────────────
hl.window_rule({
	match = { class = "^(xwaylandvideobridge)$" },
	workspace = "special:scratch_hidden silent",
	opacity = "0.0 override",
	no_anim = true,
	no_blur = true,
	no_focus = true,
	no_initial_focus = true,
	max_size = { 1, 1 },
})

-- ── Livepet (desktop pet animation layer) ────────────────────────────────────
-- S1 standalone Electron host: a floating, pinned, always-on-top pet window.
-- Launched via `electron --class=livepet-host …` — the generic electron
-- binary reports WM_CLASS "electron" unless --class is passed (measured
-- 2026-10-14); the rule matches BOTH so manual launches without --class
-- still float. Click-through stays off in v1 (the pet is draggable).
hl.window_rule({
	match = { class = "^(livepet-host)$" },
	float = true,
	pin = true,
	no_anim = true,
	no_blur = true,
	no_shadow = true,
	no_focus = true,
	no_initial_focus = true,
})
hl.window_rule({
	match = { class = "^(electron)$", title = "^(livepet-host)$" },
	float = true,
	pin = true,
	no_anim = true,
	no_blur = true,
	no_shadow = true,
	no_focus = true,
	no_initial_focus = true,
})
