{ inputs, outputs, lib, config, pkgs, overlays, ... }: {
  # imports = [./default-shell.nix];
  imports = [

    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ] ++ outputs.homeManagerModulesEnv;

  nixpkgs = {
    # You can add overlays here
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);

      permittedInsecurePackages = [ "openssl-1.1.1u" ];
    };
  };

  home.username = "mykolas";
  home.homeDirectory = "/home/mykolas";

  home.stateVersion = "23.11";

  # Let Home Manager install and manage itself.

  services.gpg-agent = {
    enable = true;
    pinentryFlavor = "qt";
  };

  programs = {
    home-manager.enable = true;

    helix = {
      enable = true;
      package = pkgs.helix;
    };

    zsh.enable = true;
    gpg.enable = true;
  };

  # create home configuration files
  home.file = {
    "./.config/nvim/" = {
      source = ./nvim;
      recursive = true;
      enable = true;
    };
    "./.config/helix" = {
      source = ./helix;
      recursive = true;
      enable = true;
    };
    # "./.wezterm.lua" = {
    #   source = ./wezterm/wezterm.lua;
    #   enable = true;
    # };
    "./.tmux.conf" = {
      source = ./tmux/tmux.conf;
      enable = true;
    };
  };

  home.packages = with pkgs; [
    # dev tools 
    libgccjit
    tree-sitter
    lazygit
    ripgrep
    fd
    nodejs
    gh # Github CLI
    cargo
    binutils
    go
    gcc
    fzf
    fzf-zsh
    rnix-lsp
    xclip
    tmux
    tree
    cmake
    gnumake
    wezterm
    git
    git-crypt
    gnupg
    pinentry_qt
    github-desktop
    # haskell
    haskell-language-server
    ghc
    # nix
    nil
    nix-tree
    nix-diff
  ];
}
