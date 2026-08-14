# Herdr — agent multiplexer that lives in your terminal.
# Bindings mirror the tmux config (lib/tmux-config.nix) so that pane
# navigation, splits, and tab switching use the same prefix key and
# the same hjkl-based motion, giving a consistent UX across both tools.
{
  config,
  lib,
  ...
}: {
  options.myconf.herdr.enable = lib.mkEnableOption "herdr configuration with tmux-like bindings";

  config = lib.mkIf config.myconf.herdr.enable {
    programs.herdr = {
      enable = true;

      settings = {
        # Skip first-run onboarding — we know what we're doing.
        onboarding = false;

        # Follow the focused pane's working directory for new panes/tabs,
        # matching tmux's `-c "#{pane_current_path}"` behaviour.
        terminal.new_cwd = "follow";

        # Use the Catppuccin theme that matches the host's flavor.
        # When the flavor is "latte" (light), use the latte variant;
        # otherwise use the default dark Catppuccin.
        theme = {
          name =
            if config.catppuccin.flavor == "latte"
            then "catppuccin-latte"
            else "catppuccin";
          auto_switch = true;
          light_name = "catppuccin-latte";
          dark_name = "catppuccin";
        };

        # ── Keybindings ─────────────────────────────────────────────────
        # Mirror the tmux config so muscle memory transfers between the
        # two multiplexers.  Prefix = C-Space (same as tmux).
        keys = {
          prefix = "ctrl+e";

          # Pane navigation — prefix+h/j/k/l (matches tmux prefix).
          # Direct chords use Alt+Shift+h/j/k/l (tmux uses Alt+hjkl without prefix).  The Shift modifier helps avoid interfering
          # with normal typing in editors/shells.
          focus_pane_left = ["prefix+h" "alt+shift+h"];
          focus_pane_down = ["prefix+j" "alt+shift+j"];
          focus_pane_up = ["prefix+k" "alt+shift+k"];
          focus_pane_right = ["prefix+l" "alt+shift+l"];

          # Pane swapping — prefix+Shift+h/j/k/l (tmux: Alt+Shift+hjkl)
          swap_pane_left = ["prefix+shift+h"];
          swap_pane_down = ["prefix+shift+j"];
          swap_pane_up = ["prefix+shift+k"];
          swap_pane_right = ["prefix+shift+l"];

          # Pane splitting — match tmux: prefix+- (horizontal/stacked),
          # prefix+v (vertical/side-by-side).  tmux also uses prefix+|
          # and prefix+" — herdr doesn't support those literal keys, so
          # we rely on the minus/v bindings.
          split_horizontal = "prefix+minus";
          split_vertical = "prefix+v";

          # Close pane — prefix+x (matches tmux)
          close_pane = "prefix+x";

          # Zoom — prefix+z (matches tmux)
          zoom = "prefix+z";

          # Resize mode — prefix+r (matches tmux's prefix+M-C-hjkl resize;
          # herdr uses a resize *mode* instead, entered with prefix+r)
          resize_mode = "prefix+r";

          # ── Tabs (windows in tmux) ───────────────────────────────────
          # New tab — prefix+c (matches tmux)
          new_tab = "prefix+c";

          # Tab switching — prefix+n/p (matches tmux), plus Alt+Shift+i/u
          # direct chords (tmux uses Alt+Shift+U/I without prefix)
          next_tab = ["prefix+n" "alt+shift+i"];
          previous_tab = ["prefix+p" "alt+shift+u"];

          # Jump to tab 1-9 — prefix+1..9 (matches tmux)
          switch_tab = "prefix+1..9";

          # Rename tab — prefix+Shift+t (tmux uses prefix+,)
          rename_tab = "prefix+shift+t";

          # Close tab — prefix+Shift+x
          close_tab = "prefix+shift+x";

          # ── Workspaces (sessions in tmux) ────────────────────────────
          # Workspace picker — prefix+w (matches tmux's window picker)
          workspace_picker = "prefix+w";

          # Workspace navigation in the picker — vim-style j/k (defaults
          # are arrow keys; keep them as aliases).  Matches the hjkl
          # pane-navigation motion used elsewhere.
          navigate_workspace_down = ["j" "down"];
          navigate_workspace_up = ["k" "up"];

          # Goto navigator — prefix+g
          goto = "prefix+g";

          # New workspace — prefix+Shift+n
          new_workspace = "prefix+shift+n";

          # Rename workspace — prefix+Shift+w
          rename_workspace = "prefix+shift+w";

          # Close workspace — prefix+Shift+d
          close_workspace = "prefix+shift+d";

          # ── Session ──────────────────────────────────────────────────
          # Detach — prefix+q (matches herdr default; tmux uses prefix+d)
          detach = "prefix+q";

          # Copy mode — prefix+[ (matches tmux)
          copy_mode = "prefix+[";

          # Toggle sidebar — prefix+b
          toggle_sidebar = "prefix+b";

          # Help — prefix+? (matches tmux's list-keys)
          help = "prefix+?";

          # Settings — prefix+s
          settings = "prefix+s";

          # Reload config — prefix+Shift+r
          reload_config = "prefix+shift+r";

          # Cycle panes — prefix+Tab / prefix+Shift+Tab
          cycle_pane_next = "prefix+tab";
          cycle_pane_previous = "prefix+shift+tab";

          # Edit scrollback in $EDITOR — prefix+e
          edit_scrollback = "prefix+e";
        };

        # ── UI ─────────────────────────────────────────────────────────
        ui = {
          # Copy selected text with the mouse (matches tmux's set-clipboard)
          copy_on_select = true;
          # Draw borders around split panes
          pane_borders = true;
          pane_gaps = true;
          # Confirm before closing a workspace
          confirm_close = true;
          # Hide tab bar when only one tab exists
          hide_tab_bar_when_single_tab = true;
        };

        # ── Session restore ────────────────────────────────────────────
        # Resume agent conversations after a server restart (like tmux
        # resurrect/continuum, but for AI agent sessions).
        session.resume_agents_on_restore = true;
      };
    };
  };
}
