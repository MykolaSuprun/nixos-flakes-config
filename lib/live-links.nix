# lib/live-links.nix — symlink dotfiles from the live checkout into ~/.config
# for immediate (rebuild-free) editing. Atomic, idempotent, self-pruning.
#
# Usage:
#   let liveLinks = import ./live-links.nix { inherit lib; }; in
#   liveLinks.mkLiveLinks {
#     activationName = "linkWaybarThemes";
#     nixPath        = ./path/to/source/dir;   # nix path — builtins.readDir at eval time
#     runtimePath    = "$NIXOS_CONF_DIR/...";  # shell string — actual symlink target at activation time
#     targetPath     = "~/.config/waybar/themes"; # shell string — link destination ("~/" expands to $HOME)
#     # filter        = name: true;            # optional: predicate on file names (default: all)
#     # after         = ["writeBoundary"];     # optional: HM DAG activation ordering
#     # backup        = false;                 # optional: move a colliding real file aside instead of aborting
#     # onLink        = "";                    # optional: shell snippet, runs ONLY when something changed, best-effort
#   }
#
# The split between nixPath and runtimePath is intentional:
#   - builtins.readDir needs a nix store-traceable path at *eval* time to
#     discover the managed file set.
#   - The symlinks themselves point at the live checkout (not the nix store)
#     so edits take effect without a rebuild.
#
# Guarantees:
#   - atomic: relinks use `ln -sfn` (coreutils: temp symlink + rename(2), so a
#     reader never observes a missing link)
#   - idempotent: unchanged links are skipped (readlink -f compare); the
#     change flag gates the onLink hook so daemons reload only when needed
#   - safe: a real (non-symlink) file at a managed target aborts activation
#     (backup = true moves it aside to <name>.hm-back instead); links whose
#     target is outside runtimePath are never modified; missing sources abort
#     with a clear message instead of creating dangling links
#   - self-pruning: stale managed links (target under runtimePath/ but not in
#     the evaluated file set) are removed — e.g. renamed/removed repo files
#
# Constraints:
#   - managed filenames must not contain quotes, backslashes, $ or backticks
#     (asserted at eval time)
#   - targetPath must be exclusive to this instance (one manager per directory);
#     pruning is scoped to runtimePath-prefixed symlinks, so other managers'
#     store-backed or foreign links are never touched
{lib}: let
  # Double-quoted shell word — keeps a tilde-expanded $HOME path expandable.
  dq = s: "\"${s}\"";

  # Expand a leading ~/ into ${HOME} (a single-quoted "~" would never expand).
  expandTilde = p:
    if lib.hasPrefix "~/" p
    then "\${HOME}/" + lib.substring 2 (lib.stringLength p) p
    else p;

  badChars = ["'" "\"" "\\" "$" "`"];
in {
  mkLiveLinks = {
    activationName,
    nixPath,
    runtimePath,
    targetPath,
    filter ? (_name: true),
    after ? ["writeBoundary"],
    backup ? false,
    onLink ? "",
  }: let
    entries = lib.filterAttrs (_name: type:
      (type == "regular" || type == "symlink") && filter _name
    ) (builtins.readDir nixPath);

    managedFiles = let
      raw = builtins.attrNames entries;
    in
      if raw == [ ]
      then
        throw "live-links.${activationName}: no files matched in ${toString nixPath} — check nixPath/filter"
      else if lib.any (f: lib.any (c: lib.elem c badChars) (lib.stringToCharacters f)) raw
      then
        throw "live-links.${activationName}: managed filenames must not contain quotes, backslashes, $ or backticks: ${
          toString (lib.filter (f: lib.any (c: lib.elem c badChars) (lib.stringToCharacters f)) raw)
        }"
      else raw;

    backupFlag = if backup then "1" else "0";

    managedDecl = "declare -A _liveManaged=(" + lib.concatMapStringsSep " " (f: "[${lib.escapeShellArg f}]=1") managedFiles + ")";

    # Per-file: source guard → collision policy → skip-if-unchanged → atomic relink.
    linkOne = f: ''
      # ---- ${f} ----
      if [ ! -e "''${_ll_runtime}/${f}" ] && [ ! -L "''${_ll_runtime}/${f}" ]; then
        _ll_error "${activationName}: source missing: ''${_ll_runtime}/${f}"
        exit 1
      fi
      if [ -e "''${_ll_target}/${f}" ] && [ ! -L "''${_ll_target}/${f}" ]; then
        if [ ${backupFlag} = 1 ]; then
          if [ -e "''${_ll_target}/${f}.hm-back" ]; then
            _ll_error "${activationName}: cannot back up ''${_ll_target}/${f}: ''${_ll_target}/${f}.hm-back already exists"
            exit 1
          fi
          mv -- "''${_ll_target}/${f}" "''${_ll_target}/${f}.hm-back"
          _ll_verbose "backed up colliding file ''${_ll_target}/${f}"
        else
          _ll_error "${activationName}: refusing to replace real file at ''${_ll_target}/${f} (pass backup = true to move it aside)"
          exit 1
        fi
      fi
      if [ -L "''${_ll_target}/${f}" ]; then
        _cur="$(readlink -f -- "''${_ll_target}/${f}" 2>/dev/null || true)"
        _new="$(readlink -f -- "''${_ll_runtime}/${f}" 2>/dev/null || true)"
        if [ -n "$_new" ] && [ "$_cur" = "$_new" ]; then
          _ll_verbose "unchanged: ''${_ll_target}/${f}"
        else
          ln -sfn -- "''${_ll_runtime}/${f}" "''${_ll_target}/${f}"
          _liveChanged=1
          _ll_verbose "relinked ''${_ll_target}/${f}"
        fi
      else
        ln -sfn -- "''${_ll_runtime}/${f}" "''${_ll_target}/${f}"
        _liveChanged=1
        _ll_verbose "linked ''${_ll_target}/${f}"
      fi
    '';

    # Remove stale links we own: symlink ∧ raw target under runtimePath/ ∧
    # basename not in the managed set. Foreign/store links and real files are
    # never matched (prefix check) or never touched (symlink check).
    pruneBlock = ''
      # ---- prune stale managed links ----
      for _l in "$_ll_target"/*; do
        [ -L "$_l" ] || continue
        _t="$(readlink -- "$_l" 2>/dev/null || true)"
        case "$_t" in
          "''${_ll_runtime}"/*) ;;
          *) continue ;;
        esac
        _b="''${_l##*/}"
        if [ -n "''${_liveManaged[$_b]+set}" ]; then
          continue
        fi
        rm -f -- "$_l"
        _liveChanged=1
        _ll_verbose "pruned stale link ''${_l}"
      done
    '';

    hookBlock = lib.optionalString (onLink != "") ''
      # ---- onLink hook (change-gated, best-effort) ----
      if (( _liveChanged )); then
        if ! eval ${lib.escapeShellArg onLink}; then
          _ll_verbose "${activationName}: onLink hook failed (non-fatal)"
        fi
      fi
    '';

    script = ''
      # live-links: ${activationName} (generated — do not edit)
      _ll_runtime=${dq runtimePath}
      _ll_target=${dq (expandTilde targetPath)}
      _liveChanged=0
      _ll_verbose() { if [ -n "''${VERBOSE:-}" ]; then printf 'live-links: %s\n' "$*" >&2; fi; return 0; }
      _ll_error() { printf 'live-links: %s\n' "$*" >&2; }
      mkdir -p -- "$_ll_target" || { _ll_error "${activationName}: cannot create target dir ''${_ll_target}"; exit 1; }
      ${managedDecl}
      ${lib.concatMapStringsSep "\n" linkOne managedFiles}
      ${pruneBlock}
      ${hookBlock}
      : # live-links: ${activationName} done
    '';
  in {
    home.activation.${activationName} = lib.hm.dag.entryAfter after script;

    # Raw script text — not part of the HM interface; exposed for
    # scripts/test-live-links.sh (flake/checks.nix renders an instance and
    # runs the harness against it).
    _script = script;
  };
}
