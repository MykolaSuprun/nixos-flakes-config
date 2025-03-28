{
  inputs,
  pkgs,
  pkgs-stable,
  ...
}: {
  fonts = {
    fontDir.enable = true;
    fontconfig.useEmbeddedBitmaps = true;
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    fira-code-symbols
    # emojione
    hack-font
    liberation_ttf
    dejavu_fonts
    corefonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.zed-mono
    nerd-fonts.roboto-mono
    nerd-fonts.noto
    nerd-fonts.liberation
    nerd-fonts.iosevka-term
    nerd-fonts.iosevka
    nerd-fonts.inconsolata
    nerd-fonts.inconsolata-lgc
    nerd-fonts.fira-mono
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.dejavu-sans-mono
    nerd-fonts.code-new-roman
    nerd-fonts._0xproto
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
