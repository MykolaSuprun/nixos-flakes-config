#!/usr/bin/env python3
"""bt-profile-switch — rofi picker for Bluetooth audio profile switching.

Lists paired Bluetooth audio devices in a rofi dmenu and switches the picked
device between High Fidelity Audio (A2DP) and Handsfree (HFP) modes. Results
are reported via notify-send; the tool exits after one switch (re-run for more).

Why modes instead of raw profiles: WirePlumber's EnumProfile only lists the
profile family of the CURRENT mode, and Bose QC Ultra / Open Earbuds drop
their A2DP endpoints entirely when in HFP mode (codec-switch bug). So the
picker groups profiles into logical modes and, when the target mode's
profiles are missing, automatically reconnects the device to restore them.

bluetoothctl output is ANSI-colorized for SOME devices (e.g. devices with
LE bonds show up gray as '\x1b[1;30mDevice ...\x1b[0m') — strip escapes
everywhere or those devices silently vanish from the parser (bluez 5.87).

Data sources:
  - bluetoothctl devices Paired / info   -> paired devices + connection status
  - pw-dump                              -> PipeWire card id + available/active profiles
  - wpctl set-profile                    -> apply the profile switch
  - bluetoothctl disconnect/connect      -> recovery for stuck devices

CLI (non-interactive, for debugging without a rofi display):
  --print-devices   list detected devices + current profile, then exit
"""

import json
import re
import subprocess
import sys
import time

# A2DP sink/source, HFP, HSP — used to filter audio-capable devices.
AUDIO_UUIDS = ("0000110b", "0000110d", "0000111e", "00001108")

# Preferred codecs per mode, best first (used when applying a mode).
A2DP_PREF = [
    "a2dp-sink-sbc_xq",
    "a2dp-sink",
    "a2dp-sink-aptx_hd",
    "a2dp-sink-ldac",
    "a2dp-sink-aptx",
    "a2dp-sink-sbc",
]
HFP_PREF = ["headset-head-unit", "headset-head-unit-cvsd"]

MODE_OPTIONS = [
    ("a2dp", "High Fidelity Audio (A2DP)"),
    ("headset", "Handsfree (HFP)"),
    ("off", "Off"),
]

BACK_ITEM = "← Back"

# bluez 5.x colors some lines (gray for certain devices) even when piped.
ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")


def strip_ansi(text):
    """Remove ANSI escape sequences from bluetoothctl output."""
    return ANSI_RE.sub("", text)


def run(cmd, timeout=10, input_text=None):
    """Run a command, return (returncode, stdout, stderr).

    input_text (str) is piped to the child's stdin — required for rofi
    dmenu, which reads its option list from stdin (no stdin = empty list).
    """
    try:
        p = subprocess.run(cmd, capture_output=True, text=True,
                           timeout=timeout, input=input_text)
        return p.returncode, p.stdout, p.stderr
    except Exception as exc:
        return -1, "", str(exc)


def notify(summary, body="", icon="bluetooth-active"):
    """Fire a desktop notification; failure is harmless."""
    run(["notify-send", "-a", "Bluetooth", "-i", icon, summary, body])


def rofi_select(prompt, items, current=0):
    """Show a rofi dmenu; return the selected index, or None on cancel.

    timeout=None is required: the menu is interactive, so the default 10s
    run() timeout would kill rofi mid-browse and silently return None —
    the exact "does nothing" failure this rewrite introduced (gen 215).
    """
    args = ["rofi", "-dmenu", "-i", "-format", "i", "-p", prompt,
            "-selected-row", str(current)]
    # Pipe the menu entries — dmenu shows an empty list without stdin input
    # (the exact "empty pick list" failure; items were built but never sent).
    rc, out, _ = run(args, timeout=None, input_text="\n".join(items) + "\n")
    if rc != 0 or not out.strip():
        return None
    try:
        idx = int(out.strip())
        return idx if 0 <= idx < len(items) else None
    except ValueError:
        return None


def rofi_error(text):
    """Show an error message in rofi (blocks until dismissed)."""
    run(["rofi", "-e", text], timeout=120)


def mode_of(profile_name):
    """Map a profile name to its logical mode: a2dp | headset | off | other."""
    if profile_name == "off":
        return "off"
    if profile_name.startswith("a2dp"):
        return "a2dp"
    if profile_name.startswith(("headset", "hfp", "hsp")):
        return "headset"
    return "other"


def short_profile(name):
    """Compact label, e.g. 'a2dp-sink-sbc_xq' -> 'A2DP SBC_XQ'.

    Exact names lack the trailing dash, so removeprefix leaves them
    unchanged (codec == name) — fall back to the bare family instead of
    echoing the raw profile (was "HFP HEADSET-HEAD-UNIT" / "A2DP A2DP-SINK").
    """
    if name == "off":
        return "off"
    if name.startswith("a2dp"):
        codec = name.removeprefix("a2dp-sink-")
        return "A2DP" if codec == name else f"A2DP {codec.upper()}"
    if name.startswith("headset-head-unit"):
        codec = name.removeprefix("headset-head-unit-")
        return "HFP" if codec == name else f"HFP {codec.upper()}"
    return name


def get_paired_audio_devices():
    """Return [{mac, name, connected}] for paired audio-capable devices.

    Uses 'devices Paired' (not 'devices', which lists every MAC bluez has
    ever seen — TVs, random LE addresses — and is slow to filter).
    """
    rc, out, _ = run(["bluetoothctl", "devices", "Paired"])
    if rc != 0:
        # Older bluez has no Paired subcommand; fall back to 'devices'.
        rc, out, _ = run(["bluetoothctl", "devices"])
    out = strip_ansi(out)
    devices = []
    for line in out.splitlines():
        parts = line.split(maxsplit=2)
        if len(parts) >= 3 and parts[0] == "Device":
            devices.append({"mac": parts[1], "name": parts[2], "connected": False})

    audio = []
    for d in devices:
        rc, out, _ = run(["bluetoothctl", "info", d["mac"]])
        out = strip_ansi(out)
        if not any(u in out for u in AUDIO_UUIDS):
            continue
        d["connected"] = "Connected: yes" in out
        audio.append(d)
    return audio


def get_pipewire_cards():
    """Return {mac: {card_id, profiles: [(index, name, desc)], active: [names]}}."""
    rc, out, _ = run(["pw-dump"])
    if rc != 0:
        return {}
    try:
        data = json.loads(out)
    except json.JSONDecodeError:
        return {}

    cards = {}
    for obj in data:
        if obj.get("type") != "PipeWire:Interface:Device":
            continue
        props = obj.get("info", {}).get("props", {})
        if props.get("device.api") != "bluez5":
            continue
        mac = props.get("api.bluez5.address", "")
        params = obj.get("info", {}).get("params", {})
        profiles = [
            (p.get("index"), p.get("name"), p.get("description", ""))
            for p in params.get("EnumProfile", [])
        ]
        active = [p.get("name") for p in params.get("Profile", [])]
        cards[mac] = {
            "card_id": obj.get("id"),
            "profiles": profiles,
            "active": active,
            "description": props.get("device.description", ""),
        }
    return cards


def group_by_mode(profiles):
    """Split [(index, name, desc)] into {mode: [(index, name, desc)]}."""
    groups = {"a2dp": [], "headset": [], "off": [], "other": []}
    for p in profiles:
        groups[mode_of(p[1])].append(p)
    return groups


def pick_best(profiles, pref_order):
    """Return the profile index of the best preferred profile, else the first."""
    for pref in pref_order:
        for idx, name, _ in profiles:
            if name == pref:
                return idx
    return profiles[0][0]


def apply_profile(card_id, index):
    rc, _, err = run(["wpctl", "set-profile", str(card_id), str(index)])
    return rc == 0, err


def connect_device(mac):
    rc, _, err = run(["bluetoothctl", "connect", mac], timeout=20)
    return rc == 0, err


def recover_card(device):
    """Reconnect a stuck device once to restore its profiles.

    Bose devices drop their A2DP endpoints while in HFP mode (codec-switch
    bug); a disconnect/reconnect cycle brings them back. The PipeWire card
    gets a NEW id on reconnect, so re-fetch and return the fresh card.
    """
    notify(device["name"],
           "broken profile state — reconnecting to restore profiles…",
           "bluetooth-disabled")
    run(["bluetoothctl", "disconnect", device["mac"]], timeout=20)
    time.sleep(1)
    rc, _, err = run(["bluetoothctl", "connect", device["mac"]], timeout=20)
    if rc != 0:
        rofi_error(f"Reconnect failed: {err.strip() or 'unknown error'}")
        return None
    for _ in range(15):
        time.sleep(1)
        cards = get_pipewire_cards()
        if device["mac"] in cards:
            return cards[device["mac"]]
    rofi_error("Device reconnected but no PipeWire card appeared.")
    return None


def device_status_label(device, cards):
    """One-line status suffix for the device list."""
    card = cards.get(device["mac"])
    if device["connected"] and card:
        active = ", ".join(short_profile(n) for n in card["active"]) or "?"
        return f"  [{active}]"
    if device["connected"]:
        return "  [connected — no profiles]"
    return "  [disconnected]"


def mode_menu(device, card):
    """Pick and apply an audio mode for a connected device. Returns nothing."""
    by_mode = group_by_mode(card["profiles"])
    active_modes = {mode_of(n) for n in card["active"]}

    items, current = [], 0
    for i, (m, label) in enumerate(MODE_OPTIONS):
        marker = "● " if m in active_modes else "  "
        items.append(f"{marker}{label}")
        if m in active_modes:
            current = i
    items.append(f"  {BACK_ITEM}")

    idx = rofi_select(f"󰂯 {device['name']}", items, current)
    if idx is None or items[idx].endswith(BACK_ITEM):
        return

    m, label = MODE_OPTIONS[idx]
    profiles = by_mode[m]
    if not profiles:
        # Stuck state (Bose bug): only one family exposed. Reconnect.
        card = recover_card(device)
        if card is None:
            return
        by_mode = group_by_mode(card["profiles"])
        profiles = by_mode[m]
        if not profiles:
            rofi_error(f"No {label} profiles available even after reconnect.")
            return

    pref = {"a2dp": A2DP_PREF, "headset": HFP_PREF, "off": ["off"]}[m]
    pidx = pick_best(profiles, pref)
    name = next((n for i, n, _ in profiles if i == pidx), str(pidx))
    ok, err = apply_profile(card["card_id"], pidx)
    if ok:
        notify(device["name"], f"switched to {label} ({short_profile(name)})")
    else:
        rofi_error(f"Switch to {label} failed: {err.strip() or 'unknown error'}")


def print_devices():
    """Non-interactive dump of detected devices + state (debug/test path)."""
    devices = get_paired_audio_devices()
    cards = get_pipewire_cards()
    if not devices:
        print("no paired bluetooth audio devices found")
        return 1
    for d in devices:
        print(f"{d['name']}  [{d['mac']}]{device_status_label(d, cards)}")
    return 0


def main():
    devices = get_paired_audio_devices()
    cards = get_pipewire_cards()

    while True:
        if not devices:
            rofi_error("No paired Bluetooth audio devices found.\n"
                       "Pair one with bluetoothctl first.")
            return

        items = [d["name"] + device_status_label(d, cards) for d in devices]
        idx = rofi_select("󰂯 Bluetooth audio", items)
        if idx is None:
            return

        device = devices[idx]
        if not device["connected"]:
            # Only useful action for a disconnected device: connect it.
            idx = rofi_select(f"󰂯 {device['name']} (disconnected)",
                              ["  Connect", f"  {BACK_ITEM}"])
            if idx != 0:
                # Cancel or Back (index 1) — return to the device list.
                continue
            notify(device["name"], "connecting…")
            ok, err = connect_device(device["mac"])
            if not ok:
                rofi_error(f"Connect failed: {err.strip() or 'unknown error'}")
            devices = get_paired_audio_devices()
            cards = get_pipewire_cards()
            continue

        card = cards.get(device["mac"])
        if not card:
            rofi_error(f"{device['name']} is not available in PipeWire.")
            return

        mode_menu(device, card)
        return  # one action per invocation (as documented)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--print-devices":
        sys.exit(print_devices())
    if len(sys.argv) > 1 and sys.argv[1] in ("--help", "-h"):
        print(__doc__)
        sys.exit(0)
    main()
