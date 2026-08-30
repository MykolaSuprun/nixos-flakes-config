#!/usr/bin/env python3
"""specialisation-picker — pick a Catppuccin NixOS specialisation and switch.

A small curses TUI that lists available NixOS specialisations (catppuccin flavors)
and lets you hot-swap live or set for next boot.

Data sources:
  - /run/current-system/specialisation/*  -> available specialisations (primary)
  - /nix/var/nix/profiles/system/specialisation/* -> fallback
  - $SYS_THEME env var (catppuccin-<flavor>) -> current flavor marker

Actions:
  - switch-to-configuration via /run/current-system/specialisation/<name>/bin/switch-to-configuration

Keys:
  Up/Down or j/k   navigate
  Enter            hot-swap live (switch)
  b                set for next boot (boot)
  B                boot + reboot now
  r                refresh
  q / Esc / Left   quit
"""

import curses
import os
import subprocess
import sys


def run(cmd, timeout=60):
    """Run a command, return (returncode, stdout, stderr)."""
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout, p.stderr
    except Exception as exc:
        return -1, "", str(exc)


def get_specialisations():
    """Return sorted list of available specialisation names."""
    candidates = [
        "/run/current-system/specialisation",
        "/nix/var/nix/profiles/system/specialisation",
    ]
    for path in candidates:
        try:
            if os.path.isdir(path):
                entries = [
                    d
                    for d in os.listdir(path)
                    if os.path.isdir(os.path.join(path, d))
                ]
                if entries:
                    return sorted(entries)
        except Exception:
            continue
    # Fallback: try to query flake (only works if flake present and Nix available)
    # This is best-effort; empty list is handled as error in UI.
    flake_dirs = [
        os.path.expanduser("~/workspaces/src/nixconf"),
        os.environ.get("NIXOS_CONF_DIR", ""),
        os.environ.get("NH_FLAKE", ""),
        ".",
    ]
    for d in flake_dirs:
        if d and os.path.isfile(os.path.join(d, "flake.nix")):
            rc, out, _ = run(
                [
                    "nix",
                    "eval",
                    f"{d}#nixosConfigurations.geks-nixos.config.specialisation",
                    "--apply",
                    "builtins.attrNames",
                    "--json",
                ],
                timeout=15,
            )
            if rc == 0:
                try:
                    import json

                    names = json.loads(out)
                    if isinstance(names, list) and names:
                        return sorted(names)
                except Exception:
                    pass
    return []


def get_current_flavor():
    """Return current flavor from $SYS_THEME (catppuccin-<flavor>) or empty."""
    theme = os.environ.get("SYS_THEME", "")
    if theme.startswith("catppuccin-"):
        return theme.removeprefix("catppuccin-")
    # Fallback: try to read from current system's etc if we wrote a marker
    for p in [
        "/run/current-system/etc/catppuccin-flavor",
        "/etc/catppuccin-flavor",
    ]:
        try:
            with open(p) as f:
                return f.read().strip()
        except Exception:
            continue
    return ""


def switch_specialisation(name, mode):
    """Switch to specialisation via switch-to-configuration.

    mode: 'switch' (live) or 'boot' (next boot).
    Returns (ok, output).
    """
    # Primary path: current system's switch-to-configuration per specialisation
    candidates = [
        f"/run/current-system/specialisation/{name}/bin/switch-to-configuration",
        f"/nix/var/nix/profiles/system/specialisation/{name}/bin/switch-to-configuration",
    ]
    switch_bin = None
    for c in candidates:
        if os.path.isfile(c) and os.access(c, os.X_OK):
            switch_bin = c
            break
    if switch_bin:
        # Need sudo unless we're root
        if os.geteuid() == 0:
            cmd = [switch_bin, mode]
        else:
            cmd = ["sudo", switch_bin, mode]
        rc, out, err = run(cmd, timeout=120)
        return rc == 0, (out + err).strip() or ("OK" if rc == 0 else "unknown error")
    # Fallback: try nixos-rebuild
    flake_ref = os.environ.get("NH_FLAKE") or os.environ.get(
        "NIXOS_CONF_DIR", os.path.expanduser("~/workspaces/src/nixconf")
    )
    # Prefer NH_FLAKE/NIXOS_CONF_DIR, else use current flake dir
    if os.geteuid() == 0:
        cmd = ["nixos-rebuild", mode, "--specialisation", name, "--flake", flake_ref]
    else:
        cmd = ["sudo", "nixos-rebuild", mode, "--specialisation", name, "--flake", flake_ref]
    rc, out, err = run(cmd, timeout=300)
    return rc == 0, (out + err).strip() or ("OK" if rc == 0 else "unknown error")


def draw_menu(stdscr, title, items, selected, footer):
    """items: list of (label, attr)."""
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


def show_message(stdscr, text, wait=True):
    h, w = stdscr.getmaxyx()
    stdscr.erase()
    lines = text.splitlines()
    start = max(0, h // 2 - len(lines) // 2)
    for i, line in enumerate(lines):
        if start + i < h - 1:
            # center-ish
            x = max(0, (w - len(line)) // 2) if w > len(line) else 0
            try:
                stdscr.addnstr(start + i, x, line, w - 1)
            except curses.error:
                pass
    if wait:
        stdscr.addnstr(h - 1, 0, "Press any key to continue", w - 1, curses.A_DIM)
    else:
        stdscr.addnstr(h - 1, 0, "Working...", w - 1, curses.A_DIM)
    stdscr.refresh()
    if wait:
        stdscr.getch()


def confirm(stdscr, prompt):
    """Show prompt and return True if user presses y/Y."""
    h, w = stdscr.getmaxyx()
    stdscr.erase()
    lines = prompt.splitlines()
    start = max(0, h // 2 - len(lines) // 2)
    for i, line in enumerate(lines):
        if start + i < h - 1:
            x = max(0, (w - len(line)) // 2) if w > len(line) else 0
            stdscr.addnstr(start + i, x, line, w - 1, curses.A_BOLD)
    stdscr.addnstr(h - 1, 0, "Press y to confirm, any other key to cancel", w - 1, curses.A_DIM)
    stdscr.refresh()
    k = stdscr.getch()
    return k in (ord("y"), ord("Y"))


def main(stdscr):
    curses.curs_set(0)
    curses.use_default_colors()
    # Enable keypad for arrow keys
    stdscr.keypad(True)

    current = get_current_flavor()
    specialisations = get_specialisations()
    selected = 0
    # Preselect current if found
    if current in specialisations:
        selected = specialisations.index(current)

    while True:
        if not specialisations:
            show_message(
                stdscr,
                "No specialisations found.\n"
                "Checked:\n"
                "  /run/current-system/specialisation\n"
                "  /nix/var/nix/profiles/system/specialisation\n"
                "Build them with:\n"
                "  nixos-rebuild switch\n"
                "or ensure flake's nixos/specialisations.nix is imported.",
            )
            return

        # Build menu items with current marker and flavor icon
        flavor_icons = {
            "latte": "🌻",
            "frappe": "🪴",
            "macchiato": "🌺",
            "mocha": "🌙",
        }
        items = []
        for name in specialisations:
            icon = flavor_icons.get(name, "●")
            marker = "  "
            attr = curses.A_NORMAL
            if name == current:
                marker = "● "
                attr = curses.A_BOLD
                label = f"{marker}{icon} {name}  (current)"
            else:
                label = f"{marker}{icon} {name}"
            # Add description
            if name == "latte":
                label += "  — light"
            elif name == "frappe":
                label += "  — dark soft"
            elif name == "macchiato":
                label += "  — dark medium"
            elif name == "mocha":
                label += "  — dark"
            items.append((label, attr))

        title = "Catppuccin Specialisations"
        footer = "j/k:↑↓  Enter:hot-swap  b:boot  B:boot+reboot  r:refresh  q/Esc:quit"
        # Show current at top
        if current:
            title += f"  (current: {current})"

        draw_menu(stdscr, title, items, selected, footer)
        key = stdscr.getch()

        if key in (-1, ord("q"), 27, curses.KEY_LEFT):  # quit
            # 27 is Esc, curses.KEY_LEFT is also used for back
            # Need to distinguish Esc vs arrow: curses handles it
            break
        elif key in (curses.KEY_UP, ord("k")):
            selected = max(0, selected - 1)
        elif key in (curses.KEY_DOWN, ord("j")):
            selected = min(len(items) - 1, selected + 1)
        elif key == curses.KEY_HOME or key == ord("g"):
            selected = 0
        elif key == curses.KEY_END or key == ord("G"):
            selected = len(items) - 1
        elif key in (curses.KEY_ENTER, 10, 13):
            # Hot-swap live
            name = specialisations[selected]
            if name == current:
                show_message(stdscr, f"{name} is already current.\nNo switch needed.")
                continue
            if not confirm(stdscr, f"Hot-swap to {name} now?\n(live switch, no reboot)"):
                continue
            show_message(stdscr, f"Switching live to {name}...\nThis will restart systemd units.", wait=False)
            ok, out = switch_specialisation(name, "switch")
            if ok:
                current = name
                show_message(
                    stdscr,
                    f"Switched to {name} (live).\n{out[:500]}\n\nYou may need to restart Hyprland\n(uwsm stop; uwsm start) or log out/in.",
                )
            else:
                show_message(stdscr, f"Switch to {name} failed:\n{out[:800]}")
        elif key == ord("b"):
            name = specialisations[selected]
            if not confirm(stdscr, f"Set {name} for next boot?\n(requires reboot to apply)"):
                continue
            show_message(stdscr, f"Setting {name} for next boot...", wait=False)
            ok, out = switch_specialisation(name, "boot")
            if ok:
                show_message(
                    stdscr,
                    f"Set {name} for next boot.\n{out[:500]}\n\nReboot to apply (or press B for boot+reboot).",
                )
            else:
                show_message(stdscr, f"Boot set failed:\n{out[:800]}")
        elif key == ord("B"):
            name = specialisations[selected]
            if not confirm(stdscr, f"Set {name} for next boot AND reboot now?"):
                continue
            show_message(stdscr, f"Setting {name} for next boot...", wait=False)
            ok, out = switch_specialisation(name, "boot")
            if not ok:
                show_message(stdscr, f"Boot set failed:\n{out[:800]}")
                continue
            # Now reboot
            show_message(stdscr, f"Set {name} for boot.\nRebooting now...", wait=False)
            # Use sudo reboot if not root
            if os.geteuid() == 0:
                run(["reboot"], timeout=10)
            else:
                run(["sudo", "reboot"], timeout=10)
            show_message(stdscr, "Reboot command sent.\nIf you see this, reboot failed.")
        elif key == ord("r"):
            current = get_current_flavor()
            specialisations = get_specialisations()
            if current in specialisations:
                selected = specialisations.index(current)
            else:
                selected = min(selected, max(0, len(specialisations) - 1))
        elif key == ord("R"):
            # Force re-eval via nix (slow) — refresh from flake
            show_message(stdscr, "Refreshing from flake (nix eval)...", wait=False)
            specialisations = get_specialisations()
            show_message(stdscr, f"Refreshed: {', '.join(specialisations) or 'none'}")
        # Ctrl-d / Ctrl-u for page (like fzf)
        elif key == 4:  # Ctrl-d
            selected = min(len(items) - 1, selected + 5)
        elif key == 21:  # Ctrl-u
            selected = max(0, selected - 5)


if __name__ == "__main__":
    # Handle non-curses invocation: --list, --help, direct switch
    if len(sys.argv) > 1:
        if sys.argv[1] in ("--help", "-h"):
            print(__doc__)
            print("\nUsage:")
            print("  specialisation-picker          # TUI")
            print("  specialisation-picker --list   # list available")
            print("  specialisation-picker --switch <name>  # hot-swap live")
            print("  specialisation-picker --boot <name>    # set for next boot")
            sys.exit(0)
        elif sys.argv[1] == "--list":
            for s in get_specialisations():
                cur = " (current)" if s == get_current_flavor() else ""
                print(s + cur)
            sys.exit(0)
        elif sys.argv[1] in ("--switch", "--boot") and len(sys.argv) > 2:
            mode = "switch" if sys.argv[1] == "--switch" else "boot"
            name = sys.argv[2]
            avail = get_specialisations()
            if name not in avail:
                print(f"Unknown specialisation '{name}'. Available: {', '.join(avail)}", file=sys.stderr)
                sys.exit(1)
            ok, out = switch_specialisation(name, mode)
            print(out)
            sys.exit(0 if ok else 1)
        else:
            print(f"Unknown args: {sys.argv[1:]}", file=sys.stderr)
            print("Try --help", file=sys.stderr)
            sys.exit(1)
    try:
        curses.wrapper(main)
    except KeyboardInterrupt:
        pass
