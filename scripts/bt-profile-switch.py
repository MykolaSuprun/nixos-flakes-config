#!/usr/bin/env python3
"""bt-profile-switch — pick a Bluetooth audio device and switch its audio mode.

A small curses TUI that lists paired Bluetooth audio devices and lets you
switch each between High Fidelity Audio (A2DP) and Handsfree (HFP) modes.

Why modes instead of raw profiles: WirePlumber's EnumProfile only lists the
profile family of the CURRENT mode, and Bose QC Ultra / Open Earbuds drop
their A2DP endpoints entirely when in HFP mode (codec-switch bug). So the TUI
groups profiles into logical modes and, when the target mode's profiles are
missing, automatically reconnects the device to restore them.

Data sources:
  - bluetoothctl devices/info  -> paired devices + connection status
  - pw-dump                    -> PipeWire card id + available/active profiles
  - wpctl set-profile          -> apply the profile switch
  - bluetoothctl disconnect/connect -> recovery for stuck devices

Keys:
  Up/Down or j/k   navigate
  Enter            select device / apply mode
  c                connect a disconnected device
  r                refresh device list
  Left / Esc / q   back or quit
"""

import curses
import json
import subprocess
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


def run(cmd, timeout=10):
    """Run a command, return (returncode, stdout, stderr)."""
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout, p.stderr
    except Exception as exc:
        return -1, "", str(exc)


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
    """Compact label for the device list, e.g. 'a2dp-sink-sbc_xq' -> 'A2DP SBC_XQ'."""
    if name == "off":
        return "off"
    if name.startswith("a2dp"):
        codec = name.removeprefix("a2dp-sink-")
        return f"A2DP {codec.upper()}" if codec else "A2DP"
    if name.startswith("headset-head-unit"):
        codec = name.removeprefix("headset-head-unit-")
        return f"HFP {codec.upper()}" if codec else "HFP"
    return name


def get_paired_audio_devices():
    """Return [{mac, name, connected}] for all paired audio-capable devices."""
    rc, out, _ = run(["bluetoothctl", "devices"])
    if rc != 0:
        return []
    devices = []
    for line in out.splitlines():
        parts = line.split(maxsplit=2)
        if len(parts) >= 3 and parts[0] == "Device":
            devices.append({"mac": parts[1], "name": parts[2], "connected": False})

    audio = []
    for d in devices:
        rc, out, _ = run(["bluetoothctl", "info", d["mac"]])
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


def recover_card(stdscr, device):
    """Reconnect a stuck device once to restore its profiles.

    Bose devices drop their A2DP endpoints while in HFP mode (codec-switch
    bug); a disconnect/reconnect cycle brings them back. The PipeWire card
    gets a NEW id on reconnect, so re-fetch and return the fresh card.
    """
    show_message(
        stdscr,
        f"{device['name']} is in a broken profile state (only one audio mode available).\n"
        "Reconnecting the device to restore its profiles...",
    )
    run(["bluetoothctl", "disconnect", device["mac"]], timeout=20)
    time.sleep(1)
    rc, _, err = run(["bluetoothctl", "connect", device["mac"]], timeout=20)
    if rc != 0:
        show_message(stdscr, f"Reconnect failed: {err.strip() or 'unknown error'}")
        return None
    for _ in range(15):
        time.sleep(1)
        cards = get_pipewire_cards()
        if device["mac"] in cards:
            return cards[device["mac"]]
    show_message(stdscr, "Device reconnected but no PipeWire card appeared.")
    return None


def draw_menu(stdscr, title, items, selected, footer):
    """items: list of (label, curses attr)."""
    h, w = stdscr.getmaxyx()
    stdscr.erase()

    y = 0
    if title:
        stdscr.addnstr(y, 0, title, w - 1, curses.A_BOLD)
        y += 1
        stdscr.addnstr(y, 0, "-" * min(w - 1, len(title)), w - 1, curses.A_DIM)
        y += 1

    for i, (label, attr) in enumerate(items):
        if y >= h - 1:
            break
        if i == selected:
            stdscr.addnstr(y, 0, "> " + label, w - 1, curses.A_REVERSE | attr)
        else:
            stdscr.addnstr(y, 0, "  " + label, w - 1, attr)
        y += 1

    if footer:
        stdscr.addnstr(h - 1, 0, footer, w - 1, curses.A_DIM)
    stdscr.refresh()


def show_message(stdscr, text):
    h, w = stdscr.getmaxyx()
    stdscr.erase()
    lines = text.splitlines()
    start = max(0, h // 2 - len(lines) // 2)
    for i, line in enumerate(lines):
        if start + i < h - 1:
            stdscr.addnstr(start + i, 0, line, w - 1)
    stdscr.addnstr(h - 1, 0, "Press any key to continue", w - 1, curses.A_DIM)
    stdscr.refresh()
    stdscr.getch()


def device_screen(stdscr):
    """List paired audio devices; return the selected device or None on quit."""
    devices = get_paired_audio_devices()
    cards = get_pipewire_cards()
    selected = 0

    while True:
        if not devices:
            show_message(stdscr, "No paired Bluetooth audio devices found.\n"
                                 "Pair one with bluetoothctl, then press r to refresh.")
            return None

        items = []
        for d in devices:
            card = cards.get(d["mac"])
            if d["connected"] and card:
                active = ", ".join(short_profile(n) for n in card["active"]) or "?"
                label = f"{d['name']}  [{d['mac']}]  {active}"
                attr = curses.A_NORMAL
            elif d["connected"]:
                label = f"{d['name']}  [{d['mac']}]  connected (no profiles)"
                attr = curses.A_NORMAL
            else:
                label = f"{d['name']}  [{d['mac']}]  disconnected"
                attr = curses.A_DIM
            items.append((label, attr))

        selected = min(selected, max(0, len(items) - 1))
        draw_menu(
            stdscr,
            "Bluetooth audio devices",
            items,
            selected,
            "Up/Down j/k: navigate   Enter: select   c: connect   r: refresh   q: quit",
        )

        key = stdscr.getch()
        if key in (-1, ord("q"), 27):  # EOF or quit
            return None
        elif key in (curses.KEY_UP, ord("k")):
            selected = max(0, selected - 1)
        elif key in (curses.KEY_DOWN, ord("j")):
            selected = min(len(items) - 1, selected + 1)
        elif key in (curses.KEY_ENTER, 10, 13):
            return devices[selected]
        elif key == ord("c"):
            d = devices[selected]
            if not d["connected"]:
                ok, err = connect_device(d["mac"])
                show_message(stdscr, f"Connect {d['name']}: {'OK' if ok else err.strip()}")
                devices = get_paired_audio_devices()
                cards = get_pipewire_cards()
        elif key == ord("r"):
            devices = get_paired_audio_devices()
            cards = get_pipewire_cards()


def mode_screen(stdscr, device):
    """Switch a connected device between A2DP (high fidelity) and HFP (handsfree)."""
    if not device["connected"]:
        show_message(stdscr, f"{device['name']} is not connected.\n"
                             "Connect it from the device list (press c).")
        return

    cards = get_pipewire_cards()
    card = cards.get(device["mac"])
    if not card:
        show_message(stdscr, f"{device['name']} is not available in PipeWire.\n"
                             "Press r in the device list to refresh.")
        return

    by_mode = group_by_mode(card["profiles"])
    active_modes = {mode_of(n) for n in card["active"]}

    # Start with the currently active mode selected.
    selected = 0
    for i, (m, _) in enumerate(MODE_OPTIONS):
        if m in active_modes:
            selected = i
            break

    while True:
        items = []
        for m, label in MODE_OPTIONS:
            marker = "*" if m in active_modes else " "
            cur = ""
            if m in active_modes and by_mode[m]:
                cur = "  <- current"
            items.append((f"{marker} {label}{cur}", curses.A_NORMAL))

        selected = min(selected, max(0, len(items) - 1))
        draw_menu(
            stdscr,
            f"Audio mode for {device['name']}",
            items,
            selected,
            "Up/Down j/k: navigate   Enter: apply   Left/Esc: back   q: quit",
        )

        key = stdscr.getch()
        if key in (-1, ord("q"), 27, curses.KEY_LEFT):  # EOF, quit, or back
            return
        elif key in (curses.KEY_UP, ord("k")):
            selected = max(0, selected - 1)
        elif key in (curses.KEY_DOWN, ord("j")):
            selected = min(len(items) - 1, selected + 1)
        elif key in (curses.KEY_ENTER, 10, 13):
            m, label = MODE_OPTIONS[selected]
            profiles = by_mode[m]
            if not profiles:
                # Stuck state (Bose bug): only one family exposed. Reconnect.
                card = recover_card(stdscr, device)
                if card is None:
                    return
                by_mode = group_by_mode(card["profiles"])
                profiles = by_mode[m]
                if not profiles:
                    show_message(stdscr, f"No {label} profiles available even after reconnect.")
                    continue

            pref = {"a2dp": A2DP_PREF, "headset": HFP_PREF, "off": ["off"]}[m]
            idx = pick_best(profiles, pref)
            name = next((n for i, n, _ in profiles if i == idx), str(idx))
            ok, err = apply_profile(card["card_id"], idx)
            show_message(stdscr, f"Switch {device['name']} to {label} ({short_profile(name)}): "
                                 f"{'OK' if ok else err.strip()}")

            # Refresh state after the switch.
            cards = get_pipewire_cards()
            card = cards.get(device["mac"])
            if card:
                by_mode = group_by_mode(card["profiles"])
                active_modes = {mode_of(n) for n in card["active"]}


def main(stdscr):
    curses.curs_set(0)
    while True:
        device = device_screen(stdscr)
        if device is None:
            break
        mode_screen(stdscr, device)


if __name__ == "__main__":
    curses.wrapper(main)