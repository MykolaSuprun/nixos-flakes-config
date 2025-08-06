{pkgs, ...}: {
  program.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono NF Normal";
      size = 10;
    };
    shellIntegration = {
      enableZshIntegration = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
    };
    setting = {
    };
  };
}
