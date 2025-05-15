(
  final: prev: {
    mynav = prev.buildGoModule rec {
      pname = "rpnc";
      version = "64ec5339d23aaaf4ce54a9f7d6e1a94668e5c77a";
      src = prev.fetchFromGitHub {
        owner = "GianlucaP106";
        repo = "mynav";
        rev = "64ec5339d23aaaf4ce54a9f7d6e1a94668e5c77a";
        sha256 = "sha256-iXKSCXi4n7RZ3HLXDI4zw6kZ/sD3bYVdleS9LVrg4wE=";
      };
      vendorHash = "sha256-EtPGBSW0deqRXO5iQjdgcySbvLSHa1gs25OBlImWWSM=";
      nativeCheckInputs = with prev; [less];
    };
  }
)
