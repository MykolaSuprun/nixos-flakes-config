{pkgs, ...}: {
  programs.kitty = {
    enable = true;
    enableGitIntegration = true;
    font = {
      name = "JetBrainsMono NF Normal";
      size = 9;
    };
    shellIntegration = {
      enableZshIntegration = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
    };
  };
}
