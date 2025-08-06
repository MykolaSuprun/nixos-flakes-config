{
  inputs,
  pkgs,
  ...
}: {
  programs = {
    helix = {
      enable = true;
      package = pkgs.helix;
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
    ghostty = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      installVimSyntax = true;
      settings = {
        font-size = 10;
        gtk-single-instance = true;
        window-theme = "system";
        gtk-titlebar = false;
        gtk-wide-tabs = false;
        gtk-adwaita = false;
      };
    };
  };

  home.packages = with pkgs; [
    # dev tools
    cachix
    inputs.my-neovim.packages.${system}.default
    inputs.my-nixvim.packages.${system}.nixvim
    inputs.my-nixvim.packages.${system}.lazyvim
    mynav
    sublime4
    zed-editor
    nvtopPackages.amd
    btop
    lazydocker
    code-cursor
    tree-sitter
    ripgrep
    fd
    nodejs
    gh # Github CLI
    meld
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
    glxinfo
    bat
    # nix
    nix-tree
    nix-diff
    nixfmt-classic
    fh

    lf
    sqlcmd
    killall
    bottom
  ];
}
