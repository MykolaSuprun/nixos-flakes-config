{
  pkgs,
  pkgs-stable,
  config,
  lib,
  ...
}: {
  options.myconf.nixos.ollama.enable = lib.mkEnableOption "Ollama optimized strictly for the discrete AMD GPU via Vulkan";

  config = lib.mkIf config.myconf.nixos.ollama.enable {
    environment.systemPackages = with pkgs; [
      vulkan-tools
      lmstudio
    ];

    services = {
      # ollama = {
      #   enable = true;
      #   package = pkgs.ollama-vulkan;
      #
      #   environmentVariables = {
      #     # Targets the 7900 XTX directly and prevents any fallback to the 7950X3D's iGPU
      #     GGML_VK_VISIBLE_DEVICES = "0";
      #   };
      # };
      open-webui = {
        enable = true;
        package = pkgs-stable.open-webui;
        port = 3000;
      };
    };
  };
}
