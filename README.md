# plasmalust

Generate a full-system color theme from your current wallpaper, on KDE Plasma.

Run one command and your accent color, window decorations, GTK apps, terminal
(kitty), prompt (starship), system monitor (btop), audio visualizer (cava),
system info (fastfetch), Spotify (via Spicetify), Discord (via Vesktop's
Vencord), vim/neovim, mpv, `bat`, `fzf`, and the Zen browser all repaint to
match whatever wallpaper is currently active — no manual palette picking.
GRUB and login-screen theming are included too (sudo-gated, applied
automatically by `set-theme`) — see
[System-level extras](#system-level-extras-optional-sudo-required) below.
The login screen part auto-detects whether your system actually runs SDDM
or KDE's newer `plasmalogin` and themes whichever one is the real active
`display-manager.service` — themeing the wrong one silently does nothing,
which is exactly the mistake this repo made at first (see the SDDM section
below).

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
5. It syncs the wallpaper used by the idle/lock screen (`kscreenlocker`) -
   a separate per-user setting the desktop wallpaper change doesn't touch on
   its own, so it otherwise stays on whatever was last set (often a distro
   default).
6. It rebuilds `bat`'s theme cache so the new colors actually take effect
   there (bat reads themes from a compiled cache, not the theme file
   directly).
7. It applies the GRUB theme and whichever login manager (SDDM or
   plasmalogin) is actually active, via `sudo` - see
   [System-level extras](#system-level-extras-optional-sudo-required)
   below for what that actually does and how to opt out.

Discord (Vesktop/Vencord) picks up the new Quick CSS live, no restart
needed. vim/neovim, mpv, `fzf`, and the Zen browser pick theirs up on next
launch (vim/mpv/fzf) or next browser restart (Zen) — none of these support
true hot-reload the way kitty/Plasma do.

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
| Discord (via Vesktop/Vencord Quick CSS) | `templates/discord-vencord.css` |
| vim / neovim | `templates/vim-colors.vim` |
| mpv (OSD/subtitle colors) | `templates/mpv-colors.conf` |
| `bat` | `templates/bat-wallust.tmTheme` |
| `fzf` | `templates/fzf-colors.sh` |
| `eza` | `templates/eza-colors.sh` |
| Zen browser (userChrome.css) | `templates/zen-userchrome.css` |
| Android Studio editor (syntax highlighting) | `templates/android-studio.icls` |
| Android Studio UI (sidebar/toolbar/panels) | `templates/android-studio.theme.json` + `android-studio-theme/` |
| GRUB (needs sudo to apply) | `templates/grub-theme.txt` |
| SDDM login screen, if active (needs sudo to apply) | `templates/sddm-theme.conf` |
| plasmalogin login screen, if active (needs sudo to apply) | see `plasmalogin/install-plasmalogin.sh` |

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
- Optional: GTK3/4, starship, btop, cava, conky, fastfetch, [Spicetify](https://spicetify.app/),
  Vesktop, vim/neovim, mpv, `bat`, `fzf`, Zen browser — only themed if installed/present

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

### Per-app notes

- **vim/neovim**: copy `dotfiles/vimrc` to `~/.vimrc` and/or `dotfiles/nvim-init.vim`
  to `~/.config/nvim/init.vim`. Both just source the generated
  `~/.cache/wallust/wallust.vim`.
- **mpv**: add the line from `dotfiles/mpv-conf-snippet.conf` to your
  `mpv.conf` (this repo doesn't ship your whole `mpv.conf`, just that one
  include line).
- **`fzf`** / **`eza`**: add the two lines from `dotfiles/bashrc-fzf-eza-snippet.sh`
  to your `.bashrc`/`.zshrc`.
- **`bat`**: copy `dotfiles/bat-config` to `~/.config/bat/config` (or just add
  `--theme="Wallust"` to your existing one). `set-theme` calls
  `bat cache --build` automatically after every run.
- **Discord (Vesktop)**: nothing to configure — Vesktop already ships with
  Quick CSS enabled (`useQuickCss: true` in its settings), and the generated
  CSS is written straight to `~/.config/vesktop/settings/quickCss.css`.
- **Zen browser**: copy `dotfiles/zen-user.js` to your Zen profile directory
  (find it via `about:profiles` in Zen, or `~/.config/zen/profiles.ini`) as
  `user.js`. This flips `toolkit.legacyUserProfileCustomizations.stylesheets`
  so `chrome/userChrome.css` gets loaded. Requires a browser restart to pick
  up new colors — Firefox-family browsers only read `userChrome.css` at
  startup.
- **Android Studio**: the `wallust.toml` target paths (and the two
  `ANDROID_STUDIO_*` variables near the bottom of `set-theme`) have your
  Android Studio version baked in (e.g. `AndroidStudio2026.1.3`) since
  JetBrains versions its config/plugin directories - adjust them to match
  `~/.config/Google/` and `~/.local/share/Google/` on your machine, and
  bump them after upgrading to a new major version. Two independent pieces:

  1. **Editor color scheme** (syntax highlighting) - `templates/android-studio.icls`,
     inherits from Darcula. Some wallpapers produce a narrow-range palette
     where color1-color6 all cluster in similar muted tones (confirmed with
     a forest-green wallpaper) - rather than assigning each syntax category
     its own hue and risking illegible, same-toned code, this leans on
     `{{foreground}}` (wallust's own contrast-guaranteed color) for most
     text, with a single accent color for strings/numbers/classes and bold
     weight to distinguish keywords instead of relying on hue variety that
     may not exist. `set-theme` also flips `options/colors.scheme.xml`
     (JetBrains' own XML format, not a KDE ini file - hence a targeted
     `sed`, not `kwriteconfig6`) to actually select it.

  2. **UI theme** (sidebar/toolbar/panels/status bar - the rest of the IDE
     chrome, which the editor scheme above doesn't touch) -
     `templates/android-studio.theme.json` +
     [`android-studio-theme/plugin-src/`](./android-studio-theme/plugin-src/).
     JetBrains requires UI themes be packaged as a real installed plugin
     (a JAR with `META-INF/plugin.xml` inside - confirmed against
     [JetBrains' own theme_basics sample](https://github.com/JetBrains/intellij-sdk-code-samples/tree/main/theme_basics)
     and the on-disk layout of an already-installed plugin on this machine),
     not something you can just drop as a loose file. `set-theme` rebuilds
     the JAR fresh every run (static `plugin.xml` + freshly-generated
     `theme.json`) and drops it straight into the installed-plugins
     location - IntelliJ-platform IDEs discover plugins by scanning that
     directory at startup, the same mechanism as installing one normally
     through the Plugins UI, so no manual reinstall step is needed after
     the first run.

  Both need an Android Studio restart to pick up new colors, like other
  apps here that don't hot-reload.
- **Idle/lock screen (`kscreenlocker`)**: wallpaper is synced automatically
  (see above), and it picks up real colors via `Kirigami.Theme.colorSet:
  Complementary`, which the KDE color scheme template also fills in - so
  it's already more than a stock default. Full custom layout the way SDDM
  got one isn't realistic here though: `kscreenlocker`'s lock screen is
  `org.kde.plasma.desktop`'s actual shell component, built on private
  Plasma APIs (session management, real PAM authentication, virtual
  keyboard) across several linked QML files - not a small standalone
  swappable theme. Reimplementing that carries real risk (a broken lock
  screen strands an already-unlocked session, worse than a broken login
  prompt), so this repo only does the safe color/wallpaper-level sync, not
  a layout rebuild.

## Panel layout (optional, one-time)

`panel-layout/apply-panel-layout.sh` does a one-time cleanup of the top
panel: swaps Kickoff's Garuda cat logo for a wallust-recolored Arch logo
(the recoloring itself is dynamic, handled every run by `set-theme`'s
`# 2d.` step - this script just wires up the icon path), turns off the user
switcher's fixed-color account avatar in favor of a plain themeable icon,
and hides the microphone privacy indicator + Garuda System Maintenance
tray icons (both are fixed-asset icons from their own processes, not real
systray plasmoids - not resizable/recolorable, so hidden rather than left
visually inconsistent). Also turns on Plasma's native floating-panel mode
for the top panel (rounded corners, edge gap, drop shadow) - a live
Containment property rather than a config file key, confirmed to persist
across `plasmashell` restarts despite not showing up in any config file.

Run once:

```
./panel-layout/apply-panel-layout.sh
```

## Desktop widgets (optional)

`plasma-widgets/` has five ornate-framed Plasma desktop widgets, styled to
match a Hyprland/conky-rice aesthetic, colors bound live to `Kirigami.Theme`
so they re-theme automatically on every `set-theme` run - no separate
wallust template needed:

- **Plasmalust Sysinfo** - OS/kernel/WM/shell/uptime + CPU/mem/disk/battery
  meters (`fastfetch --format json`), plus a wallust-duotone dithered
  portrait of the current wallpaper (ordered-dither halftone, generated by
  `set-theme` itself - see the `# 2b.` step in `set-theme`).
- **Plasmalust Media** - MPRIS now-playing panel via `playerctl` (art,
  title/artist/album, progress, prev/play-pause/next).
- **Plasmalust Visualizer** - live audio bars via `cava`. Needs the bridge
  service below.
- **Plasmalust Processes** - top processes by CPU (`ps`).
- **Plasmalust Wallpaper Picker** - searchable thumbnail grid of
  `~/Pictures/wallpapers/`; clicking one sets it and re-runs the full
  `set-theme` pipeline (`scripts/plasmalust-set-wallpaper`). Thumbnails are
  cached and kept in sync automatically (`scripts/plasmalust-refresh-thumbnails`,
  called incrementally at the end of every `set-theme` run).

Install/upgrade all five, plus the visualizer's cava bridge service and the
wallpaper picker's helper scripts:

```
./plasma-widgets/install-widgets.sh
```

Then add them from the desktop: right-click → **Add Widgets** → search
"Plasmalust" → drag onto the desktop.

The visualizer needs a small always-on bridge: cava's `raw` output method
requires an active reader on its FIFO or it blocks, so
`plasmalust-cava-bridge.service` (a `systemd --user` unit, enabled by the
install script) drains that FIFO continuously into a plain file the widget
polls, decoupling cava from the widget's own poll timer.

Note: on a desktop using the **Folder View** containment, widget position
and size aren't stored in `plasma-org.kde.plasma.desktop-appletsrc`'s
per-applet config the way you'd expect, and setting `.geometry` through
Plasma's scripting API on a freshly-added widget silently doesn't stick.
Folder View keeps its own `ItemGeometries-<WxH>` key (screen resolution as
seen at your global scale factor) in the containment's own config block:
`Applet-<id>:x,y,width,height,0;` per widget. Dragging a widget to resize it
by hand in the UI works fine - this only matters if you're scripting
placement.

## Toybox (optional)

`toybox/plasmalust-toybox` is a themed `fzf` picker for a handful of fun
terminal toys (`fastfetch`, `hyfetch`, `unimatrix`, `aafire`,
`asciiquarium`, `peaclock`, `mapscii`, `btop`, `cava`, plus a `figlet`
banner prompt) - the same idea as the little "exit/kill/st/..." corner
menus seen in a lot of Hyprland/conky rices. It rides on `fzf`'s existing
wallust theming (`~/.cache/wallust/fzf.sh`), so no separate template is
needed. Install the packages it wraps, symlink or copy the script to
`~/.local/bin/plasmalust-toybox`, alias `toybox` to it if you want.

## Icons + cursor theme (optional)

Neither icon nor cursor themes take arbitrary hex - each ships a small
curated set of pre-built variants - so `icons-cursors/nearest-swatch.py`
picks whichever variant is closest (plain RGB distance) to the current
wallust accent, from swatches pulled directly from the real source assets
(not guessed):

- **Icons**: [Papirus-Dark](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme),
  folder color recolored via `papirus-folders` (24 named colors).
- **Cursor**: [Bibata-Modern](https://aur.archlinux.org/packages/bibata-cursor-theme)
  - Classic (dark), Ice (light), or Amber, picked to match.

Install once:

```
./icons-cursors/install-icons-cursors.sh
```

`set-theme` picks up from there automatically - the icon/cursor theme
*selection* (step 2c) needs no sudo, only the actual Papirus folder
recoloring does (folded into the same sudo-gated block as GRUB/login-manager
below, since it touches Papirus's system-owned directory). Both stay
inert no-ops until the install script has been run once.

## System-level extras (optional, sudo required)

GRUB and login-screen theming touch root-owned system paths. `set-theme`
applies both automatically at the end of every run, via `sudo` (one
password prompt covers both - `sudo -v` up front caches it). If sudo is
declined or unavailable, this step is skipped and everything else in the
run - the actual desktop theme - is unaffected; it already finished before
this point.

This assumes the repo lives at `~/Projects/plasmalust` (see the
`PLASMALUST_REPO` line near the bottom of `set-theme`) - adjust that path if
you clone it somewhere else, or delete that whole block if you'd rather keep
these as a manual, occasional step instead (see below for running them by
hand).

A broken login screen or boot menu is a worse day than a stale terminal
theme, so every install script here is conservative: GRUB only changes
color values (never touches `grub-mkconfig` or the boot path) and backs up
the original on first run.

### Which login manager?

**Check which one is actually running before assuming anything** -
`systemctl status sddm` showing `disabled`/`inactive` while a theme still
doesn't seem to apply is a strong sign you're theming the wrong one. Find
the real active one with:

```sh
basename "$(readlink -f /etc/systemd/system/display-manager.service)" .service
```

`set-theme` runs this same check itself and calls the matching install
script below - you shouldn't normally need to run either manually unless
you're testing.

### GRUB

[`grub-theme/install-grub-theme.sh`](./grub-theme/install-grub-theme.sh) copies
the staged, wallust-colored `theme.txt` over Garuda's `catppuccin-mocha` GRUB
theme (only color values change - images/fonts/layout are untouched). It
backs up the original `theme.txt` on first run. No `grub-mkconfig` needed,
since the theme *path* isn't changing, only its contents.

```sh
sudo ./grub-theme/install-grub-theme.sh
```

Note: `desktop-image` is deliberately not set in the template. GRUB draws
that image *over* `desktop-color` - if an image is set, the color is only
ever a fallback for when the image fails to load, so it's invisible
regardless of its value. The theme's original static background picture
never gets touched or regenerated; dropping the image line is what actually
makes `desktop-color` (the real wallust palette) the visible background.

A GRUB gfxmenu error normally just falls back to GRUB's plain text menu, not
an unbootable system - but if you want to undo it anyway:

```sh
sudo cp /usr/share/grub/themes/catppuccin-mocha/theme.txt.orig \
        /usr/share/grub/themes/catppuccin-mocha/theme.txt
```

### plasmalogin login screen

KDE's newer native greeter, used instead of SDDM on some current Plasma
setups (this repo's own dev machine included). It runs as its own
restricted system user (`plasmalogin`, home `/var/lib/plasmalogin`) with a
config entirely separate from your own `~/.config` - your desktop's color
scheme doesn't reach it on its own.

[`plasmalogin/install-plasmalogin.sh`](./plasmalogin/install-plasmalogin.sh)
copies the current wallpaper and the most recently generated
`Wallust-*.colors` scheme into plasmalogin's own home, and points its own
`kdeglobals` at that scheme:

```sh
sudo ./plasmalogin/install-plasmalogin.sh
```

Takes effect on next logout (no reboot needed - just log out and look at
the greeter). No live preview mode exists for this one; if something looks
wrong, `/etc/plasmalogin.conf` and `/var/lib/plasmalogin/.config/kdeglobals`
are both plain text and safe to hand-edit or revert.

### SDDM login screen

[`sddm-theme/`](./sddm-theme/) is a minimal, dependency-free (plain
QtQuick/QtQuick.Controls, no Plasma/Kirigami coupling) SDDM greeter theme
that reads its colors from the wallust-generated `theme.conf`.

**Test it first without touching your real login screen at all:**

```sh
./sddm-theme/preview-sddm.sh
```

This stages the currently-generated `theme.conf` and wallpaper into
`sddm-theme/` (both gitignored - not committed) and opens the greeter in an
ordinary window via SDDM's `--test-mode`, with your actual wallust colors
and background. Your session keeps running, nothing system-wide changes.

Running SDDM's test-mode directly (`sddm-greeter-qt6 --test-mode --theme
sddm-theme/`, or just `sddm-greeter` on older builds) works too, but without
`theme.conf`/`background.png` present it silently falls back to the
hardcoded defaults in `Main.qml` - flat near-black, no image - which looks
like a theme bug but isn't; it's just an incomplete preview.

Only once you're happy with what `preview-sddm.sh` showed you, install it
for real:

```sh
sudo ./sddm-theme/install-sddm.sh
```

This is a one-shot snapshot of whatever colors were staged at the time -
SDDM runs as its own restricted system user and can't read your `~/.cache`,
so the login screen doesn't update live the way your terminal does. Re-run
the install script (with sudo) whenever you want to resync it after a
wallpaper change.

**Recovery**, if anything looks wrong after installing: switch to a TTY with
`Ctrl+Alt+F3` (or F2/F4), log in there, and run:

```sh
sudo rm /etc/sddm.conf.d/plasmalust.conf
sudo systemctl restart sddm
```

to instantly fall back to the default theme.

## License

MIT
