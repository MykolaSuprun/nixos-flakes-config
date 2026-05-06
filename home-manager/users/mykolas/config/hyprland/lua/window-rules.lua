-- Each entry is { match = { <prop> = <pattern>, ... }, [overrides...] }.
-- The match table accepts any Hyprland match property: class, title,
-- initial_title, initial_class, tag, xwayland, float, etc.
-- Per-entry override fields (size, workspace, center, …) extend or replace
-- the shared effects for that entry only; nil fields are silently ignored.

-- ── Games ─────────────────────────────────────────────────────────────────────
-- Shared effects: immediate (tearing), fullscreen, sent to scratch_games.
-- Toggle the workspace with mod+G.
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
	{ match = { class = "^(steam_app_2623190)$" } }, -- oblivion remastered
}

for _, entry in ipairs(games) do
	hl.window_rule({
		match            = entry.match,
		immediate        = true,
		fullscreen       = true,
		fullscreen_state = "3 3",
		workspace        = "special:scratch_games",
	})
end

-- ── App workspace assignments ─────────────────────────────────────────────────
-- Each entry: { match = {...}, workspace = "<id>" }
local workspace_assignments = {
	{ match = { class         = "^(zen-beta)$" },                workspace = "1"  },
	{ match = { class         = "^(org\\.telegram\\.desktop)$" },  workspace = "4"  },
	{ match = { class         = "^(chromium-browser)$" },         workspace = "7"  },
	{ match = { initial_title = "^((s|S)team)$" },                workspace = "13" },
}

for _, entry in ipairs(workspace_assignments) do
	hl.window_rule({ match = entry.match, workspace = entry.workspace })
end

-- ── Floating utility windows ──────────────────────────────────────────────────
-- Shared effects: float, pseudo.
-- Optional per-entry `center = true` for windows that should open centered.
local floating_utils = {
	{ match = { class = "^(steam)$" },                         center = true },
	{ match = { class = "^(kitty-dropterm)$" } },
	{ match = { class = "^(com\\.saivert\\.pwvucontrol)$" } },
}

for _, entry in ipairs(floating_utils) do
	hl.window_rule({ match = entry.match, float = true, pseudo = true, center = entry.center })
end

-- ── Priority floating dialogs ─────────────────────────────────────────────────
-- Shared effects: float, center, pin, stay_focused.
-- Optional per-entry `size` for windows that need a specific size.
local priority_floating = {
	{ match = { class = "^(org\\.kde\\.ksecretd)$" } },
	{ match = { class = "^(nm-applet)$" } },
	{ match = { class = "^(clipse)$" },  size = { "40%", "30%" } },
	{ match = { title = "clipse" },       size = { "40%", "30%" } },
}

for _, entry in ipairs(priority_floating) do
	hl.window_rule({
		match        = entry.match,
		float        = true,
		center       = true,
		pin          = true,
		stay_focused = true,
		size         = entry.size,
	})
end

-- KDE portal file picker — force float+center on creation, then override
-- the portal's self-resize to fullscreen via an openwindow callback.
-- The 0.15s delay lets the portal finish its own layout first.
hl.window_rule({
	match        = { class = "^(org\\.freedesktop\\.impl\\.portal\\.desktop\\.kde)$" },
	float        = true,
	center       = true,
	pin          = true,
	stay_focused = true,
	size         = { "60%", "60%" },
})

hl.on("window.open", function(win)
	if win and win.class == "org.freedesktop.impl.portal.desktop.kde" then
		hl.exec_cmd(
			"sh -c 'sleep 0.15 && " ..
			"hyprctl dispatch resizewindowpixel exact 60% 60%,class:org.freedesktop.impl.portal.desktop.kde && " ..
			"hyprctl dispatch centerwindow class:org.freedesktop.impl.portal.desktop.kde'"
		)
	end
end)

-- ── System tray / hidden scratch workspace ────────────────────────────────────
-- These apps run silently in special:scratch_hidden; toggle with mod+B.
local scratch_hidden = {
	{ match = { class         = "^(nz\\.co\\.mega\\.)$" } },
	{ match = { initial_title = "Cryptomator" } },
	{ match = { class         = "^(xwaylandvideobridge)$" } },
	{ match = { initial_title = "^(Filen)$" } },
}

for _, entry in ipairs(scratch_hidden) do
	hl.window_rule({ match = entry.match, float = true, workspace = "special:scratch_hidden" })
end
