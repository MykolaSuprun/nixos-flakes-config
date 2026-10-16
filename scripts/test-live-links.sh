#!/usr/bin/env bash
# Harness for lib/live-links.nix — simulates Home Manager activation runs
# against a sandboxed $HOME. Renders the generated activation script with a
# writable runtime path (the check renders it with the @LL_RUNTIME@ marker).
#
# Usage: test-live-links.sh <rendered-activation.sh> <fixture-dir> <workdir>
#
# Scenario matrix:
#   A. fresh run: links created, onLink fires exactly once
#   B. rerun unchanged: no relink, onLink must NOT fire
#   C. retarget to a different runtime path: links updated, hook fires
#   D. stale managed-prefix link pruned; foreign links + real files preserved
#   E. real file at a managed target: activation aborts, file untouched
#   F. missing source: activation aborts with a message
set -u

SCRIPT=${1:?usage: test-live-links.sh <rendered-script> <fixture-dir> <workdir>}
FIXTURE=${2:?usage: test-live-links.sh <rendered-script> <fixture-dir> <workdir>}
WORK=${3:?usage: test-live-links.sh <rendered-script> <fixture-dir> <workdir>}

export HOME="$WORK/home"
TARGET="$HOME/.config/live-links-check"
R1="$WORK/runtime1"
R2="$WORK/runtime2"
LOG="$WORK/hook.log"
export LL_HOOK_LOG="$LOG"

PASS=0
FAIL=0
ok()   { PASS=$((PASS+1)); printf 'PASS: %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf 'FAIL: %s\n' "$1" >&2; }

# run <runtime-path>: materialize a substituted copy and execute under sandbox
# HOME. The exit code of the activation script propagates to the caller.
run() {
  local rt=$1
  sed "s|@LL_RUNTIME@|$rt|g" "$SCRIPT" > "$WORK/run.sh"
  RUN_OUT=$(HOME="$HOME" bash "$WORK/run.sh" 2>&1)
}

link_target() { readlink -- "$1" 2>/dev/null; }

rm -rf "$WORK"
mkdir -p "$TARGET" "$R1" "$R2"
cp -r "$FIXTURE"/. "$R1"/
cp -r "$FIXTURE"/. "$R2"/
# Store fixtures are mode 444; the sandbox runtime must be writable (scenario E
# writes through a link, scenario F deletes a source).
chmod -R u+w "$R1" "$R2"
: > "$LOG"

# ── A: fresh run links everything and fires the hook once ────────────────────
run "$R1"
[ -f "$LOG" ] || : > "$LOG"
[ "$(wc -l < "$LOG")" = 1 ] && ok "A: onLink fired once on fresh link" || { bad "A: hook fired $(wc -l < "$LOG") times"; }
for f in "alpha.txt" "beta.txt" "spaced name.txt"; do
  if [ -L "$TARGET/$f" ] && [ "$(link_target "$TARGET/$f")" = "$R1/$f" ]; then
    ok "A: $f -> $R1/$f"
  else
    bad "A: $f missing or wrong target ($(link_target "$TARGET/$f"))"
  fi
done

# ── B: unchanged rerun: no hook ──────────────────────────────────────────────
: > "$LOG"
run "$R1"
if [ "$(wc -l < "$LOG")" = 0 ]; then ok "B: onLink NOT fired when nothing changed"
else bad "B: hook fired on unchanged rerun"; fi
for f in "alpha.txt" "beta.txt" "spaced name.txt"; do
  [ "$(link_target "$TARGET/$f")" = "$R1/$f" ] && ok "B: $f still -> R1" || bad "B: $f retargeted unexpectedly"
done

# ── C: retarget to a second runtime path ─────────────────────────────────────
: > "$LOG"
run "$R2"
if [ "$(wc -l < "$LOG")" = 1 ]; then ok "C: onLink fired after retarget"
else bad "C: hook fired $(wc -l < "$LOG") times after retarget"; fi
for f in "alpha.txt" "beta.txt" "spaced name.txt"; do
  [ "$(link_target "$TARGET/$f")" = "$R2/$f" ] && ok "C: $f -> R2" || bad "C: $f not retargeted ($(link_target "$TARGET/$f"))"
done

# ── D: prunes stale managed links; preserves foreign links and real files ────
: > "$LOG"
ln -s "$R2/ghost.txt" "$TARGET/ghost.txt"   # stale managed-prefix link
ln -s /etc/hostname "$TARGET/foreign.txt"   # foreign link (other prefix)
echo real > "$TARGET/real.txt"              # real file
run "$R2"
[ ! -e "$TARGET/ghost.txt" ] && [ ! -L "$TARGET/ghost.txt" ] && ok "D: stale managed link pruned" || bad "D: ghost.txt survived"
[ -L "$TARGET/foreign.txt" ] && ok "D: foreign link preserved" || bad "D: foreign.txt clobbered"
[ -f "$TARGET/real.txt" ] && [ ! -L "$TARGET/real.txt" ] && ok "D: real file preserved" || bad "D: real.txt clobbered"
[ "$(wc -l < "$LOG")" = 1 ] && ok "D: prune counts as a change (hook fired)" || bad "D: hook fired $(wc -l < "$LOG") times"

# ── E: collision with a real file aborts and leaves it intact ────────────────
rm -f "$TARGET/alpha.txt"                  # replace the link with a REAL file
echo "precious" > "$TARGET/alpha.txt"
chmod 644 "$TARGET/alpha.txt"
before=$(stat -c '%i %Y' "$TARGET/alpha.txt")
run "$R2" && rc=0 || rc=$?
if [ "$rc" != 0 ] && printf '%s' "$RUN_OUT" | grep -q "refusing to replace"; then
  ok "E: collision aborted with message"
else
  bad "E: collision rc=$rc out=${RUN_OUT:-<none>}"
fi
after=$(stat -c '%i %Y' "$TARGET/alpha.txt")
[ "$before" = "$after" ] && [ "$(cat "$TARGET/alpha.txt")" = "precious" ] && ok "E: colliding file untouched" || bad "E: colliding file modified"

# ── F: missing source aborts ─────────────────────────────────────────────────
rm "$TARGET/alpha.txt"                       # restore the managed link slot
rm "$R2/beta.txt"
run "$R2" && rc=0 || rc=$?
if [ "$rc" != 0 ] && printf '%s' "$RUN_OUT" | grep -q "source missing"; then
  ok "F: missing source aborted with message"
else
  bad "F: missing source rc=$rc out=${RUN_OUT:-<none>}"
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
