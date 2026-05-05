# lib/live-links.nix — helper for symlinking dotfiles from the live checkout
# into ~/.config for immediate (rebuild-free) editing.
#
# Usage:
#   let liveLinks = import ./live-links.nix { inherit lib; }; in
#   liveLinks.mkLiveLinks {
#     activationName = "linkWaybarThemes";
#     nixPath        = ./path/to/source/dir;   # nix path — used by builtins.readDir at eval time
#     runtimePath    = "$NIXOS_CONF_DIR/...";  # shell string — actual symlink source at activation time
#     targetPath     = "~/.config/waybar/themes"; # shell string — symlink destination
#     # filter        = name: true;            # optional: predicate on file names (default: all files)
#   }
#
# The split between nixPath and runtimePath is intentional:
#   - builtins.readDir needs a nix store-traceable path at *eval* time to discover files.
#   - The symlinks themselves must point to the live checkout (not the nix store)
#     so edits take effect without a rebuild.
#
# Returns: { home.activation.${activationName} = lib.hm.dag.entryAfter [...] {...}; }
{lib}: {
  mkLiveLinks = {
    activationName,
    nixPath,
    runtimePath,
    targetPath,
    filter ? (_name: true),
  }: let
    files = builtins.attrNames (lib.filterAttrs
      (name: type: type == "regular" && filter name)
      (builtins.readDir nixPath));

    linkCmds = lib.strings.concatLines (map (f: ''
      rm -f ${targetPath}/${f}
      ln -s ${runtimePath}/${f} ${targetPath}/${f}
    '') files);
  in {
    home.activation.${activationName} = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p ${targetPath}
      ${linkCmds}
    '';
  };
}
