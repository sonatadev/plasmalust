#!/usr/bin/env python3
"""Pick the nearest named swatch to a given hex color (simple RGB Euclidean
distance - good enough for choosing among a small fixed palette, not meant
to be perceptually exact). Used to match Papirus folder colors and Bibata
cursor variants to the current wallust accent, since neither supports
arbitrary hex - only a small curated set of pre-built options.

Swatch hex values were pulled directly from the actual source assets
(Papirus: the width=40 height=26 x=4 y=16 front-face rect fill in each
folder-<color>-documents.svg; Bibata: representative color per variant),
not guessed.
"""
import sys

PAPIRUS = {
    "adwaita": "93c0ea", "black": "4f4f4f", "blue": "5294e2",
    "bluegrey": "607d8b", "breeze": "57b8ec", "brown": "ae8e6c",
    "carmine": "a30002", "cyan": "00bcd4", "darkcyan": "45abb7",
    "deeporange": "eb6637", "green": "87b158", "grey": "8e8e8e",
    "indigo": "5c6bc0", "magenta": "ca71df", "nordic": "81a1c1",
    "orange": "ee923a", "palebrown": "d1bfae", "paleorange": "eeca8f",
    "pink": "f06292", "red": "e25252", "teal": "16a085",
    "violet": "7e57c2", "white": "e4e4e4", "yaru": "676767",
    "yellow": "f9bd30",
}

BIBATA = {
    "Classic": "3c3c3c",
    "Ice": "e8e8e8",
    "Amber": "e8a33d",
}

PALETTES = {"papirus": PAPIRUS, "bibata": BIBATA}


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def nearest(hex_color, palette):
    r1, g1, b1 = hex_to_rgb(hex_color)
    best_name, best_dist = None, float("inf")
    for name, swatch in palette.items():
        r2, g2, b2 = hex_to_rgb(swatch)
        dist = (r1 - r2) ** 2 + (g1 - g2) ** 2 + (b1 - b2) ** 2
        if dist < best_dist:
            best_name, best_dist = name, dist
    return best_name


if __name__ == "__main__":
    if len(sys.argv) != 3 or sys.argv[1] not in PALETTES:
        print("usage: nearest-swatch.py <papirus|bibata> <#hexcolor>", file=sys.stderr)
        sys.exit(1)
    print(nearest(sys.argv[2], PALETTES[sys.argv[1]]))
