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
    # mynav
    sublime4
    zed-editor
    nvtopPackages.amd
    btop
    lazydocker
    lazysql
    code-cursor
    tree-sitter
    ripgrep
    fd
    nodejs
    gh # Github CLI
    delta
    cargo
    binutils
    openssl
    go
    gcc
    fzf
    fzf-zsh
    xclip
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
    # python
    uv

    lf
    sqlcmd
    killall
    bottom
  ];
}
