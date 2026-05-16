{
  lib,
  config,
  ...
}: {
  options.myconf.ghostty.enable = lib.mkEnableOption "ghostty terminal emulator";
  config = lib.mkIf config.myconf.ghostty.enable {
    programs.ghostty = {
      enable = true;
      enableZshIntegration = true;
      installBatSyntax = true;
      installVimSyntax = true;

      settings = {
        # Theme — auto-tracks catppuccin module flavor
        theme = "catppuccin-${config.catppuccin.flavor}";

        # Font — JetBrainsMono Nerd Font with ligatures
        font-family = "JetBrainsMono NF Regular";
        font-size = 10;
        font-feature = [
          "+calt" # contextual alternates — main JetBrainsMono ligatures
          "+liga" # standard ligatures
          "+zero" # slashed zero
          "+ss01" # alternate r
          "+ss02" # alternate >=  <=
        ];
        # Break ligatures under cursor — prevents confusing overlap in neovim insert mode
        font-shaping-break = "cursor";

        # Shell integration
        shell-integration = "detect";
        # ssh-env: rewrites TERM to xterm-256color on hosts without ghostty terminfo
        # ssh-terminfo: auto-installs ghostty terminfo on remote hosts
        shell-integration-features = "cursor,sudo,title,ssh-env,ssh-terminfo";

        # Window chrome
        gtk-single-instance = true;
        gtk-titlebar = false;
        gtk-wide-tabs = false;
        window-padding-x = 4;
        window-padding-y = 4;
        window-theme = "system";
        confirm-close-surface = false;

        # Rendering — linear blending avoids colour fringing on neovim rendered text
        alpha-blending = "linear-corrected";

        # Slight transparency; Hyprland compositor handles blur
        background-opacity = 0.95;

        # UX
        mouse-hide-while-typing = true;

        # term stays as default "xterm-ghostty" — full feature set
        # (kitty keyboard protocol, focus events, true colour, image protocol)
      };
    };
  };
}
