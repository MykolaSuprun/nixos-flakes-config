self: super: {
  lmstudio = super.lmstudio.overrideAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [super.makeWrapper];

    postFixup =
      (oldAttrs.postFixup or "")
      + ''
        wrapProgram $out/bin/lmstudio \
          --prefix PATH : ${super.lib.makeBinPath [
          super.rocmPackages.rocm-smi
          super.lm_sensors
          super.procps
          super.pciutils
          super.sysfsutils
        ]}
      '';
  });
}
