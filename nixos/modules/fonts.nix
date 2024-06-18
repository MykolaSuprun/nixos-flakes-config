{
  inputs,
  pkgs,
  pkgs-stable,
  ...
}: {
  fonts.fontDir.enable = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    # emojione
    roboto-mono
    hack-font
    fira-code
    fira-code-symbols
    liberation_ttf
    fira-code
    fira-code-symbols
    inconsolata
    dejavu_fonts
    corefonts
    google-fonts
    nerdfonts
    font-awesome
    paratype-pt-sans
    paratype-pt-mono
    paratype-pt-serif
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
    libertine
    libertinus
  ];
}
