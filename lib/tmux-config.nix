{
  mkTmuxConf = {
    pkgs,
    catppuccinFlavor ? "latte",
  }: ''
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

    # better window switching
    bind -n M-H previous-window
    bind -n M-L next-window

    # vim-like pane resizing
    bind -r C-k resize-pane -U
    bind -r C-j resize-pane -D
    bind -r C-h resize-pane -L
    bind -r C-l resize-pane -R

    # smart pane switching with vim awareness
    is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
    is_fzf="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?fzf$'"

    bind -n M-h run "($is_vim && tmux send-keys M-h) || tmux select-pane -L"
    bind -n M-j run "($is_vim && tmux send-keys M-j) || ($is_fzf && tmux send-keys C-j) || tmux select-pane -D"
    bind -n M-k run "($is_vim && tmux send-keys M-k) || ($is_fzf && tmux send-keys C-k) || tmux select-pane -U"
    bind -n M-l run "($is_vim && tmux send-keys M-l) || tmux select-pane -R"

    # Catppuccin
    set -g @catppuccin_flavor "${catppuccinFlavor}"
    run-shell ${pkgs.tmuxPlugins.catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux

    # Plugins
    run-shell ${pkgs.tmuxPlugins.copy-toolkit}/share/tmux-plugins/copy-toolkit/copytk.tmux
    run-shell ${pkgs.tmuxPlugins.better-mouse-mode}/share/tmux-plugins/better-mouse-mode/scroll_copy_mode.tmux
  '';

  runtimeInputs = pkgs:
    with pkgs; [
      wl-clipboard
      fzf
    ];
}
