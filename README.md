# plasmalust

Generate a full-system color theme from your current wallpaper, on KDE Plasma.

Run one command and your accent color, window decorations, GTK apps, terminal
(kitty), prompt (starship), system monitor (btop), audio visualizer (cava),
system info (fastfetch), and Spotify (via Spicetify) all repaint to match
whatever wallpaper is currently active — no manual palette picking.

## How it works

1. **[`set-theme`](./set-theme)** finds your active Plasma wallpaper by reading
   it straight out of `plasma-org.kde.plasma.desktop-appletsrc`.
2. It runs [`wallust`](https://codeberg.org/explosion-mental/wallust) against
   that image to extract a palette and render it into every template listed
   in [`wallust.toml`](./wallust.toml).
3. It applies the generated KDE color scheme system-wide, working around a
   few Plasma quirks along the way (see below).
4. It pushes the new colors live into every open terminal, restarts
   `plasmashell` for a clean redraw, and — if Spotify is running — rebuilds
   and reloads the Spicetify theme too.

## What it themes

| Target | Template |
|---|---|
| KDE color scheme (Plasma, Qt/KDE apps, Dolphin, System Settings) | `templates/Wallust.colors` |
| kitty terminal | `templates/colors-kitty.conf` |
| GTK3 apps | `templates/gtk3-colors.css` |
| GTK4 apps | `templates/gtk4-colors.css` |
| starship prompt | `templates/starship.toml` |
| btop | `templates/btop-wallust.theme` |
| cava | `templates/cava-config` |
| conky | `templates/conky-mocha.conf` |
| fastfetch | `templates/fastfetch.jsonc` |
| Spotify (via Spicetify) | `templates/spicetify-user.css` → derived `color.ini` |

## KDE quirks it works around

Getting Plasma to *actually* pick up new colors on every run, not just the
first one, turned out to be the hard part:

- **Plasma fights back on accent color.** If "accent color from wallpaper" is
  left on, Plasma keeps regenerating its own accent and overwriting wallust's.
  The script turns that setting off, then derives the accent color itself
  from the same color wallust picked for GTK (`color5`), so Plasma's accent
  still matches the rest of the theme.
- **Stale `Colors:*` overrides in `kdeglobals`.** Plasma's accent-color writer
  (or a previous run) can leave literal `[Colors:Button]`, `[Colors:View]`,
  etc. blocks in `kdeglobals`. These shadow the active color scheme file for
  any app that reads `kdeglobals` directly, freezing them on old colors even
  after the scheme changes. The script strips those blocks on every run.
- **`plasma-apply-colorscheme` no-ops on a repeat name.** It only checks the
  scheme *name*, not its contents — so if every generated scheme is named
  `Wallust`, only the first run ever actually applies. The script applies
  each run under a fresh timestamped scheme name, then prunes the old ones.

## Requirements

- KDE Plasma (uses `kwriteconfig6`, `plasma-apply-colorscheme`, `kquitapp6`/`kstart`)
- [`wallust`](https://codeberg.org/explosion-mental/wallust)
- kitty (for the live terminal color push and accent-color derivation)
- Optional: GTK3/4, starship, btop, cava, conky, fastfetch, [Spicetify](https://spicetify.app/) — only themed if installed/present

## Setup

1. Copy `wallust.toml` and `templates/` to `~/.config/wallust/`, editing the
   `target` paths to match your username and which of the optional templates
   you actually want.
2. Copy `set-theme` somewhere on your `$PATH`, e.g. `~/.local/bin/set-theme`,
   and make it executable.
3. Run it:

   ```sh
   set-theme
   ```

Re-run it any time you change your wallpaper.

## License

MIT
