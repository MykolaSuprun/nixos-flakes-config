---
status: active
item: bluetooth audio — bt-profile-switch rewrite bugs + BlueZ 5.87 A2DP regression
started: 2026-09-22
---

# NixConf Bluetooth Backlog

Domain memory for Bluetooth / BlueZ / A2DP audio work in this repo.

## Current Item

**Fix bt-profile-switch script, integrate with rofi, fix BlueZ 5.87 A2DP regression**

## State (flattened 2026-09-22)

### Problem statement
1. `bt-profile-switch` (rofi picker) does nothing when run — menus silently exit.
2. Bose QC Ultra Headphones (BC:87:FA:46:67:3A) stuck in HFP (handsfree) mode
   again — A2DP profiles missing from EnumProfile.

### Root causes (verified)

**1. bt-profile-switch broken by the rofi UI rewrite (commit 862cb23, gen 215).**
`rofi_select()` calls `run(args)` with the default 10s timeout; interactive rofi
is killed after 10s → returns None → script exits silently at line 311. Verified
by execution trace (rofi invoked → TimeoutExpired → None → return).
Second bug: `short_profile()` shows "HFP HEADSET-HEAD-UNIT" / "A2DP A2DP-SINK"
for exact profile names: `removeprefix("headset-head-unit-")` does NOT match the
exact name (no trailing dash), leaving the full string as the "codec".

**2. Bose HFP = BlueZ 5.87 regression, not the autoswitch path.**
Commit 912f5efb0 ("a2dp: Fix handling of codec capability storage", 2026-06-15,
in 5.87) added a bogus `i >= 2` condition to load_remote_sep()'s cached-SEP
parse loop — the loop never runs (i starts at 0), i stays 0, and
`if (i != size) continue;` discards EVERY cached remote SEP:
  - `load_remote_sep() Unable to load LastUsed: rseid 5 not found`
  - `a2dp-sink profile connect failed: Device or resource busy` (sink.c: sink
    already CONNECTING / connect_id>0 from the racing AVDTP discover)
  - `avdtp.c:cancel_request() Abort: Connection timed out (110)`
Device comes up HFP-only (EnumProfile = off + headset-head-unit-*), no A2DP.
Upstream fix b7d71e5 (2026-07-10) is master-only; 5.87 is the latest release
(2026-07-03). Fixes bluez#2285 (Bose QC Ultra 2nd Gen, same error, workaround =
disconnect/reconnect); matches bluez#2524 (HFP-only reconnect on bluez 5.87 +
pipewire 1.6.8 + wireplumber 0.5.17 — our exact stack), bluez#2273, bluez#2321.

### Why the previous fix didn't work
- pipewire.nix `bluetooth.autoswitch-to-headset-profile = false` — VERIFIED
  active (`wpctl settings` → false). Only stops WirePlumber switching to HFP on
  mic requests. The real failure is BlueZ failing to connect A2DP (cache
  regression) — the device lands in HFP as a fallback, not via autoswitch.
- desktop-config.nix `bluetooth-resume-recovery` service — VERIFIED runs
  (14:48:39). A2DP still failed at 14:54 with a fresh bluetoothd, and at 16:04
  with NO resume involved. Stale MediaEndpoints from resume isn't the cause.

### Applied (2026-09-22, approved)
1. `scripts/bt-profile-switch.py` — `rofi_select` now `run(args, timeout=None)`
   + docstring; `short_profile` exact-name fallback (`codec == name` → bare
   family). Verified via function-level test (short_profile cases +
   rofi_select timeout arg).
2. `binds.lua` — new `SUPER+CTRL+B` → `bt-profile-switch`, description
   "Bluetooth audio mode (rofi)" → shows in the rofi binds tab.
3. BlueZ fix, CORRECTED 2026-09-23: the first attempt (global
   `overlays/bluez-a2dp-fix.nix`) was WRONG — it patched pkgs.bluez for every
   consumer, rebuilding pipewire → chromium/electron (WebRTC) from source
   (multi-hour; proven by vanilla-vs-overlay drv comparison + requisites
   diff listing the patch inside chromium's closure). Replaced with a
   TARGETED `hardware.bluetooth.package` override in `nixos/pipewire.nix`
   (same `patches/bluez-a2dp-fix-load-remote-sep.patch`). The bug is in
   bluetoothd, not libbluetooth, so PipeWire/Chromium keep cached upstream
   libs: verified `pkgs.chromium.drvPath` reverted to the cached
   `7xnkpf08…` while `hardware.bluetooth.package` is the patched
   `zm5bc6dwd…` (already built). DROP when nixpkgs ships bluez > 5.87.

### Nix-in-git-files gotcha (hit here)
New files were invisible to the flake (`.pkgs.bluez.patches` = 2, no patch).
Nix git-flakes only copy TRACKED files (modified tracked = seen w/ warning;
new untracked = invisible). Had to `git add` the new overlay/patch/backlog
before the config saw them. Stage, not commit.

### Notes / caveats
- `bluetoothctl devices` shows 27 entries, ~20 junk BLE random addresses — bluez
  cache pollution from BLE scanning (privacy addresses; bluez 5.87 grays them).
  Cosmetic, not a config bug.
- bt-profile-switch is a CLI tool in home.packages, NOT a Hyprland keybind —
  hence never in the rofi binds tab until bound (fix #2).
- The Bose is dual-stack: BREDR connected, LE bonded ("LE-Bose QC Ultra
  Headphones" is the LE identity name).

### Next actions
- Reconnect Bose after the bluez patch; verify A2DP (`pw-dump` EnumProfile has
  a2dp-*; `wpctl inspect 70` profile != headset-head-unit).
- Optionally clear the bluez cache to purge junk LE addresses.

### Resume point
Re-read this file + `scripts/bt-profile-switch.py` header + `nixos/pipewire.nix`
before further bluetooth work.
