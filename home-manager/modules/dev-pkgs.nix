{
  inputs,
  pkgs,
  system,
  ...
}: {
  programs = {
    helix = {
      enable = true;
      package = pkgs.helix;
    };
    delta = {
      enable = true;
      enableGitIntegration = true;
    };
    direnv = {
      enable = true;
      enableBashIntegration = true; # see note on other shells below
      nix-direnv.enable = true;
    };
    zsh.enable = true;
    gpg.enable = true;
    fzf = {
      enable = true;
      tmux.enableShellIntegration = true;
    };
    lazygit = {enable = true;};
    kitty = {
      enable = true;
      settings = {
        force_ltr = "no";
        disable_ligatures = "never";
        sync_to_monitor = "no";
        confirm_os_window_close = 0;
      };
    };
    yazi = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      extraPackages = with pkgs; [
        jq
        fd
        zoxide
        resvg
        imagemagick
        fzf
        poppler
        ffmpeg
        zip
        ripgrep
        resvg
        imagemagick
        wl-clipboard
      ];
      plugins = {
        git = pkgs.yaziPlugins.git;
        sudo = pkgs.yaziPlugins.sudo;
        lsar = pkgs.yaziPlugins.lsar;
        diff = pkgs.yaziPlugins.diff;
        rsync = pkgs.yaziPlugins.rsync;
        piper = pkgs.yaziPlugins.piper;
        mount = pkgs.yaziPlugins.mount;
        lazygit = pkgs.yaziPlugins.lazygit;
        dupes = pkgs.yaziPlugins.dupes;
        chmod = pkgs.yaziPlugins.chmod;
        duckdb = pkgs.yaziPlugins.duckdb;
        yatline = pkgs.yaziPlugins.yatline;
        restore = pkgs.yaziPlugins.restore;
        githead = pkgs.yaziPlugins.githead;
        starship = pkgs.yaziPlugins.starship;
        projects = pkgs.yaziPlugins.projects;
        compress = pkgs.yaziPlugins.compress;
        files = pkgs.yaziPlugins.vcs-files;
        mediainfo = pkgs.yaziPlugins.mediainfo;
        bookmarks = pkgs.yaziPlugins.bookmarks;
        paste = pkgs.yaziPlugins.smart-paste;
        clipboard = pkgs.yaziPlugins.wl-clipboard;
        char = pkgs.yaziPlugins.jump-to-char;
        motions = pkgs.yaziPlugins.relative-motions;
        catppuccin = pkgs.yaziPlugins.yatline-catppuccin;
      };
    };
    ghostty = {
      enable = true;
      installVimSyntax = true;
      settings = {
        font-size = 10;
        gtk-single-instance = true;
        window-theme = "system";
        gtk-titlebar = false;
        gtk-wide-tabs = false;
        gtk-adwaita = false;
        # theme = "catppuccin-latte";
      };
    };
  };

  home.packages = with pkgs; [
    # dev tools
    cachix
    inputs.my-nixvim.packages.${system}.lazyvim
    inputs.my-nixvim.packages.${system}.nixvim
    inputs.my-nixvim.packages.${system}.nvim
    neovide
    # mynav
    # sublime4
    # zed-editor
    nvtopPackages.amd
    tree-sitter
    ripgrep
    nodejs
    cargo
    binutils
    openssl
    go
    gcc
    fzf
    tree
    cmake
    gnumake
    wezterm
    git
    git-crypt
    gnupg
    alejandra
    ghc
    usbutils
    pciutils
    lshw-gui
    mesa-demos
    bat
    # nix
    nix-tree
    nix-diff
    nixfmt-classic
    fh
    poppler # pdf preview
    jq
    fd
    zoxide
    resvg
    imagemagick

    # python
    uv

    # terminal utils
    superfile
    fd
    browsh # tui browser
    gh # Github CLI
    xclip
    sqlcmd
    killall
    bottom
    btop
    lazydocker
    lazysql
  ];
}
