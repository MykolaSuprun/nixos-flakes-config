# This file defines overlays
{ inputs, pkgs-stable, ... }: {

  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays

  home_modifications = final: prev: {
    steam = (prev.steam.override {
      extraPkgs = pkgs: with pkgs; [ pango harfbuzz libthai ];
    });
    discord = prev.discord.override { withOpenASAR = true; };

    # neovim = (prev.neovim.override {
    #   configure = {
    #     packages.myPlugins = with prev.vimPlugins; {
    #       start = [
    #         (nvim-treesitter.withPlugins (
    #           plugins: with plugins; [
    #             nix
    #             python
    #           ]
    #         ))
    #       ];
    #     };
    #   };
    # });
  };
}
