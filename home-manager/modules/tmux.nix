{
  inputs,
  config,
  pkgs,
  ...
}: {
  programs.tmux = {
    enable = true;
    # terminal = "xterm-256color";
    # escapeTime = 10;
    clock24 = true;
    plugins = with pkgs.tmuxPlugins; [
      sensible
      # vim-tmux-navigator
      catppuccin
      tilish
      yank
      urlview
      sidebar
      logging
      tmux-fzf
      resurrect
      tmux-thumbs
      copy-toolkit
      continuum
      better-mouse-mode
      # fzf-tmux-url
      # sidebar
      # sysstat
    ];
    extraConfig = ''
      # fix teminal colors
      set-option -sa terminal-overrides ",xterm*:Tc"
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

      # keybindings
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      # open panes in the current directory
      bind '-' split-window -v -c "#{pane_current_path}"
      bind | split-window -h -c "#{pane_current_path}"
      # set tmux regularly save it's environment
      set -g @continuum-restore 'on'

      # vim integration
      # See: https://github.com/christoomey/vim-tmux-navigator
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
          | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
      # bind-key -n 'A-h' if-shell "$is_vim" 'send-keys A-h'  'select-pane -L'
      # bind-key -n 'A-j' if-shell "$is_vim" 'send-keys A-j'  'select-pane -D'
      # bind-key -n 'A-k' if-shell "$is_vim" 'send-keys A-k'  'select-pane -U'
      # bind-key -n 'A-l' if-shell "$is_vim" 'send-keys A-l'  'select-pane -R'

      tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
      if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
          "bind-key -n 'A-\\' if-shell \"$is_vim\" 'send-keys A-\\'  'select-pane -l'"
      if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
          "bind-key -n 'A-\\' if-shell \"$is_vim\" 'send-keys A-\\\\'  'select-pane -l'"

      # bind-key -T copy-mode-vi 'A-h' select-pane -L
      # bind-key -T copy-mode-vi 'A-j' select-pane -D
      # bind-key -T copy-mode-vi 'A-k' select-pane -U
      # bind-key -T copy-mode-vi 'A-l' select-pane -R
      # bind-key -T copy-mode-vi 'A-\' select-pane -l

      # vim-like pane resizing  
      bind -r C-k resize-pane -U
      bind -r C-j resize-pane -D
      bind -r C-h resize-pane -L
      bind -r C-l resize-pane -R
    '';
  };
}
