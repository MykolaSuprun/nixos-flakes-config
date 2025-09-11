{pkgs, ...}: {
  programs.zellij = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  home.file.".config/zellij/config.kdl" = {
    text =
      #kdl
      ''
        pane_frames false
        copy_command "wl-copy"
        env {
          IN_ZELLIJ_SESSION 1
        }

        plugins {
          tab-bar { path "tab-bar"; }
          status-bar { path "status-bar"; }
          strider { path "strider"; }
          compact-bar { path "compact-bar"; }
          session-manager { path "session-manager"; }
          autolock location="https://github.com/fresh2dev/zellij-autolock/releases/latest/download/zellij-autolock.wasm" {
            // Enabled at start?
            is_enabled true
            // Lock when any open these programs open.
            triggers "nvim|vim|git|fzf|zoxide|lazygit|lazydocker"
            // Reaction to input occurs after this many seconds.
            // (An existing scheduled reaction prevents additional reactions.)
            reaction_seconds "2.0"
          }
        }
        load_plugins {
            autolock
        }

        keybinds {
          normal {
            bind "Alt Shift h" { GoToPreviousTab; }
            bind "Alt Shift k" { GoToPreviousTab; }
          }
          locked {
            bind "Alt Shift h" { GoToPreviousTab; }
            bind "Alt Shift k" { GoToPreviousTab; }
            bind "Alt z" {
                // Disable the autolock plugin.
                MessagePlugin "autolock" {payload "disable";};
                // Unlock Zellij.
                SwitchToMode "Normal";
            }
            bind "Alt f" { ToggleFloatingPanes; }
          }
          shared {
              bind "Alt Shift z" {
                  // Enable the autolock plugin.
                  MessagePlugin "autolock" {payload "enable";};
              }
          }
        }
      '';
  };
}
