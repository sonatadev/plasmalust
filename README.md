# plasmalust

Generate a full-system color theme from your current wallpaper, on KDE Plasma.

Run one command and your accent color, window decorations, GTK apps, terminal
(kitty), prompt (starship), system monitor (btop), audio visualizer (cava),
system info (fastfetch), Spotify (via Spicetify), Discord (via Vesktop's
Vencord), vim/neovim, mpv, `bat`, `fzf`, and the Zen browser all repaint to
match whatever wallpaper is currently active — no manual palette picking.
Optional (sudo-gated, not auto-applied) theming for GRUB and the SDDM login
screen is included too — see [System-level extras](#system-level-extras-optional-sudo-required) below.

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
5. It rebuilds `bat`'s theme cache so the new colors actually take effect
   there (bat reads themes from a compiled cache, not the theme file
   directly).
6. It applies the GRUB and SDDM themes too, via `sudo` - see
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
| GRUB (staged only, needs sudo to apply) | `templates/grub-theme.txt` |
| SDDM login screen (staged only, needs sudo to apply) | `templates/sddm-theme.conf` |

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

## System-level extras (optional, sudo required)

GRUB and SDDM theming touch root-owned system paths (`/usr/share/grub/`,
`/usr/share/sddm/`, `/etc/sddm.conf.d/`). `set-theme` applies both
automatically at the end of every run, via `sudo` (one password prompt
covers both - `sudo -v` up front caches it). If sudo is declined or
unavailable, this step is skipped and everything else in the run - the
actual desktop theme - is unaffected; it already finished before this
point.

This assumes the repo lives at `~/Projects/plasmalust` (see the
`PLASMALUST_REPO` line near the bottom of `set-theme`) - adjust that path if
you clone it somewhere else, or delete that whole block if you'd rather keep
GRUB/SDDM as a manual, occasional step instead (see below for running them
by hand).

A broken login screen or boot menu is a worse day than a stale terminal
theme, so both install scripts are conservative: GRUB only changes color
values (never touches `grub-mkconfig` or the boot path) and backs up the
original on first run; SDDM comes with a documented TTY recovery path
(below) if anything looks wrong.

### GRUB

[`grub-theme/install-grub-theme.sh`](./grub-theme/install-grub-theme.sh) copies
the staged, wallust-colored `theme.txt` over Garuda's `catppuccin-mocha` GRUB
theme (only color values change - images/fonts/layout are untouched). It
backs up the original `theme.txt` on first run. No `grub-mkconfig` needed,
since the theme *path* isn't changing, only its contents.

```sh
sudo ./grub-theme/install-grub-theme.sh
```

A GRUB gfxmenu error normally just falls back to GRUB's plain text menu, not
an unbootable system - but if you want to undo it anyway:

```sh
sudo cp /usr/share/grub/themes/catppuccin-mocha/theme.txt.orig \
        /usr/share/grub/themes/catppuccin-mocha/theme.txt
```

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
