---
category: herdr
slug: nixconf-herdr
created: 2026-10-01
updated: 2026-10-01
status: active
owner: OpenAgent
---

# Herdr — Task Backlog

Domain memory for herdr (agent multiplexer) work in this repo.

## Domain Context

- herdr 0.9.1 (upstream docs at 0.9.3; `herdr.dev/docs/configuration/`). HM module
  `programs.herdr` (home-manager, rev 0aefa652): options are only `enable`,
  `package`, `settings`. `settings` → `tomlFormat.generate` →
  `~/.config/herdr/config.toml` (store symlink) + `onChange` → `herdr server reload-config`.
- Enabled only on `home-manager/users/mykolas/home-geks-nixos.nix`
  (`myconf.herdr.enable = true`); module: `home-manager/modules/herdr.nix`.
- Native hot-reload exists: `herdr server reload-config` CLI + bound
  `reload_config = "prefix+shift+r"`. Reload applies most UI settings without
  restarting panes; startup-only settings need a server restart.
- herdr reads exactly ONE config file (`~/.config/herdr/config.toml`, env override
  `HERDR_CONFIG_PATH`). No include/fragment support → no "Nix base + live overlay"
  merge inside one file.
- Theme is runtime-dynamic via `theme.auto_switch` (light/dark follow the terminal;
  manual Settings selection disables auto_switch).
- Plugins are imperative/runtime-managed (`herdr plugin install` → `plugins.json`,
  `.plugins.lock`) — no declarative HM support. `[[keys.command]]` plugin_action
  bindings live in config.toml.
- Runtime files in `~/.config/herdr/`: herdr-server.log, herdr-client.log,
  herdr.sock, herdr-client.sock, plugins.json, session.json, release-notes.json —
  a live-link activation must touch ONLY config.toml.
- Evidence of friction: `config.toml.hm-back` (2026-07-13) — a hand-edited config
  was clobbered/backed up by HM.
- ⚠️ A PARALLEL SESSION works on herdr plugins. Agreed coordination (2026-10-01):
  this session converts the config mechanism NOW; the plugin session adapts —
  future plugin-action bindings go into the live config file, NOT
  `programs.herdr.settings`. plugins.json work is unaffected.

### Research findings (2026-10-01, 3 SearchResearcher digests)

**herdr-specific (decisive):**
- NO include/merge mechanism — herdr reads exactly one `config.toml`; upstream
  has no include feature and no open request (confirmed by cideM/dotfiles doing
  Nix-side `recursiveUpdate` merging instead). → the "Nix entry file + live
  overlay" hybrid (best pattern elsewhere) is IMPOSSIBLE for herdr.
- `HERDR_CONFIG_PATH` is brittle: the config DIR supplies the socket location;
  every client/process must share the env or they can't find the server. Not
  worth it.
- herdr itself WRITES to config.toml (onboarding flow, `herdr config
  reset-keys`) — fails against read-only store symlinks. We already set
  `onboarding = false`; with a live symlink the write would hit the repo file
  (do NOT run reset-keys; keep onboarding=false).
- Reload is solid: issue #2960's "reload_config never activates keys.command"
  was corrected — reload works; the real bug was `type = "shell"` commands
  getting the SERVER's environment (use absolute paths). Client-side settings
  (themes/sidebar/copy) vs server-side (panes/worktrees/commands) split applies.
- NEVER manage: session.json, session-backups/, session-snapshots/,
  session-history.json, logs, plugin state/checkouts. A live-link must touch
  ONLY config.toml.
- Plugins (for the parallel session): community-declarative options exist —
  `herdr plugin link <store-path>` in home.activation (calops/cideM; idempotent,
  self-heals store-path changes; one `herdr server stop` after upgrades) or
  Nix-generated plugins.json (Mic92/otavio; upstream registry preserves
  symlinks). Plugin user-config belongs in `HERDR_PLUGIN_CONFIG_DIR`
  (`config.env` for simple-switcher PROJECTS_ROOT).
- Version note: we run 0.9.1 — 0.9.2 added multi-prefix arrays,
  keys.clear_pane, session.startup_per_agent_delay_ms (dead/warned on 0.9.1);
  #4555 0.9.1 CPU bug is tmux-under-WSL2 nested only (irrelevant here).

**Nix/HM pattern landscape (community):**
- Community standard for no-rebuild editing = out-of-store symlinks:
  HM-native `config.lib.file.mkOutOfStoreSymlink` or the repo's equivalent
  `lib/live-links.nix` home.activation approach — validated as the right tool,
  2022→2026 consensus (HM #3514, Discourse 77643). Keep Nix options for
  dynamic/host-conditional values.
- "Entry-point hybrid" (Nix-generated immutable entry file that
  `source=`/`include`s a live file) is the best-practice pattern where the app
  supports includes (hyprland, git, kitty, tmux) — not applicable to herdr.
- Known gotchas to accept/document: content drift invisible to Nix, symlink
  recreation each generation, checkout must exist before activation,
  `nixos-rebuild` rollback restores the base but not live-file content (git is
  the rollback).
- Template generators (confgen, nixago) and full-stow approaches: niche /
  rejected for this use case.

**Runtime theming (for backlog item 2, hyprland):**
- matugen = de-facto standard (wallpaper-driven, templates any format incl.
  Lua, can import catppuccin's palette.json to stay on-palette); canonical
  pipeline: picker → `matugen image` → render colors.lua → `hyprctl reload`.
- Zero-tool alternative for catppuccin: pre-generate all 4 flavor palettes as
  Lua tables (whiskers/palette.json) and select flavor at runtime in
  hyprland-dynamic.lua.
- herdr `auto_switch` note: multiplexers must re-query OSC 11 after terminal
  theme switches (tmux stale-cache lesson) — verify herdr behavior when doing
  runtime theme work.

## Current Item

**Item 1 implemented + validated + plugin changes reviewed → ready to rebuild**

- Implementation complete (2026-10-01): new live config
  `home-manager/users/mykolas/config/herdr/config.toml` (ported verbatim from
  old settings, comments preserved, plugin-binding ownership note added),
  `home-manager/modules/herdr.nix` rewritten (settings dropped,
  `linkHerdrConfig` mkLiveLinks activation, filter = config.toml only),
  AGENTS.md Herdr bullet updated. TOML parse check: PASS.
- Dry-run build geks-nixos: PASS after `git add -N` (untracked-dir flake
  visibility, user ran it). No commit made (repo rule: only when asked).
- Plugin session changes reviewed (2026-10-02): all RUNTIME-side — new local
  plugin `preview-grid` (linked from ~/workspaces/src/herdr-preview-grid,
  actions preview-grid.spaces/.agents), plugin configs seeded under
  plugins/config/ (simple-switcher config.env PROJECTS_ROOT=$HOME/workspaces,
  picker + preview-grid configs). plugins.json survives rebuild untouched.
- Takeover decision (user, 2026-10-02): preview-grid.spaces → prefix+w,
  preview-grid.agents → prefix+a (replacing simple-switcher fzf switchers;
  fzf keeps prefix+t switch-tab + prefix+shift+o open-project). Bindings were
  already applied in the repo TOML (by plugin session/user); this session
  updated the stale plugin-actions comment block to document all 3 plugins +
  the takeover + how to revert to fzf. TOML re-validated: PASS (5 bindings).
  Dry-run re-validated: PASS.
- Remaining (user machine actions): run the switch, verify
  `readlink ~/.config/herdr/config.toml` points into the checkout, reload
  (prefix+shift+r) to activate the new bindings, test preview-grid, then
  commit code + backlog together.

## Backlog

- [ ] **1. Convert herdr installation to be dynamically switchable (like hyprland)**
  - Why: every config tweak (keys/theme/UI) currently needs a full nix rebuild;
    `config.toml` is an immutable store symlink.
  - Claim: hyprland achieves edit → reload with zero rebuilds via live-links into
    `$NIXOS_CONF_DIR`; herdr has native `reload-config` but the file is
    rebuild-gated, so the same workflow is impossible today.
  - Verification: DONE 2026-10-01 — `readlink ~/.config/herdr/config.toml` →
    `/nix/store/...-home-manager-files/...`; contrast hyprland lua live-links;
    `herdr server reload-config` + `prefix+shift+r` exist but can't help while the
    file is store-owned.
  - Approach: A — live-linked config.toml (user decision 2026-10-01);
    implemented 2026-10-01/02
  - Verdict: verified
  - Status: in-progress (awaiting user switch + commit)
- [ ] **2. Apply research findings to improve hyprland config (e.g. runtime theming)**
  - Why: hyprland is already live-linked Lua, but `catppuccin-palette.lua` is
    Nix-generated (rebuild needed on flavor/accent change).
  - Claim: runtime color generation (e.g. matugen/pywal-style) could decouple the
    last rebuild-coupled piece.
  - Verification: pending research.
  - Approach: (empty)
  - Verdict: pending
  - Status: pending

## Done

- (none yet)

## Decisions

- 2026-10-01: User chose RESEARCH-FIRST before picking an approach for item 1
  (approaches pre-identified: A live-linked config.toml / B profile-switcher CLI /
  C HERDR_CONFIG_PATH multi-config). Also: findings may improve hyprland config.
- 2026-10-01: Coordination with parallel plugin session: proceed now; plugin
  session adapts (plugin bindings go to the live config file, not
  `programs.herdr.settings`).
- 2026-10-01: Backlog file created per protocol (user confirmed).
- 2026-10-01: Research complete (3 digests: Nix/HM patterns, herdr specifics,
  runtime theming). Key verdicts: entry-point hybrid impossible (no herdr
  include support); HERDR_CONFIG_PATH brittle (socket dir coupling); approach A
  (live-linked config.toml) aligns with the community-standard
  mkOutOfStoreSymlink pattern AND this repo's existing live-links usage.
  hyprland item 2 has two candidate designs (matugen pipeline vs zero-tool
  4-flavor runtime palette). Awaiting user decisions.

- 2026-10-01: USER DECIDED — item 1 approach = A (live-linked config.toml,
  "dynamically linked config"). Implementation started. The terminal-theme
  idea (theme.name="terminal") and item-2 runtime-overlay design remain
  open follow-ups, NOT part of this implementation (theme stays
  catppuccin-latte + auto_switch verbatim).

## Blockers

- (none)

## Notes

- Current generated config snapshot (2026-10-01): prefix ctrl+e, theme
  catppuccin-latte + auto_switch, new_cwd=follow, ui booleans, 5 plugin_action
  bindings, session.resume_agents_on_restore=true. Repo file conversion must
  preserve comments/intent from `herdr.nix`.
- `herdr --default-config` prints the full default config (good starting reference).
- Reload split (docs): client-local settings (themes, sidebar, copy) vs server
  settings (pane defaults, worktrees, integrations, custom commands).

---

## Appendix — Plugin session (ses_f08e9855bffe…, 2026-10-01)

The "plugin session" from the coordination note (line 38). Domain: plugin
failures + the herdr preview-grid plugin. Additive per read-before-write;
the config-session sections above are theirs.

### Fixed: the "plugins failed" popup is opencode 2, not herdr plugins

- Root cause: OpenCode **2.0.12** rejects two V1-shaped plugins at load
  (`Plugin must export a default definition with an id and an effect or setup
  function`), 56× in today's log alone:
  1. `~/.config/opencode/plugins/herdr-agent-state.js` — herdr's **opencode
     integration v9** (V1-only `export default async fn`); herdr 0.9.1 bundles
     **v12** (dual shape `{ id, server, setup() {} }` + V2 TUI entrypoint).
  2. `@open-pets/opencode@4.0.0` — upstream still ships V1 `{id, server}`
     only (verified in npm tarball + local openpets checkout).
- Fixes: `herdr integration install opencode` → v12 (`herdr integration
  status` = current); writes `plugins/herdr-agent-state.js`,
  `herdr-tui-session.js` (v12), `herdr-opencode/tui.js`, registers
  `./herdr-opencode` in `cli.json`, keeps `tui.jsonc` registration. OpenPets
  plugin commented out in nixconf-private `opencode/opencode.jsonc` (re-enable
  when upstream ships V2 — full note in `nixconf_openpets_backlog.md`).
  opencode-workflow repo snapshot updated to v12 + docs corrected (so
  `install.sh` can't regress it).
- Evidence: fresh plugin reconciliation 15:54:32Z loads herdr-agent-state.js
  with **0 failures**; last v9 failure 15:49:57Z. Popup clears on the next
  opencode TUI/service restart (user action; restart would kill this session).
- herdr-plugin marketplace plugins themselves were verified healthy
  (simple-switcher + yoshiori picker rendered/selected fine in isolated PTY
  tests; `herdr config check` = ok) — no action needed there.

### In progress: `herdr-preview-grid` (user item 2) — Go + Bubble Tea v2

- User decisions so far: framework = **Go + Bubble Tea v2** (chosen over
  Rust/ratatui + Python; python3 is MISSING on the herdr server PATH).
  Research digest (SearchResearcher): ratatui strongest precedent, Bubble Tea
  safest distribution; charm.land vanity import path for v2 modules.
- Plan: installable herdr plugin, separate project (scaffolding now at
  `~/workspaces/src/herdr-preview-grid`); preview wall of spaces/agents; move
  ctrl+h/j/k/l; `/` fuzzy; 1–2 letter codes from `jklfds`; active highlight;
  MRU usage order; scrollable wall; live ANSI pane previews via
  `herdr pane read --format ansi`; state under `HERDR_PLUGIN_STATE_DIR`.
- Working defaults (user may adjust): two grids replacing simple-switcher's
  `switch-workspace`/`switch-agent` (prefix+w / prefix+a); code typing
  disambiguated by timeout (~400ms, easymotion-style); tile = name + status +
  live pane preview.
- Integration notes: new bindings go into the LIVE
  `home-manager/users/mykolas/config/herdr/config.toml` (config session's
  conversion), NOT Nix. Dev loop: `herdr plugin link <dir>` → test → publish
  to GitHub for `herdr plugin install`. Go 1.26.7 + cargo build toolchain
  verified present on the server PATH.

### DONE 2026-10-02: `herdr-preview-grid` v0.1.0 — built, linked, bound, E2E-verified

- Project: `~/workspaces/src/herdr-preview-grid` (git, 2 commits; MIT). Go +
  Bubble Tea v2 (`charm.land/bubbletea/v2` v2.0.10, lipgloss v2.0.6) + sahilm/fuzzy;
  static CGO_ENABLED=0 binary. Packages: `internal/{herdr,app,codes,mru,config}`,
  `cmd/herdr-preview-grid`; unit tests for codes/mru/config/view helpers (all pass,
  gofmt+vet clean).
- Manifest: actions `spaces`/`agents` delegate to overlay panes via
  `herdr plugin pane open` (actions have NO TTY — direct TUI in an action fails
  `open /dev/tty`); panes fall back `bin/` binary → `go run`. Build cmd:
  `CGO_ENABLED=0 go build -o bin/herdr-preview-grid ./cmd/herdr-preview-grid`
  (manifest `[[build]]` runs on GitHub install; link mode uses the local binary).
- Linked: `herdr plugin link ~/workspaces/src/herdr-preview-grid` (plugin id
  `preview-grid`, enabled, source local). Config seeded:
  `~/.config/herdr/plugins/config/preview-grid/config.toml` (from
  `config.example.toml`).
- Bindings LIVE in `home-manager/users/mykolas/config/herdr/config.toml`:
  `prefix+w` → `preview-grid.spaces`, `prefix+a` → `preview-grid.agents`
  (replacing simple-switcher's switch-workspace/switch-agent; switch-tab and
  open-project stay on simple-switcher). `herdr config check` = ok,
  `herdr server reload-config` = applied (0 diagnostics). simple-switcher
  remains installed for tab/project actions.
- E2E evidence: spaces + agents grids rendered inside live herdr overlay panes
  (read via `pane read`, equal tiles, codes j/k/l/f/d/s + pairs, statuses, live
  ANSI previews); fuzzy `/n1` filtered correctly; code `jj` jumped to
  workspace w15 (`workspace.focus` in server log, request_id=preview-grid) and
  wrote `mru.json`; panel-ESC closed the overlay cleanly (exit 0).
- Gotchas recorded for the project: lipgloss Width/Height are minimum outer
  sizes and never trim (pad lines to exact count; `truncateDisplay` is
  display-width aware); `[section]` headers end config parsing (keys top-level
  only); pane `display_agent` is the rename-aware name field (not `name`).
- Open follow-ups (user): decide whether to publish to GitHub
  (`herdr plugin install <owner>/herdr-preview-grid`) or keep local-linked;
  optional `popup` placement experiment; config tuning (preview_lines,
  tile_min_width).
