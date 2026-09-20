---
status: active
item: lua:tape custom Hyprland layout
started: 2026-09-20
---

# NixConf Hyprland Backlog

Domain memory for Hyprland/window-management work in this repo.

## Current Item

**lua:tape custom layout — implemented, wired, live-validated**

## State (flattened 2026-09-20)

### What was built
- New file `home-manager/users/mykolas/config/hyprland/lua/tape-layout.lua` — custom
  tiling layout registered via `hl.layout.register("tape", ...)`, an infinite
  horizontal tape of columns with vertical stacking (niri / built-in scrolling style).
- `hyprland-dynamic.lua` requires it (inert until a workspace uses `lua:tape`).
- `settings.lua` flips `general.layout` from `scrolling` → `lua:tape` (other layouts
  stay per-workspace via hypr-layout-picker; picker list updated in
  `flake/packages/hypr-layout-picker.nix`).
- `binds.lua` wiring: Mod+F → tape `maximize` (native maximized elsewhere),
  Mod+Shift+F stays true exclusive fullscreen, Mod+H/J/K/L focus (u/d = within stack),
  Mod+Shift+T promote, Mod+Shift+H/L swapcol, Mod+Shift+K/J reorder within stack,
  Mod+Ctrl+H/L niri smart move (into adjacent column / as own column).
  The old `fit_visible_if_needed` exec-hack on window.close/move was REMOVED
  (tape auto-rebalances; scrolling fallback has the fit submap manually).

### Key decisions (decision gate)
- Approach chosen: full custom Lua layout (approach C) over config-only (A) and
  built-in scrolling + Lua automation (B).
- Column budget is per monitor by aspect ratio: `w/h >= 2.0` (ultrawide like
  geks-nixos main) → 3 columns; otherwise (zenbook panels) → 2. n ≤ budget →
  even 1/n squash; n > budget → 1/budget columns, tape scrolls; 1 window → full screen.
- Maximize: `maximize` layoutmsg stores the column's width and pins it to 100%;
  second toggle restores the exact previous width — works around upstream
  hyprwm/Hyprland#14380 (built-in scrolling can't unmaximize; vaxerski: "shorthand
  for expel + width 1"). Stack members maximize together (niri-style).
- Manual width overrides (colresize) survive count changes; `reset`/`fit` clear them.
- layout_msg vocabulary mirrors built-in scrolling (focus/swapcol/colresize/fit/
  consume/expel/promote/center) + additions: maximize, move l|r|u|d, movecol,
  reset, fit_active_view, view/scroll.
- Focus-follow viewport driven by `hl.on("window.active")` → self-dispatched
  `fit_active_view` message (recalculate is not guaranteed on focus changes).

### Validated
- stylua clean; `hyprctl reload` with zero Lua errors; live flip
  scrolling → lua:tape → scrolling OK; after settings.lua flip the active
  workspace reports `tiledLayout: lua:tape`.
- Nix dry-run build of geks-nixos toplevel passed.
- User confirmed: "Basic logic seems to work as it should."

### Notes / caveats
- The symlink `~/.config/hypr/lua/tape-layout.lua` was created manually for live
  testing; the next home-manager activation formalizes it via live-links
  (filter `*.lua` already covers it).
- No touchpad tape-swipe gestures with a custom layout (keyboard-driven only) —
  accepted loss.
- Columns ≠ tab groups: Mod+T group submap untouched and independent.
- `consume`/`expel` messages exist but are currently unbound.

### Next actions
- Daily-drive it; tune ULTRAWIDE_ASPECT / budgets if other monitors misbehave.
- Consider binding consume/expel if smart-move proves insufficient.

### Resume point
Nothing pending — task complete, committed as `lua:tape` feature commit.
Re-read this file + `tape-layout.lua` header before further layout work.
