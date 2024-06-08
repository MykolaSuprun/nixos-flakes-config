{
  inputs,
  pkgs,
  ...
}: {
  programs = {
    anyrun = {
      enable = true;
      config = {
        plugins = [
          # An array of all the plugins you want, which either can be paths to the .so files, or their packages
          inputs.anyrun.packages.${pkgs.system}.applications
          inputs.anyrun.packages.${pkgs.system}.kidex
          inputs.anyrun.packages.${pkgs.system}.websearch
          inputs.anyrun.packages.${pkgs.system}.translate
          inputs.anyrun.packages.${pkgs.system}.shell
          # "${inputs.anyrun.packages.${pkgs.system}.anyrun-with-all-plugins}/lib/kidex"
        ];
        x = {fraction = 0.5;};
        y = {fraction = 0.3;};
        width = {fraction = 0.3;};
        hideIcons = false;
        ignoreExclusiveZones = false;
        layer = "overlay";
        hidePluginInfo = false;
        closeOnClick = false;
        showResultsImmediately = false;
        maxEntries = null;
      };
      extraCss = ''
        @define-color bg-col  rgba(30, 30, 46, 0.7);
        @define-color bg-col-light rgba(150, 220, 235, 0.7);
        @define-color border-col rgba(30, 30, 46, 0.7);
        @define-color selected-col rgba(150, 205, 251, 0.7);
        @define-color fg-col #D9E0EE;
        @define-color fg-col2 #F28FAD;

        * {
          transition: 200ms ease;
          font-family: "JetBrainsMono Nerd Font";
          font-size: 1.3rem;
        }

        #window {
          background: transparent;
        }

        #plugin,
        #main {
          border: 3px solid @border-col;
          color: @fg-col;
          background-color: @bg-col;
        }
        /* anyrun's input window - Text */
        #entry {
          color: @fg-col;
          background-color: @bg-col;
        }

        /* anyrun's ouput matches entries - Base */
        #match {
          color: @fg-col;
          background: @bg-col;
        }

        /* anyrun's selected entry - Red */
        #match:selected {
          color: @fg-col2;
          background: @selected-col;
        }

        #match {
          padding: 3px;
          border-radius: 16px;
        }

        #entry, #plugin:hover {
          border-radius: 16px;
        }

        box#main {
          background: rgba(30, 30, 46, 0.7);
          border: 1px solid @border-col;
          border-radius: 15px;
          padding: 5px;
        }
      '';

      extraConfigFiles."some-plugin.ron".text = ''
        Config(
          // for any other plugin
          // this file will be put in ~/.config/anyrun/some-plugin.ron
          // refer to docs of xdg.configFile for available options
        )
      '';
    };
  };
}
