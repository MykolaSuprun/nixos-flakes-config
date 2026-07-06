# Expose all NixOS and Home Manager feature modules as flake outputs.
# Each module is gated by its own enable flag (myconf.nixos.<name>.enable
# for NixOS, myconf.<name>.enable for HM), so importing them is safe —
# nothing activates unless explicitly enabled in a host config.
#
# Usage from another flake:
#   inputs.nixconf.nixosModules.sys-pkgs
#   inputs.nixconf.homeManagerModules.kitty
{
  lib,
  ...
}: {
  flake.nixosModules = lib.pipe (builtins.readDir ../nixos) [
    (lib.filterAttrs (_: type: type == "regular"))
    (lib.mapAttrs' (name: _: {
      name = lib.removeSuffix ".nix" name;
      value = ../nixos/${name};
    }))
  ];

  flake.homeManagerModules = lib.pipe (builtins.readDir ../home-manager/modules) [
    (lib.filterAttrs (_: type: type == "regular"))
    (lib.mapAttrs' (name: _: {
      name = lib.removeSuffix ".nix" name;
      value = ../home-manager/modules/${name};
    }))
  ];
}

