{
  inputs,
  ...
}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    btProfileSwitch = pkgs.writeShellApplication {
      name = "bt-profile-switch";

      # Runtime deps: python3 (stdlib curses TUI), bluez (bluetoothctl),
      # pipewire (pw-dump), wireplumber (wpctl). The Python script calls
      # these via subprocess, so they must be on PATH when it runs.
      runtimeInputs = with pkgs; [
        python3
        bluez
        pipewire
        wireplumber
      ];

      text = ''
        exec ${pkgs.python3}/bin/python3 ${../../scripts/bt-profile-switch.py} "$@"
      '';
    };
  in {
    packages."bt-profile-switch" = btProfileSwitch;
  };
}