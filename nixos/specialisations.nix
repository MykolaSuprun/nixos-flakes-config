{
  lib,
  ...
}: {
  # NixOS specialisations DISABLED 2026-10-16.
  #
  # These provided 4 Catppuccin flavour variants (latte/frappe/macchiato/mocha),
  # live-switchable via `nixos-rebuild switch --specialisation <flavour>` and
  # from the boot menu. They are removed because they are not affordable on
  # this host's 511 MiB ESP:
  #
  #   Each specialisation is its OWN SYSTEM TOPLEVEL, so each carries its own
  #   ~37 MiB initrd even though they differ only by a flavour setting.
  #   Measured cost per generation:
  #     kernel bzImage (shared, deduped by store path)   13.2 MiB
  #     initrd x4 (one per specialisation)              148.8 MiB
  #     ------------------------------------------------------
  #     PER GENERATION                                  162.0 MiB
  #   Without specialisations the same generation costs 50.4 MiB.
  #
  #   limine's installer copies new files BEFORE pruning old ones, so the ESP
  #   must transiently hold maxGenerations+1 generations. At 162 MiB/gen even
  #   maxGenerations=2 was marginal; boot.loader.limine.maxGenerations=5 is
  #   only safe because this block is disabled.
  #
  # There is no upstream option to hide specialisations from the boot menu:
  # boot.loader.limine has no such flag, extraEntries only appends, and
  # stripping entries via extraInstallCommands would not help because the
  # initrds are copied while generating the entries, before any pruning.
  #
  # To revert: uncomment the block below (and re-check
  # boot.loader.limine.maxGenerations — it must drop back to ~2).
  #
  # specialisation = {
  #   latte.configuration = {
  #     catppuccin.flavor = lib.mkForce "latte";
  #     home-manager.users.mykolas = {
  #       catppuccin.flavor = lib.mkForce "latte";
  #       myconf.catppuccin.flavor = lib.mkForce "latte";
  #     };
  #   };
  #   frappe.configuration = {
  #     catppuccin.flavor = lib.mkForce "frappe";
  #     home-manager.users.mykolas = {
  #       catppuccin.flavor = lib.mkForce "frappe";
  #       myconf.catppuccin.flavor = lib.mkForce "frappe";
  #     };
  #   };
  #   macchiato.configuration = {
  #     catppuccin.flavor = lib.mkForce "macchiato";
  #     home-manager.users.mykolas = {
  #       catppuccin.flavor = lib.mkForce "macchiato";
  #       myconf.catppuccin.flavor = lib.mkForce "macchiato";
  #     };
  #   };
  #   mocha.configuration = {
  #     catppuccin.flavor = lib.mkForce "mocha";
  #     home-manager.users.mykolas = {
  #       catppuccin.flavor = lib.mkForce "mocha";
  #       myconf.catppuccin.flavor = lib.mkForce "mocha";
  #     };
  #   };
  # };
}
