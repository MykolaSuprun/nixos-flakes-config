(self: super: {
  steam = super.steam.override {
    extraPkgs = pkgs:
      with pkgs; [
        pango
        harfbuzz
        libthai
        mangohud
        xorg.libXcursor
        xorg.libXi
        xorg.libXinerama
        xorg.libXScrnSaver
        libpng
        libpulseaudio
        libvorbis
        stdenv.cc.cc.lib
        libkrb5
        keyutils
      ];
  };
})
