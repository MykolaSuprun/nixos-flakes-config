# Herdr — agent multiplexer that lives in your terminal.
#
# Config model (like Hyprland's live-linked Lua):
#   The actual config is a plain TOML file in the checkout:
#     home-manager/users/mykolas/config/herdr/config.toml
#   live-linked into ~/.config/herdr/ below — edit it, then
#   prefix+shift+r inside herdr (or `herdr server reload-config`).
#   No rebuild needed. Nix owns only the symlink; git is the rollback.
#
# Caveats:
#   - herdr reads ONE config file (no include/merge support) and herdr
#     itself may write to it (onboarding) — `onboarding = false` in the
#     file keeps that writer idle.
#   - NEVER run `herdr config reset-keys` — it rewrites config.toml in
#     place (would clobber the checkout copy).
#   - herdr's runtime state (session.json, plugins.json, logs, sockets)
#     lives in the same dir and must stay unmanaged — the link below
#     touches ONLY config.toml.
#   - Plugin-action bindings ([[keys.command]]) belong in the TOML file.
{
  config,
  lib,
  ...
}: let
  liveLinks = import ../../lib/live-links.nix {inherit lib;};
  herdrSrcPath = "${config.home.sessionVariables.NIXOS_CONF_DIR}/home-manager/users/mykolas/config/herdr";
in {
  options.myconf.herdr.enable = lib.mkEnableOption "herdr configuration with tmux-like bindings";

  config = lib.mkIf config.myconf.herdr.enable {
    # Symlink config.toml from the live checkout into ~/.config/herdr for
    # rebuild-free editing (hyprland-style live config). Same pattern as
    # waybar/hyprland/tmuxp live-links.
    home.activation = (liveLinks.mkLiveLinks {
      activationName = "linkHerdrConfig";
      nixPath = ./../users/mykolas/config/herdr;
      runtimePath = "${herdrSrcPath}";
      targetPath = "~/.config/herdr";
      filter = name: name == "config.toml";
    }).home.activation;

    programs.herdr = {
      enable = true;
      # No `settings`: the HM module only manages config.toml when settings
      # are set. Leaving it empty leaves the file fully owned by the live
      # link above (see header comment for the editing workflow).
    };
  };
}
