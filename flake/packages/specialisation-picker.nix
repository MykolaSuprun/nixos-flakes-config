{
  inputs,
  ...
}: {
  perSystem = {
    pkgs,
    ...
  }: let
    specialisationPicker = pkgs.writeShellApplication {
      name = "specialisation-picker";

      runtimeInputs = with pkgs; [
        python3
      ];

      text = ''
        exec ${pkgs.python3}/bin/python3 ${../../scripts/specialisation-picker.py} "$@"
      '';
    };
  in {
    packages."specialisation-picker" = specialisationPicker;
  };
}
