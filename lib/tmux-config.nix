{
  mkTmuxConf = {
    pkgs,
    catppuccinFlavor ? "latte",
    tmuxpPresetsDir ? null,
    seshConfigFile ? null,
  }: let
    # Bundled paths (nix store copies) used when no live config is present.
    # On NixOS managed by home-manager, live symlinks in ~/.config take precedence.
    bundledTmuxpDir =
      if tmuxpPresetsDir != null
      then "${tmuxpPresetsDir}"
      else "";
    bundledSeshConf =
      if seshConfigFile != null
      then "${seshConfigFile}"
      else "";

    seshPicker = pkgs.writeShellScript "sesh-picker" ''
      LIVE="''${XDG_CONFIG_HOME:-$HOME/.config}/sesh/sesh.toml"
      if [ -f "$LIVE" ]; then
        SESH_CFG="$LIVE"
      elif [ -n "${bundledSeshConf}" ]; then
        SESH_CFG="${bundledSeshConf}"
      else
        SESH_CFG=""
      fi
      export SESH_CFG

      # Wrapper so --config is always quoted; fzf reload subprocesses use $SESH_CFG directly
      sesh_run() { ${pkgs.sesh}/bin/sesh ''${SESH_CFG:+--config "$SESH_CFG"} "$@"; }

      selected=$(
        sesh_run list --icons \
        | ${pkgs.fzf}/bin/fzf \
            --no-sort --ansi \
            --border-label ' sesh ' \
            --prompt '⚡  ' \
            --header '  ^a all  ^t tmux  ^g configs  ^x zoxide  ^f find  ^q kill  ^j/^k nav' \
            --bind 'ctrl-j:down,ctrl-k:up,ctrl-d:half-page-down,ctrl-u:half-page-up' \
            --bind "ctrl-a:change-prompt(⚡  )+reload(${pkgs.sesh}/bin/sesh list --icons ''${SESH_CFG:+--config }$SESH_CFG)" \
            --bind "ctrl-t:change-prompt(🪟  )+reload(${pkgs.sesh}/bin/sesh list -t --icons ''${SESH_CFG:+--config }$SESH_CFG)" \
            --bind "ctrl-g:change-prompt(⚙️  )+reload(${pkgs.sesh}/bin/sesh list -c --icons ''${SESH_CFG:+--config }$SESH_CFG)" \
            --bind "ctrl-x:change-prompt(📁  )+reload(${pkgs.sesh}/bin/sesh list -z --icons ''${SESH_CFG:+--config }$SESH_CFG)" \
            --bind 'ctrl-f:change-prompt(🔎  )+reload(${pkgs.fd}/bin/fd -H -d 2 -t d -E .Trash . ~)' \
            --bind "ctrl-q:execute(tmux kill-session -t {2..} 2>/dev/null)+change-prompt(⚡  )+reload(${pkgs.sesh}/bin/sesh list --icons ''${SESH_CFG:+--config }$SESH_CFG)" \
            --preview-window 'right:55%' \
            --preview '${pkgs.sesh}/bin/sesh preview {}'
      )
      [ -n "$selected" ] && sesh_run connect "$selected"
    '';

    tmuxpPicker = pkgs.writeShellScript "tmuxp-picker" ''
      LIVE="''${XDG_CONFIG_HOME:-$HOME/.config}/tmuxp"
      if ls "$LIVE"/*.yaml 2>/dev/null | grep -q .; then
        PRESETS_DIR="$LIVE"
      elif [ -n "${bundledTmuxpDir}" ] && ls "${bundledTmuxpDir}"/*.yaml 2>/dev/null | grep -q .; then
        PRESETS_DIR="${bundledTmuxpDir}"
      else
        echo 'No tmuxp presets found.' >&2
        exit 0
      fi
      preset=$(
        ls "$PRESETS_DIR"/*.yaml \
        | xargs -I{} basename {} .yaml \
        | ${pkgs.fzf}/bin/fzf --prompt='layout: ' --border-label ' tmuxp presets '
      )
      [ -z "$preset" ] && exit 0
      dir=$(
        { echo "$HOME"; ${pkgs.fd}/bin/fd -H -d 3 -t d . "$HOME/workspaces" 2>/dev/null; } \
        | ${pkgs.fzf}/bin/fzf \
            --prompt='directory: ' \
            --border-label ' select directory ' \
            --preview '${pkgs.eza}/bin/eza --all --git --icons --color=always {}' \
            --preview-window 'right:50%'
      )
      [ -z "$dir" ] && exit 0
      name=$(basename "$dir")
      if tmux has-session -t "$name" 2>/dev/null; then
        tmux switch-client -t "$name"
      else
        TMUXP_SESSION_NAME="$name" TMUXP_DIR="$dir" ${pkgs.tmuxp}/bin/tmuxp load "$PRESETS_DIR/$preset.yaml"
      fi
    '';

    windowPicker = pkgs.writeShellScript "window-picker" ''
      selected=$(
        tmux list-windows -F '#{window_index}: #{window_name}  #{pane_current_path}' \
        | ${pkgs.fzf}/bin/fzf \
            --no-sort --ansi \
            --border-label ' windows ' \
            --prompt '🪟  ' \
            --bind 'ctrl-j:down,ctrl-k:up,ctrl-d:half-page-down,ctrl-u:half-page-up' \
            --header 'Enter: switch  ctrl-j/k: nav  type: filter' \
            --preview 'tmux capture-pane -p -e -t ":$(echo {} | cut -d: -f1)"' \
            --preview-window 'right:60%'
      )
      [ -n "$selected" ] && tmux select-window -t ":$(echo "$selected" | cut -d: -f1)"
    '';

    whichKeyRebuild = pkgs.writeShellScript "which-key-rebuild" ''
      xdg_data="${"\${XDG_DATA_HOME:-$HOME/.local/share}"}/tmux/plugins/tmux-which-key"
      xdg_config="${"\${XDG_CONFIG_HOME:-$HOME/.config}"}/tmux/plugins/tmux-which-key"
      build_py="$xdg_data/build.py"
      config_yaml="$xdg_config/config.yaml"
      init_tmux="$xdg_data/init.tmux"
      if [ ! -f "$build_py" ]; then
        tmux display-message "  which-key rebuild failed: $build_py not found (run tmux once first)"
        exit 0
      fi
      if "$build_py" "$config_yaml" "$init_tmux"; then
        tmux source-file "$init_tmux"
        tmux display-message "  which-key menu rebuilt and reloaded"
      else
        tmux display-message "  which-key rebuild failed — check $config_yaml"
      fi
    '';

    reloadScript = pkgs.writeShellScript "tmux-reload" ''
      new_conf=$(${pkgs.gnugrep}/bin/grep -o '/nix/store/[^[:space:]]*\.conf' "$(command -v tmux)" 2>/dev/null | head -1)
      if [ -n "$new_conf" ]; then
        tmux source-file "$new_conf"
        tmux display-message "  config reloaded from $new_conf"
      else
        tmux display-message "  reload failed: no .conf path found in $(command -v tmux)"
      fi
    '';

    cheatsheet = pkgs.writeText "tmux-cheatsheet" ''
      ╔══════════════════════════════════════════════════════════════════╗
      ║                     TMUX CHEATSHEET                            ║
      ║  prefix = C-Space                 q / Esc = close popup        ║
      ╚══════════════════════════════════════════════════════════════════╝

      ── PANES ──────────────────────────────────────────────────────────
        prefix -            new pane below
        prefix |            new pane to the right
        M-h/j/k/l           navigate panes  (vim & fzf aware)
        M-H/J/K/L           swap pane with neighbour  (Alt+Shift+h/j/k/l)
        M-C-h/j/k/l         resize pane  (hold to continuously resize)
        prefix z            zoom / unzoom active pane

      ── WINDOWS ────────────────────────────────────────────────────────
        prefix c            new window
        M-U / M-I           previous / next window  (Alt+Shift+U/I)
        prefix w            window picker  (fzf, current session windows)
        prefix ,            rename window
        prefix 1-9          jump to window N
        prefix &            kill window

      ── SESSIONS ───────────────────────────────────────────────────────
        prefix o            sesh picker  (smart session switcher)
          ctrl-j / ctrl-k     scroll down / up
          ctrl-d / ctrl-u     half-page down / up
          ctrl-a              all sources (tmux + configs + zoxide)
          ctrl-t              tmux sessions only
          ctrl-g              sesh.toml configured sessions
          ctrl-x              zoxide recently-used directories
          ctrl-f              filesystem find (fd, 2 levels from ~)
          ctrl-q              kill selected session + reload list
          Enter               connect or create session

        prefix S            tmuxp layout picker  (multi-pane presets)
          presets:  ~/.config/tmuxp/*.yaml  (live-linked from nixconf on NixOS)
          bundled:  nixconf repo presets used on unmanaged systems
          CLI:      TMUXP_DIR=<path> tmuxp load -s <name> <preset.yaml>

        prefix s            built-in session tree (choose-tree)
        prefix $            rename session

      ── SESSION PERSISTENCE ────────────────────────────────────────────
        prefix C-s          resurrect: SAVE  current layout
        prefix C-r          resurrect: RESTORE  last save
        auto-save           continuum saves every 10 min
        auto-restore        continuum restores on tmux server start

      ── COPY MODE ──────────────────────────────────────────────────────
        prefix [            enter copy mode
        v                   begin selection
        Enter / y           copy selection → clipboard (wl-copy)
        q                   exit copy mode
        / ?                 search forward / backward

      ── HARPOON  (window bookmarks) ────────────────────────────────────
        C-S-h               add current window as bookmark
        C-h                 open harpoon list / fuzzy-jump to bookmark

      ── MENUS ──────────────────────────────────────────────────────────
        prefix Space        which-key command palette
        prefix R            rebuild which-key menu  (edits: ~/.config/tmux/plugins/tmux-which-key/config.yaml)
        prefix r            reload config  (greps new conf path from updated tmux wrapper)
        prefix /            this cheatsheet

      ── HOLISTIC WORKFLOW ──────────────────────────────────────────────

        Starting a new project:
          1. prefix o → type dir/project name → Enter
             sesh creates a session and runs nvim (from sesh.toml wildcard)
          2. prefix S → pick a layout preset + directory
             tmuxp builds the full pane layout (editor / lazygit / shell)
          3. C-S-h → bookmark the main window for instant return

        Daily driver:
          • tmux auto-restores all sessions on login  (continuum)
          • prefix o → jump between projects instantly
          • M-h/j/k/l → navigate panes without lifting hands
          • M-H/J/K/L → reorder panes within the layout
          • M-U/M-I → cycle windows  (Alt+Shift+U/I)
          • prefix C-s before shutdown to snapshot layout

        On any machine without config files (nix run):
          nix run github:<user>/nixconf#tmux
          All plugins and keybindings work; bundled sesh.toml and tmuxp
          presets are included. Clone nixconf and run home-manager switch
          to enable live editing of configs.

        Live-editing configs (NixOS, no rebuild needed):
          sesh rules:      ~/workspaces/src/nixconf/.../config/sesh/sesh.toml
          tmuxp presets:   ~/workspaces/src/nixconf/.../config/tmuxp/*.yaml
    '';
  in ''
    # GENERAL SETTINGS
    set -g status-left '#S '
    set -g status-left-length 30
    setw -g aggressive-resize on

    # allow passthrough
    set -gq allow-passthrough on
    set -g visual-activity off
    set -ga update-environment TERM
    set -ga update-environment TERM_PROGRAM

    # fix terminal colors
    set -g default-terminal "tmux-256color"
    set -ag terminal-overrides ",xterm-256color:RGB"
    set-option -a terminal-overrides ",alacritty:RGB"
    set -ag terminal-overrides ",xterm-ghostty:RGB"

    # propagate kitty identity so graphics protocol detection works inside tmux
    set -ga update-environment KITTY_WINDOW_ID

    # set escape key delay to 0
    set -s escape-time 0

    # set mouse mode
    set -g mouse on

    # window numbering
    set -g base-index 1
    set -g pane-base-index 1
    set-window-option -g pane-base-index 1
    set-option -g renumber-windows on

    # KEYBINDINGS

    # set prefix
    unbind C-b
    set -g prefix C-Space
    bind C-Space send-prefix

    # Use vi keybindings in copy mode
    setw -g mode-keys vi
    set -g focus-events on
    set -g clock-mode-style 24

    # copy mode
    bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "${pkgs.wl-clipboard}/bin/wl-copy"
    bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "${pkgs.wl-clipboard}/bin/wl-copy"

    # splitting panes
    bind '-' split-window -v -c "#{pane_current_path}"
    bind '"' split-window -v -c "#{pane_current_path}"
    bind | split-window -h -c "#{pane_current_path}"
    bind % split-window -h -c "#{pane_current_path}"

    # open panes in the current directory
    bind c new-window -c "#{pane_current_path}"

    # window switching (Alt+Shift+U/I)
    bind -n M-U previous-window
    bind -n M-I next-window

    # pane resizing — hold M-C-h/j/k/l (Alt+Ctrl+hjkl), no prefix needed
    bind -n M-C-k resize-pane -U 5
    bind -n M-C-j resize-pane -D 5
    bind -n M-C-h resize-pane -L 5
    bind -n M-C-l resize-pane -R 5

    # smart pane switching with vim awareness
    is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
    is_fzf="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?fzf$'"

    bind -n M-h run "($is_vim && tmux send-keys M-h) || tmux select-pane -L"
    bind -n M-j run "($is_vim && tmux send-keys M-j) || ($is_fzf && tmux send-keys C-j) || tmux select-pane -D"
    bind -n M-k run "($is_vim && tmux send-keys M-k) || ($is_fzf && tmux send-keys C-k) || tmux select-pane -U"
    bind -n M-l run "($is_vim && tmux send-keys M-l) || tmux select-pane -R"

    # pane swapping — physically move pane within layout (Alt+Shift+h/j/k/l)
    bind -n M-H swap-pane -t '{left-of}'
    bind -n M-J swap-pane -t '{below}'
    bind -n M-K swap-pane -t '{above}'
    bind -n M-L swap-pane -t '{right-of}'

    # Catppuccin
    set -g @catppuccin_flavor "${catppuccinFlavor}"
    run-shell ${pkgs.tmuxPlugins.catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux

    # Pane borders — fully frame and highlight active pane
    set -g pane-border-lines heavy
    set -g pane-active-border-style "fg=#{@thm_blue},bold"
    set -g pane-border-style "fg=#{@thm_overlay_0}"

    # Plugins
    run-shell ${pkgs.tmuxPlugins.copy-toolkit}/share/tmux-plugins/copy-toolkit/copytk.tmux
    run-shell ${pkgs.tmuxPlugins.better-mouse-mode}/share/tmux-plugins/better-mouse-mode/scroll_copy_mode.tmux

    # Harpoon — bookmark windows and jump to them
    run-shell ${pkgs.tmuxPlugins.harpoon}/share/tmux-plugins/harpoon/harpoon.tmux

    # Resurrect — save and restore sessions across reboots
    set -g @resurrect-capture-pane-contents 'on'
    run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux

    # Continuum — automatic periodic session saving + restore on start
    set -g @continuum-restore 'on'
    set -g @continuum-save-interval '10'
    run-shell ${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux

    # tmuxp — layout preset picker (prefix+S)
    # On NixOS: uses live-linked ~/.config/tmuxp/*.yaml  (edit without rebuild)
    # On any system: falls back to bundled presets from the nix store
    bind-key S display-popup -E -w 80% -h 70% "${tmuxpPicker}"

    # Window picker — fzf list of windows in the current session (prefix+w)
    bind-key w display-popup -E -w 80% -h 70% "${windowPicker}"

    # Sesh — smart session picker (prefix+o)
    # On NixOS: uses live-linked ~/.config/sesh/sesh.toml
    # On any system: falls back to bundled sesh.toml from the nix store
    set -g detach-on-destroy off
    bind-key o display-popup -E -w 80% -h 70% "${seshPicker}"

    # Reload config — greps the updated conf path from the current tmux wrapper (prefix+r)
    # After nixos-rebuild switch, the profile symlink points to the new wrapper with the new conf path.
    bind-key r run-shell "${reloadScript}"

    # Cheatsheet (prefix+/)
    bind-key / display-popup -E -w 80% -h 90% "${pkgs.less}/bin/less ${cheatsheet}"

    # Which-key — discoverable popup menu (prefix+Space)
    # XDG paths required because the nix store is read-only; plugin writes config/init to ~/.config and ~/.local/share
    # Disable autobuild: build.py exits non-zero on first run (set -e propagates it); menu loads from existing generated file
    set -g @tmux-which-key-xdg-enable 1
    set -g @tmux-which-key-disable-autobuild 1
    run-shell ${pkgs.tmuxPlugins.tmux-which-key}/share/tmux-plugins/tmux-which-key/plugin.sh.tmux

    # Rebuild which-key menu from config.yaml (prefix+R)
    bind-key R run-shell "${whichKeyRebuild}"
  '';

  runtimeInputs = pkgs:
    with pkgs; [
      wl-clipboard
      fzf
      tmuxp
      sesh
      fd
      eza
      less
    ];
}
