{ inputs, config, pkgs, ... }: {
  programs.tmux = {
    enable = true;
    # terminal = "xterm-256color";
    # escapeTime = 10;
    clock24 = true;
    plugins = with pkgs.tmuxPlugins; [
      # sensible
      # vim-tmux-navigator
      catppuccin
      # tilish
      # yank
      # urlview
      # sidebar
      # logging
      # tmux-fzf
      # resurrect
      # tmux-thumbs
      # copy-toolkit
      # continuum
      better-mouse-mode
      # fzf-tmux-url
      # sidebar
      # sysstat
    ];
    extraConfig = ''
      # set tmux attach to create new session if none is available
      new-session -n $HOST
      # fix teminal colors
      # set-option -sa terminal-overrides ",xterm*:Tc"
      set -g default-terminal "tmux-256color"
      set -ag terminal-overrides ",xterm-256color:RGB"
      set-option -a terminal-overrides ",alacritty:RGB"
      # better window switching
      bind -n M-H previous-window
      bind -n M-L next-window
      # set prefix
      unbind C-b
      set -g prefix C-Space
      bind C-Space send-prefix
      # set mouse mode
      set -g mouse on
      # window numbering
      set -g base-index 1
      set -g pane-base-index 1
      set-window-option -g pane-base-index 1
      set-option -g renumber-windows on

      # set tmux regularly save it's environment
      set -g @continuum-restore 'on'

      # keybindings
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      # open panes in the current directory
      bind '-' split-window -v -c "#{pane_current_path}"
      bind | split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # vim-like pane resizing
      bind -r C-k resize-pane -U
      bind -r C-j resize-pane -D
      bind -r C-h resize-pane -L
      bind -r C-l resize-pane -R

      is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
      bind-key -n 'M-h' if-shell "$is_vim" 'send-keys M-h' 'select-pane -L'
      bind-key -n 'M-j' if-shell "$is_vim" 'send-keys M-j' 'select-pane -D'
      bind-key -n 'M-k' if-shell "$is_vim" 'send-keys M-k' 'select-pane -U'
      bind-key -n 'M-l' if-shell "$is_vim" 'send-keys M-l' 'select-pane -R'
      bind-key -n 'M-\' if-shell "$is_vim" 'send-keys M-\' 'select-pane -l'
    '';
  };
}
