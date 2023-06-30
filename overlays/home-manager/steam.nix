{ inputs, ... }:
(self: super: {
  steam = super.steam.override {
    extraPkgs = pkgs: with pkgs; [ pango harfbuzz libthai ];
  };
})
