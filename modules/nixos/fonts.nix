{
  inputs,
  pkgs,
  ...
}: {
  fonts.fontDir.enable = true;

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    emojione
    victor-mono
    roboto-mono
    hack-font
    fira-code
    fira-code-symbols
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    proggyfonts
    inconsolata
    dejavu_fonts
    corefonts
    google-fonts
    nerdfonts
    paratype-pt-sans
    paratype-pt-mono
    paratype-pt-serif
    caladea
    carlito
  ];
}
