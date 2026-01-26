{
  config,
  lib,
  pkgs,
  ...
}: {
  # Simply install just the packages
  environment.packages = with pkgs; [
    # User-facing stuff that you really really want to have
    neovim # or some other editor, e.g. nano or neovim

    # Some common stuff that people expect to have
    procps
    lazygit
    killall
    diffutils
    findutils
    utillinux
    tzdata
    hostname
    man
    gnugrep
    gnupg
    gnused
    gnutar
    bzip2
    gzip
    xz
    zip
    unzip
    git
    gh
    nix-output-monitor
    nvd
    eza
    fzf
    xclip
    tree
    ripgrep
    git
    git-crypt
    gnupg
    fd
    bat
    fh
    lf
    bottom
  ];

  android-integration = {
    am.enable = true;
    termux-open.enable = true;
    xdg-open.enable = true;
    termux-reload-settings.enable = true;
    termux-setup-storage.enable = true;
  };

  user.shell = pkgs.zsh;
  # terminal.font = "${pkgs.jetbrains-mono}";

  # Backup etc files instead of failing to activate generation if a file already exists in /etc
  environment.etcBackupExtension = ".bak";

  # Read the changelog before changing this value
  system.stateVersion = "24.05";

  # Set up nix for flakes
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Set your time zone
  #time.timeZone = "Europe/Berlin";
}
