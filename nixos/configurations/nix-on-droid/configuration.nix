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
    fzf-zsh
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

  terminal = {
    font = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/"
         + "truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFontMono-Regular.ttf"; 
    colors = {
	background = "#eff1f5";
	foreground = "#4c4f69";
	color0 = "#5c5f77";
	color1 = "#d20f39";
	color2 = "#40a02b";
	color3 = "#df8e1d";
	color4 = "#1e66f5";
	color5 = "#ea76cb";
	color6 = "#179299";
	color7 = "#acb0be";
	color8 = "#acb0be";
	color9 = "#d20f39";
	color10 = "#40a02b";
	color11 = "#df8e1d";
	color12 = "#1e66f5";
	color13 = "#ea76cb";
	color14 = "#179299";
	color15 = "#bcc0cc";
    };
  };

  android-integration = {
    am.enable = true;
    termux-open.enable = true;
    termux-open-url.enable = true;
    termux-reload-settings.enable = true;
    termux-setup-storage.enable = true;
    # termux-wake-lock.enable = true;
    xdg-open.enable = true;
  };

  user = {
    userName = "mykolas";
    shell = "${pkgs.zsh}/bin/zsh";
  };
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
