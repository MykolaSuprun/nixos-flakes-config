{
  inputs,
  pkgs,
  ...
}: {
  fonts.fontDir.enable = true;

  fonts.packages = with pkgs; [
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
    inconsolata
    dejavu_fonts
    corefonts
    google-fonts
    nerdfonts
    font-awesome
    paratype-pt-sans
    paratype-pt-mono
    paratype-pt-serif
    caladea
    carlito
    corefonts # windows fonts
    hannom
    wqy_zenhei
    wqy_microhei
    ttf-tw-moe
    ipafont
    hanazono
    baekmuk-ttf
    nanum
    nanum-gothic-coding
    culmus
    twitter-color-emoji
    libertine
    libertinus
    symbola
  ];
}
