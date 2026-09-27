#!/usr/bin/env python3
"""Snapshot this machine's Plasma panel + desktop-widget layout into
layout/plasma-appletsrc and layout/plasmashellrc, portable enough for
import-layout.py to replay on a different machine / user.

This is the same "copy the config files" approach tools like konsave use,
rather than rebuilding panels through Plasma's scripting API: the scripting
API can't fully recreate things like the system tray's own internal
containment config or Folder View widget geometry (see README), while the
raw files round-trip exactly. What does NOT round-trip as-is is anything
tied to this one machine, so that gets swapped for placeholders here:

  /home/<you>                      -> __HOME__
  activityId=<uuid> (the desktop)  -> __ACTIVITY__   (every install has its own)
  ItemGeometries-<WxH>             -> ItemGeometries-__RES__ (rescaled on import)
  the wallpaper image              -> __WALLPAPER__

and a few groups get dropped entirely: other wallpaper plugins' leftover
settings (e.g. Wallpaper Engine's Steam workshop paths), config-dialog
window sizes, and screen/connector mappings (connector names differ per
machine - Plasma rebuilds them).

Run from anywhere; re-run and commit whenever the layout changes.
"""
import os
import re
import sys

HOME = os.path.expanduser("~")
CONFIG = os.path.join(HOME, ".config")
OUT_DIR = os.path.dirname(os.path.abspath(__file__))


def read_groups(path):
    """Parse a KConfig file into [(header, [lines])], preserving order."""
    groups, header, lines = [], None, []
    with open(path, encoding="utf-8") as fh:
        for raw in fh:
            line = raw.rstrip("\n")
            if line.startswith("["):
                if header is not None or lines:
                    groups.append((header, lines))
                header, lines = line, []
            elif line.strip():
                lines.append(line)
    groups.append((header, lines))
    return groups


def write_groups(path, groups):
    with open(path, "w", encoding="utf-8") as fh:
        for header, lines in groups:
            if header is None and not lines:
                continue
            if header is not None:
                fh.write(header + "\n")
            for line in lines:
                fh.write(line + "\n")
            fh.write("\n")


def export_appletsrc():
    groups = read_groups(os.path.join(CONFIG, "plasma-org.kde.plasma.desktop-appletsrc"))
    out, source_res = [], None
    for header, lines in groups:
        h = header or ""
        m = re.search(r"\]\[Wallpaper\]\[([^\]]+)\]", h)
        if m and m.group(1) != "org.kde.image":
            continue
        if h.endswith("[ConfigDialog]") or h == "[ScreenMapping]":
            continue
        new = []
        for line in lines:
            key, _, value = line.partition("=")
            if key == "activityId" and value:
                line = "activityId=__ACTIVITY__"
            elif m and key == "Image":
                line = "Image=__WALLPAPER__"
            elif m and key == "SlidePaths":
                line = "SlidePaths=__HOME__/Pictures/wallpapers/"
            elif re.fullmatch(r"ItemGeometries-\d+x\d+", key):
                res = key.split("-", 1)[1]
                if source_res and res != source_res:
                    continue  # geometry left over from an older resolution
                source_res = res
                line = "ItemGeometries-__RES__=" + value
            new.append(line.replace(HOME, "__HOME__"))
        out.append((header, new))
    if source_res:
        out.append(("[PlasmalustExport]", ["sourceResolution=" + source_res]))
    write_groups(os.path.join(OUT_DIR, "plasma-appletsrc"), out)


def export_plasmashellrc():
    groups = read_groups(os.path.join(CONFIG, "plasmashellrc"))
    keep = [(h, [l.replace(HOME, "__HOME__") for l in ls]) for h, ls in groups
            if h and (h.startswith("[PlasmaViews]") or h == "[Updates]")]
    write_groups(os.path.join(OUT_DIR, "plasmashellrc"), keep)


def main():
    export_appletsrc()
    export_plasmashellrc()
    leftover = [f for f in ("plasma-appletsrc", "plasmashellrc")
                if HOME in open(os.path.join(OUT_DIR, f), encoding="utf-8").read()]
    if leftover:
        sys.exit("Error: %s still contains %s" % (leftover, HOME))
    print("Exported layout to", OUT_DIR)


if __name__ == "__main__":
    main()
