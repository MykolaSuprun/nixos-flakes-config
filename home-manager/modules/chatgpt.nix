{
  pkgs,
  lib,
  config,
  ...
}: {
  options.myconf.chatgpt.enable = lib.mkEnableOption "ChatGPT desktop application";
  config = lib.mkIf config.myconf.chatgpt.enable {
    home.packages = with pkgs; [chatgpt];
  };
}
