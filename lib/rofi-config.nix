{
  mkConfigRasi = {theme ? "catppuccin-latte"}: ''
    configuration{
        modi: "run,drun,window,binds:hypr-binds-list";
        icon-theme: "catppuccin-pairus-folders";
        show-icons: true;
        terminal: "kitty";
        drun-display-format: "{icon} {name}";
        location: 0;
        disable-history: false;
        hide-scrollbar: true;
        display-drun: "   Apps ";
        display-run: "   Run ";
        display-window: " 﩯  Window";
        display-Network: " 󰤨  Network";
        display-binds: " 󰌌  Binds";
        sidebar-mode: true;

        kb-row-up: "Up,Control+k,Shift+Tab,Shift+ISO_Left_Tab";
        kb-row-down: "Down,Control+j";
        kb-accept-entry: "Control+m,Return,KP_Enter";
        kb-remove-to-eol: "Control+Shift+e";
        kb-mode-previous: "Shift+Left,Control+Shift+Tab,Control+h";
        kb-mode-next: "Shift+Right,Control+l";
        kb-mode-complete: "";
        kb-remove-char-back: "BackSpace";
    }
  '';
}
