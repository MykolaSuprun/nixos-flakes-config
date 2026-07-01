hl.on("hyprland.start", function()
	-- Services & Background Daemons
	hl.exec_cmd("uwsm app -s b -- clipse -listen")
	hl.exec_cmd("uwsm app -s b -- vivaldi", { workspace = "1 silent" })

	-- Regular Workspaces (Launched Silently via Workspace Flag)
	hl.exec_cmd("uwsm app -s a kitty", { workspace = "2 silent" })
	hl.exec_cmd("uwsm app -s a obsidian", { workspace = "11 silent" })

	-- Scratchpad Applications
	-- (Window rules handle hiding these completely in the background)
	hl.exec_cmd("uwsm app -s a -- AyuGram")
	hl.exec_cmd("uwsm app -s a cryptomator")
	hl.exec_cmd("uwsm app -s a filen-desktop")
	hl.exec_cmd("uwsm app -s a lm-studio")
	hl.exec_cmd("uwsm app -s a -- zen-beta --name zen-beta")
end)
