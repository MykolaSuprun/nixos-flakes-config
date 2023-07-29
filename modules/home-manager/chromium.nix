{
  inputs,
  pkgs,
  ...
}: {
  programs.chromium = {
    enable = true;
    package = pkgs.chromium;
    extensions = [
      {id = "fdjamakpfbbddfjaooikfcpapjohcfmg";} # Dashlane
      {id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";} # Ublock origin
      {id = "dlnejlppicbjfcfcedcflplfjajinajd";} # Bonjourr
      {id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp";} # PrivacyBadger
      {id = "gebbhagfogifgggkldgodflihgfeippi";} # Return YouTube Dislike
      {id = "kmhcihpebfmpgmihbkipmjlmmioameka";} # Eternl
      {id = "dmkamcknogkgcdfhhbddcghachkejeap";} # Keplr
      {id = "kbmfpngjjgdllneeigpgjifpgocmfgmb";} # Reddit Enhancement Suite
      {id = "kbfnbcaeplbcioakkpcpgfkobkghlhen";} # Grammarly
      {id = "ponfpcnoihfmfllpaingbgckeeldkhle";} # Enhancer for YouTube
      {id = "mnjggcdmjocbbbhaepdhchncahnbgone";} # SponsorBlock for YouTube
      {
        id = "oepjogknopbbibcjcojmedaepolkghpb";
      } # Editor for Docs, Sheets & Slides
      {id = "ecabifbgmdmgdllomnfinbmaellmclnh";} # Reader view
      {id = "cimiefiiaegbelhefglklhhakcgmhkai";} # Plasma integration
      {id = "ailoabdmgclmfmhdagmlohpjlbpffblp";} # Surfshark vpn
      {id = "dphilobhebphkdjbpfohgikllaljmgbn";} # SimpleLogin anonymous mail
      {id = "pioclpoplcdbaefihamjohnefbikjilc";} # Evernote web clipper
    ];
  };
}
