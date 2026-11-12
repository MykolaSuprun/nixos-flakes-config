_: {
  flake.modules.homeManager.chatgpt = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.myconf.chatgpt.enable = lib.mkEnableOption "ChatGPT desktop application";

    config = lib.mkIf config.myconf.chatgpt.enable {
      home.packages = [
        (pkgs.chatgpt.override {
          # The locked unstable Cargo hook breaks Tectonic; use the stable build.
          tectonic-unwrapped = pkgs.stable.tectonic-unwrapped;
        })
      ];
    };
  };
}
