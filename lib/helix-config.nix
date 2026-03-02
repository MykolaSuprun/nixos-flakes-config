{
  themes = {
    latte = "rose_pine_dawn";
    mocha = "catppuccin_mocha";
  };

  mkConfigToml = {
    theme ? "rose_pine_dawn",
  }: ''
    theme = "${theme}"
    [editor]
    line-number = "relative"
  '';
}
