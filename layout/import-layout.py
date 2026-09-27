#!/usr/bin/env python3
"""Replay the panel + desktop-widget layout exported by export-layout.py
onto this machine. Must run inside the Plasma session (needs D-Bus to
restart plasmashell and to look up the current activity/screen).

Usage: import-layout.py WALLPAPER_IMAGE

Backs up the current layout files to ~/.config/plasmalust-backup-<time>/
first - copy them back (with plasmashell stopped) to undo.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
CONFIG = os.path.join(HOME, ".config")
SRC_DIR = os.path.dirname(os.path.abspath(__file__))
APPLETSRC = os.path.join(CONFIG, "plasma-org.kde.plasma.desktop-appletsrc")
SHELLRC = os.path.join(CONFIG, "plasmashellrc")


def run(*cmd):
    return subprocess.run(cmd, capture_output=True, text=True).stdout.strip()


def current_activity():
    act = run("qdbus6", "org.kde.ActivityManager", "/ActivityManager/Activities", "CurrentActivity")
    if re.fullmatch(r"[0-9a-f-]{36}", act):
        return act
    # Fall back to whatever activity the existing desktop containment uses.
    if os.path.exists(APPLETSRC):
        m = re.search(r"^activityId=([0-9a-f-]{36})$", open(APPLETSRC, encoding="utf-8").read(), re.M)
        if m:
            return m.group(1)
    sys.exit("Error: could not determine the current Plasma activity id")


def logical_resolution():
    """Primary screen size in logical pixels (what Folder View keys on)."""
    try:
        outputs = json.loads(run("kscreen-doctor", "-j")).get("outputs", [])
    except ValueError:
        outputs = []
    enabled = [o for o in outputs if o.get("enabled")]
    if not enabled:
        return None
    out = min(enabled, key=lambda o: o.get("priority", 99))
    mode = next((m for m in out.get("modes", []) if m.get("id") == out.get("currentModeId")), None)
    size = (mode or {}).get("size") or out.get("size")
    if not size:
        return None
    w, h = size["width"], size["height"]
    if out.get("rotation") in (2, 8):  # left/right = portrait
        w, h = h, w
    scale = out.get("scale") or 1
    return round(w / scale), round(h / scale)


def rescale_geometry(value, src, dst):
    """Applet-N:x,y,w,h,0;... fitted onto a screen of a different size
    and/or aspect ratio.

    One uniform factor for both axes (the tighter of the two), with the
    whole arrangement then centered - scaling x and y independently would
    squash columns into each other going e.g. 16:10 -> 16:9. Sizes only
    ever shrink (on a smaller screen); on a bigger one widgets keep their
    designed size and just spread out. Snapped to Folder View's 16px grid
    (the source layout already sits on it)."""
    sw, sh = src
    dw, dh = dst
    s = min(dw / sw, dh / sh)
    size_s = min(s, 1.0)
    off_x = (dw - sw * s) / 2
    off_y = (dh - sh * s) / 2

    def snap(v):
        return int(round(v / 16.0)) * 16

    items = []
    for item in filter(None, value.split(";")):
        name, _, geo = item.partition(":")
        x, y, w, h, rot = (int(float(v)) for v in geo.split(","))
        w, h = snap(w * size_s), snap(h * size_s)
        x = max(0, min(snap(x * s + off_x), dw - w))
        y = max(0, min(snap(y * s + off_y), dh - h))
        items.append("%s:%d,%d,%d,%d,%d" % (name, x, y, w, h, rot))
    return ";".join(items) + ";"


def installed_launchers(value):
    """Task manager pinned launchers, minus apps this machine doesn't have
    (they'd show up as a "?" icon in the dock)."""
    dirs = [os.path.join(HOME, ".local/share")] + \
        os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
    keep = []
    for entry in filter(None, value.split(",")):
        if entry.startswith("applications:"):
            name = entry.split(":", 1)[1]
            if not any(os.path.exists(os.path.join(d, "applications", name)) for d in dirs):
                continue
        keep.append(entry)
    return ",".join(keep)


def main():
    if len(sys.argv) != 2 or not os.path.isfile(sys.argv[1]):
        sys.exit("Usage: import-layout.py WALLPAPER_IMAGE")
    wallpaper = os.path.abspath(sys.argv[1])

    text = open(os.path.join(SRC_DIR, "plasma-appletsrc"), encoding="utf-8").read()
    m = re.search(r"^\[PlasmalustExport\]\nsourceResolution=(\d+)x(\d+)\n*", text, re.M)
    src_res = (int(m.group(1)), int(m.group(2))) if m else None
    text = text[:m.start()] if m else text

    dst_res = logical_resolution() or src_res
    text = (text.replace("__HOME__", HOME)
                .replace("__ACTIVITY__", current_activity())
                .replace("__WALLPAPER__", "file://" + wallpaper))
    if src_res and dst_res:
        def fix(match):
            return "%s=%s" % (match.group(1), rescale_geometry(match.group(2), src_res, dst_res))
        text = re.sub(r"^(ItemGeometries(?:-__RES__|Horizontal))=(.*)$", fix, text, flags=re.M)
        text = text.replace("ItemGeometries-__RES__", "ItemGeometries-%dx%d" % dst_res)

    text = re.sub(r"^launchers=(.*)$", lambda lm: "launchers=" + installed_launchers(lm.group(1)),
                  text, flags=re.M)

    shellrc = open(os.path.join(SRC_DIR, "plasmashellrc"), encoding="utf-8").read().replace("__HOME__", HOME)

    backup = os.path.join(CONFIG, time.strftime("plasmalust-backup-%Y%m%d-%H%M%S"))
    os.makedirs(backup)

    # plasmashell rewrites both files on exit, so it has to be fully down
    # before they're replaced or it would clobber the new layout.
    subprocess.run(["kquitapp6", "plasmashell"], capture_output=True)
    for _ in range(40):
        if subprocess.run(["pgrep", "-x", "plasmashell"], capture_output=True).returncode != 0:
            break
        time.sleep(0.25)
    else:
        subprocess.run(["pkill", "-x", "plasmashell"])
        time.sleep(1)

    for path in (APPLETSRC, SHELLRC):
        if os.path.exists(path):
            shutil.copy2(path, backup)
    with open(APPLETSRC, "w", encoding="utf-8") as fh:
        fh.write(text)
    with open(SHELLRC, "w", encoding="utf-8") as fh:
        fh.write(shellrc)

    subprocess.Popen(["kstart", "plasmashell"], stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True)
    print("Layout imported (screen %s). Previous layout backed up to %s" %
          ("%dx%d" % dst_res if dst_res else "unknown", backup))


if __name__ == "__main__":
    main()
