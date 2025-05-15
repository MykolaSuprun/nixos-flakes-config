{
  inputs,
  config,
  pkgs,
  ...
}: {
  programs = {
    fzf.tmux.enableShellIntegration = true;
    tmux = {
      enable = true;
      # terminal = "xterm-256color";
      # escapeTime = 10;
      clock24 = true;
      focusEvents = true;
      keyMode = "vi";
      mouse = true;
      resizeAmount = 10;
      shell = "${pkgs.zsh}/bin/zsh";

      plugins = with pkgs.tmuxPlugins; [
        # sensible
        # vim-tmux-navigator
        # catppuccin
        # tilish
        # yank
        # urlview
        # sidebar
        # logging
        # tmux-fzf
        # resurrect
        # tmux-thumbs
        copy-toolkit
        # continuum
        better-mouse-mode
        # fzf-tmux-url
        # sidebar
        # sysstat
      ];
      extraConfig = ''
        # GENERAL SETTINGS
        # set tmux attach to create new session if none is available
        # new-session -n $HOST

        setw -g aggressive-resize on

        # allow passthrough
        set -gq allow-passthrough on
        set -g visual-activity off

        # fix teminal colors
        # set-option -sa terminal-overrides ",xterm*:Tc"
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

        # set tmux regularly save it's environment
        # set -g @continuum-restore 'on'

        # KEYBINDINGS

        # set prefix
        unbind C-b
        set -g prefix C-Space
        bind C-Space send-prefix

        # Use vi keybindings in copy mode
        setw -g mode-keys vi

        # When pressing Enter in copy mode, copy selection to system clipboard and exit copy-mode
        bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "wl-copy"

        # Optional: Copy on mouse select/drag end (requires mouse mode enabled)
        bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "wl-copy"

        # bind-key -T copy-mode-vi v send-keys -X begin-selection
        # bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
        # bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

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


        # is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"

        is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"

        is_fzf="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?fzf$'"

        bind -n M-h run "($is_vim && tmux send-keys M-h) || tmux select-pane -L"
        bind -n M-j run "($is_vim && tmux send-keys M-j)  || ($is_fzf && tmux send-keys C-j) || tmux select-pane -D"
        # bind-key -n 'M-k' if-shell "$is_vim" 'send-keys M-k' 'select-pane -U'
        bind -n M-k run "($is_vim && tmux send-keys M-k) || ($is_fzf && tmux send-keys C-k)  || tmux select-pane -U"
        bind -n M-l run  "($is_vim && tmux send-keys M-l) || tmux select-pane -R"
        # bind-key -n C-\ if-shell "$is_vim" "send-keys M-\\" "select-pane -l"
      '';
    };
  };
}
