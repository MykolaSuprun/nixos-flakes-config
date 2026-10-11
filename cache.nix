# Single source of truth for binary caches. Consumed by:
# - nixos/nix-conf.nix (runtime nix daemon settings, all hosts)
# - flake/packages/nixos-install.nix (fresh-install ~/.config/nix/nix.conf)
# - flake/packages/{nixos-build,nixos-check,nixos-remote-build}.nix (script flags)
# NOTE: flake.nix nixConfig CANNOT import this (nix refuses thunked nixConfig
# values) — keep its literal copy in sync when editing this file.
# Keys verified 2026-09-20 against cache dashboards and
# DeterminateSystems/nix-installer source.
{
  trusted-substituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
    "https://hyprland.cachix.org"
    "https://install.determinate.systems"
    "https://noctalia.cachix.org"
    # comfyui-nix flake (private ComfyUI stack, nixconf-private) — prebuilt
    # ROCm torch wheels for gfx1100. Added 2026-10-11.
    "https://comfyui.cachix.org"
  ];
  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    # Determinate/flakehub key set (-3..-10, current as of 2026-09):
    # install.determinate.systems narinfos are signed with the flakehub keys
    # (cache.flakehub.com-* names don't have to match the substituter URL).
    "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
    "cache.flakehub.com-4:Asi8qIv291s0aYLyH6IOnr5Kf6+OF14WVjkE6t3xMio="
    "cache.flakehub.com-5:zB96CRlL7tiPtzA9/WKyPkp3A2vqxqgdgyTVNGShPDU="
    "cache.flakehub.com-6:W4EGFwAGgBj3he7c5fNh9NkOXw0PUVaxygCVKeuvaqU="
    "cache.flakehub.com-7:mvxJ2DZVHn/kRxlIaxYNMuDG1OvMckZu32um1TadOR8="
    "cache.flakehub.com-8:moO+OVS0mnTjBTcOUh2kYLQEd59ExzyoW1QgQ8XAARQ="
    "cache.flakehub.com-9:wChaSeTI6TeCuV/Sg2513ZIM9i0qJaYsF+lZCXg0J6o="
    "cache.flakehub.com-10:2GqeNlIp6AKp4EF2MVbE1kBOp9iBSyo0UPR9KoR0o1Y="
    "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
  ];
}
