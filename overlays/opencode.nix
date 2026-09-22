# Wrap opencode so its binary carries a full dev toolbox on PATH — LSPs,
# formatters, linters, security scanners and CLI utilities — without spilling
# any of them into the global environment. opencode's agent spawns these tools
# by name, so they must be reachable from its own wrapper.
#
# The upstream package already wraps the binary with ripgrep; we re-wrap in
# postFixup to prepend our tool set (nested wrappers are fine — each layer
# only prepends PATH).
#
# HERDR_AGENT is set per-process (not exported globally) so Herdr's
# foreground-process detection still recognizes opencode through the
# makeWrapper bash script (which otherwise runs as .opencode-wrapped).
#
# The toolbox list lives in lib/opencode-tools.nix — shared with the
# opencode2 (v2) overlay.
self: super: {
  opencode = super.opencode.overrideAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [super.makeWrapper];

    postFixup =
      (oldAttrs.postFixup or "")
      + ''
        wrapProgram $out/bin/opencode \
          --prefix PATH : ${super.lib.makeBinPath (import ../lib/opencode-tools.nix super)} \
          --set HERDR_AGENT "opencode"
      '';
  });
}
