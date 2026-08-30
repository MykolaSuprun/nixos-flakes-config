{
  lib,
  ...
}: {
  # NixOS specialisations for all 4 Catppuccin flavors.
  # Each pre-builds a closure live-switchable via:
  #   nixos-rebuild switch --specialisation <flavor>
  # or selectable from the boot menu. Both NixOS `catppuccin.flavor` and HM
  # `myconf.catppuccin.flavor` are forced so every native module follows.
  specialisation = {
    latte.configuration = {
      catppuccin.flavor = lib.mkForce "latte";
      home-manager.users.mykolas = {
        catppuccin.flavor = lib.mkForce "latte";
        myconf.catppuccin.flavor = lib.mkForce "latte";
      };
    };
    frappe.configuration = {
      catppuccin.flavor = lib.mkForce "frappe";
      home-manager.users.mykolas = {
        catppuccin.flavor = lib.mkForce "frappe";
        myconf.catppuccin.flavor = lib.mkForce "frappe";
      };
    };
    macchiato.configuration = {
      catppuccin.flavor = lib.mkForce "macchiato";
      home-manager.users.mykolas = {
        catppuccin.flavor = lib.mkForce "macchiato";
        myconf.catppuccin.flavor = lib.mkForce "macchiato";
      };
    };
    mocha.configuration = {
      catppuccin.flavor = lib.mkForce "mocha";
      home-manager.users.mykolas = {
        catppuccin.flavor = lib.mkForce "mocha";
        myconf.catppuccin.flavor = lib.mkForce "mocha";
      };
    };
  };
}
