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

### Adversarial review 2026-09-20 (code trace + community research)

**Confirmed bugs:**
1. HIGH — smart-move skips columns when the SOURCE column empties. `move r` from a
   sole-member column detaches, `table.remove(st.columns, aci)` shifts indices,
   then reads `st.columns[aci+1]` = the column TWO over. Verified by logic sim:
   `[x][a,b][c] + move r` → `[[a,b],[c,x]]`, expected `[[a,b],[x],[c]]`.
2. HIGH — `fit_active_view` viewport snap on floating focus. `hl.on("window.active")`
   fires for floaters; active_column nil → `or 1` → fit_view(col 1) resets
   `st.view` to 0. Fix: no-op when active_column returns nil.
3. MED — move l at the leftmost edge: sole-member column removed, `math.max(1,aci-1)`
   = 1 = former RIGHT neighbor → window silently merges into the next column.
   Should be edge no-op (or new column before). Sim-verified.
4. MED — `active_column(...) or 1` fallback in colresize/fit/maximize/move/center:
   while a floating window is focused, commands target column 1, not the last
   tiled column. Track `st.last_ci` (set in active_column on positive hits) as fallback.
5. LOW — expel/promote of a sole-member column shifts it right one position
   (insert at aci+1 after removal). Treat sole-member expel/promote as no-op.
6. LOW — `target_id` fallback `"tmp:"..index` unstable for nil-window targets
   (group targets expose main window but `.window` may be nil per wiki). Skip
   nil-window targets instead.

**Workflow risks (behavioral, no code bug):**
- Mouse-drag window swap = C++ insertion-order swap; bypasses Lua column state →
  visibly reverts (known custom-layout limitation, same in hy3-lua community layout).
- `hyprctl reload` tears down Lua state → columns rebuild from C++ insertion order
  (stack memberships lost, tape order = spawn order). By-design caveat.
- Tab-group targets expose only the main window; stacking a tab group into a
  column members list works but group window semantics are untested on tape.

**Community practices verified against (SearchResearcher digest):**
- C++ auto-calls recalculate after every layout_msg (mutate state only) ✓ conforms
- layout_msg: return string = visible dispatch error, true = OK ✓ conforms
- per-workspace state + reconcile-from-targets = canonical pattern (hyprwm
  example/layouts/manual.lua, hy3-lua) ✓ conforms
- recalculate runs under LUA_TIMEOUT_LAYOUT_CALLBACK_MS — current O(cols*members*targets)
  nested loop is fine at realistic sizes; a Lua error in recalculate silently
  snaps windows to a default GRID (didError flag) — avoid nil derefs
- Debugging tip: `hyprctl repl` prints layout_msg return values (`eval` only prints "ok")

### Fix-pass 2026-09-20 (all confirmed bugs closed)

1–4, 6 FIXED in tape-layout.lua (reload-verified, zero Lua errors, stylua clean):
- Index-shift: dest indices now computed against post-removal state
  (`removed` flag; right neighbor at `aci` not `aci+1`; left neighbor
  unaffected). Invalid `move` args validated BEFORE detach. 12-scenario
  logic sim in node: all correct (move-r joins the adjacent column per
  built-in scrolling semantics; edge cases are structural no-ops).
- `fit_active_view` no-ops while a floater holds focus.
- `current_ci()` helper tracks `st.last_ci`; colresize/fit/maximize/move/
  center/view-col use it instead of hard `or 1`.
- expel/promote of a sole-member column re-inserts at `aci` (no right-creep).
- sync skips nil-window targets (tmp index ids no longer churn columns).

Not committed yet (awaiting user). Remaining acceptances: mouse-drag moves
visibly revert (custom-layout limitation), reload wipes Lua state (by design),
tab-group stacking untested.

### Next actions
- Live-test on the ultrawide: edge moves, sole-member move r, floater focus
  while scrolled (viewport must stay), then commit.
- Optionally: `move +col/-col`/`±px` aliases for scrolling vocabulary parity.
- Consider `follow_min_visible`-style partial-visibility mode later.


### Resume point
Nothing pending — task complete, committed as `lua:tape` feature commit.
Re-read this file + `tape-layout.lua` header before further layout work.
