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
      vim-tmux-navigator
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
      # set vi-mode
      set-window-option -g mode-keys vi
      # keybindings
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      # open panes in the current directory
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
      # set tmux regularly save it's environment
      set -g @continuum-restore 'on'

    '';
  };
}
