#!/bin/bash
# plasmalust installer - turns a fresh Garuda Linux KDE (Mokka) install
# into the full plasmalust setup in one go:
#
#   packages   install everything the scripts/widgets/templates use
#   remove     remove stock Garuda packages that conflict with it
#   shell      make bash the login shell (the dotfiles are bash)
#   wallust    generate ~/.config/wallust/ for this user
#   dotfiles   kitty, bash, vim/nvim, bat, mpv configs
#   bin        link set-theme + helper scripts into ~/.local/bin
#   wallpapers make sure ~/Pictures/wallpapers has something in it
#   kde        fonts, decorations, KWin effects/tiling (layout/kde-settings.sh)
#   polish     Kvantum, KWin scripts, kitty/yazi defaults (system-polish/)
#   widgets    the plasmalust desktop widgets + cava bridge
#   theme      first set-theme run
#   layout     panels + desktop widget arrangement (layout/import-layout.py)
#   system     GRUB, login screen and splash theming (sudo)
#
# Usage: ./install.sh [options]
#   -y, --yes             don't ask for confirmation (pacman still shows output)
#   -n, --dry-run         only show what would happen, change nothing
#       --only STEPS      comma-separated subset of the steps above
#       --skip STEPS      comma-separated steps to leave out
#       --icons           also install Papirus icons + Bibata cursors
#                         (recolored to the accent by set-theme)
#       --wallpapers DIR  copy the images in DIR into ~/Pictures/wallpapers
#
# Safe to re-run: every step checks before it changes anything, and files
# it replaces are backed up to ~/.config/plasmalust-backup-<time>/.
set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
ALL_STEPS="packages remove shell wallust dotfiles bin wallpapers kde polish widgets theme layout system"
BACKUP_DIR="$HOME/.config/plasmalust-backup-$(date +%Y%m%d-%H%M%S)"

ASSUME_YES=0
DRY_RUN=0
WITH_ICONS=0
WALLPAPER_SRC=""
ONLY=""
SKIP=""

# Everything the setup uses. Grouped only for readability - all installed.
PKGS_CORE=(
    git python curl imagemagick
    wallust-git            # palette extraction + templating (chaotic-aur)
    kitty                  # terminal; its theme file is also where set-theme reads the accent
    qt6-declarative        # qml6, runs the menu/wallpaper overlays
    kvantum                # Qt widget style (KvArcDark shapes -> Plasmalust theme)
    kwin-effect-rounded-corners-git
    kwin-scripts-krohnkite-git
    plasma6-applets-panel-colorizer
    kdeconnect             # tray widget in the imported panel layout
    inter-font ttf-jetbrains-mono-nerd
)
PKGS_CLI=(
    starship fastfetch btop cava bat fzf eza yazi ueberzugpp
    playerctl mpv vim blesh
)
PKGS_TOYS=(
    hyfetch aalib asciiquarium figlet astroterm pastel npm
)
# Not in any binary repo - built from the AUR with paru (ships with Garuda).
PKGS_AUR=(cbonsai peaclock unimatrix-git)
PKGS_ICONS=(papirus-icon-theme papirus-folders bibata-cursor-theme)

# Stock Garuda packages that fight this setup:
#   konsole, alacritty  replaced by kitty (Meta+T, default terminal)
#   kwin-polonium       second tiling script, fights krohnkite over windows
#   blesh-git           conflicts with the stable blesh used here
PKGS_REMOVE=(konsole alacritty kwin-polonium blesh-git)

# --- helpers ------------------------------------------------------------

if [ -t 1 ]; then
    C_STEP=$'\e[1;35m' C_OK=$'\e[32m' C_WARN=$'\e[33m' C_ERR=$'\e[31m' C_DIM=$'\e[2m' C_OFF=$'\e[0m'
else
    C_STEP="" C_OK="" C_WARN="" C_ERR="" C_DIM="" C_OFF=""
fi
step() { printf '\n%s==> %s%s\n' "$C_STEP" "$*" "$C_OFF"; }
info() { printf '  %s\n' "$*"; }
ok()   { printf '  %s✓%s %s\n' "$C_OK" "$C_OFF" "$*"; }
warn() { printf '  %s!%s %s\n' "$C_WARN" "$C_OFF" "$*" >&2; }
die()  { printf '%sError:%s %s\n' "$C_ERR" "$C_OFF" "$*" >&2; exit 1; }

# Runs a command, or just prints it in --dry-run mode.
run() {
    if [ "$DRY_RUN" = 1 ]; then
        printf '  %s[dry-run]%s %s\n' "$C_DIM" "$C_OFF" "$*"
    else
        "$@"
    fi
}

confirm() {
    [ "$ASSUME_YES" = 1 ] && return 0
    [ "$DRY_RUN" = 1 ] && return 0
    local reply
    read -rp "  $1 [Y/n] " reply
    [[ -z "$reply" || "$reply" =~ ^[YySs] ]]
}

want() {
    local s="$1"
    if [ -n "$ONLY" ] && [[ ",$ONLY," != *",$s,"* ]]; then return 1; fi
    if [[ ",$SKIP," == *",$s,"* ]]; then return 1; fi
    return 0
}

# Moves an existing file/dir aside into the backup dir before replacing it.
backup() {
    local path="$1"
    [ -e "$path" ] || [ -L "$path" ] || return 0
    local rel="${path#"$HOME"/}"
    run mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    run mv "$path" "$BACKUP_DIR/$rel"
    info "backed up $rel"
}

# Installs SRC at DEST (copy) unless DEST already has identical content.
put_file() {
    local src="$1" dest="$2"
    if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
        return 0
    fi
    backup "$dest"
    run mkdir -p "$(dirname "$dest")"
    run cp "$src" "$dest"
    ok "wrote ${dest/#$HOME/\~}"
}

# Symlinks DEST -> SRC unless it already points there.
put_link() {
    local src="$1" dest="$2"
    if [ "$(readlink -f "$dest" 2>/dev/null)" = "$(readlink -f "$src")" ]; then
        return 0
    fi
    backup "$dest"
    run mkdir -p "$(dirname "$dest")"
    run ln -s "$src" "$dest"
    ok "linked ${dest/#$HOME/\~} -> ${src/#$HOME/\~}"
}

# Replaces (or appends) the block between "# >>> plasmalust >>>" markers.
put_block() {
    local file="$1" content="$2" comment="${3:-#}"
    local begin="$comment >>> plasmalust >>>" end="$comment <<< plasmalust <<<"
    local tmp
    tmp=$(mktemp)
    if [ -f "$file" ]; then
        awk -v b="$begin" -v e="$end" '$0==b{skip=1; next} $0==e{skip=0; next} !skip' "$file" > "$tmp"
    fi
    # drop trailing blank lines left behind by a removed block
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$tmp"
    { [ -s "$tmp" ] && echo; echo "$begin"; printf '%s\n' "$content"; echo "$end"; } >> "$tmp"
    if [ -f "$file" ] && cmp -s "$tmp" "$file"; then
        rm -f "$tmp"
        return 0
    fi
    [ -f "$file" ] && { run mkdir -p "$BACKUP_DIR"; run cp "$file" "$BACKUP_DIR/$(basename "$file")"; }
    run mkdir -p "$(dirname "$file")"
    run cp "$tmp" "$file"
    rm -f "$tmp"
    ok "updated plasmalust block in ${file/#$HOME/\~}"
}

in_plasma_session() {
    [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] && pgrep -u "$USER" -x plasmashell >/dev/null
}

# Picks the image set-theme/import-layout should start from: whatever Plasma
# has set now if it's a real file, else the first image in ~/Pictures/wallpapers.
pick_wallpaper() {
    local current
    current=$(awk -F= '/^\[/{g=($0 ~ /\]\[Wallpaper\]\[org\.kde\.image\]\[General\]$/)} g && /^Image=/{v=substr($0,7)} END{print v}' \
              "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" 2>/dev/null)
    current="${current#file://}"
    if [ -f "$current" ]; then
        printf '%s\n' "$current"
        return
    fi
    find "$HOME/Pictures/wallpapers" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort | head -n 1 || true
}

# --- steps --------------------------------------------------------------

preflight() {
    step "Checking the system"
    [ "$(id -u)" -ne 0 ] || die "run this as your normal user, not root (it uses sudo where needed)."
    command -v pacman >/dev/null || die "pacman not found - this needs an Arch-based system (Garuda Linux)."
    command -v plasmashell >/dev/null || die "KDE Plasma not found - install Garuda's KDE edition."
    command -v kwriteconfig6 >/dev/null || die "kwriteconfig6 not found - this needs Plasma 6."
    grep -q '^\[chaotic-aur\]' /etc/pacman.conf ||
        die "the chaotic-aur repo isn't enabled (Garuda has it by default) - several packages come from it."
    ok "Arch/Garuda with Plasma $(pacman -Q plasma-workspace 2>/dev/null | awk '{print $2}')"

    if pacman -Q garuda-mokka >/dev/null 2>&1; then
        ok "Garuda Mokka theme package present"
    else
        warn "garuda-mokka isn't installed - GRUB theming needs its catppuccin-mocha theme; the 'system' step will be skipped."
    fi

    if in_plasma_session; then
        ok "running inside a Plasma session"
    elif [ "$DRY_RUN" = 1 ]; then
        warn "not inside a Plasma session - fine for a dry run, required for a real one"
    elif want theme || want layout || want widgets || want polish || want kde; then
        die "run this from a terminal inside your Plasma desktop session (the theme/layout steps need it), or use --skip theme,layout,widgets,polish,kde."
    fi

    if [ "$DRY_RUN" = 0 ] && { want packages || want remove || want shell || want system; }; then
        info "sudo is needed for packages and GRUB/login screen:"
        sudo -n true 2>/dev/null || sudo -v || die "sudo failed."
        # keep the sudo timestamp fresh for the rest of the run
        while kill -0 $$ 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done &
        SUDO_KEEPALIVE=$!
        trap 'kill $SUDO_KEEPALIVE 2>/dev/null || true' EXIT
    fi
}

step_packages() {
    step "Packages"
    local wanted=("${PKGS_CORE[@]}" "${PKGS_CLI[@]}" "${PKGS_TOYS[@]}")
    [ "$WITH_ICONS" = 1 ] && wanted+=("${PKGS_ICONS[@]}")

    # "wallust" already satisfied by the plain package counts too.
    local missing=() p
    for p in "${wanted[@]}"; do
        case "$p" in
            wallust-git) pacman -T wallust >/dev/null || missing+=("$p") ;;
            *) pacman -T "$p" >/dev/null || missing+=("$p") ;;
        esac
    done
    if [ "${#missing[@]}" -eq 0 ]; then
        ok "everything already installed"
    else
        info "to install (${#missing[@]}): ${missing[*]}"
        # -Syu, not -Sy: syncing the database without upgrading is a partial
        # upgrade, which Arch doesn't support and which breaks things.
        confirm "Install these (with a full system upgrade)?" || die "cancelled."
        local noconfirm=()
        [ "$ASSUME_YES" = 1 ] && noconfirm=(--noconfirm)
        run sudo pacman -Syu --needed "${noconfirm[@]}" "${missing[@]}"
    fi

    local aur_missing=()
    for p in "${PKGS_AUR[@]}"; do
        pacman -T "$p" >/dev/null || aur_missing+=("$p")
    done
    if [ "${#aur_missing[@]}" -gt 0 ]; then
        if command -v paru >/dev/null; then
            info "to build from the AUR: ${aur_missing[*]}"
            local aur_flags=(--needed)
            [ "$ASSUME_YES" = 1 ] && aur_flags+=(--noconfirm --skipreview)
            run paru -S "${aur_flags[@]}" "${aur_missing[@]}" ||
                warn "AUR build failed for some of: ${aur_missing[*]} (only toybox toys - everything else still works)"
        else
            warn "paru not found - skipping AUR toys: ${aur_missing[*]}"
        fi
    fi

    # mapscii (a toybox toy) only exists on npm.
    if command -v npm >/dev/null && [ ! -e "$HOME/.local/bin/mapscii" ]; then
        run npm install -g --prefix "$HOME/.local" mapscii >/dev/null && ok "installed mapscii (npm)"
    fi
}

step_remove() {
    step "Removing conflicting packages"
    local present=() p
    for p in "${PKGS_REMOVE[@]}"; do
        pacman -Q "$p" >/dev/null 2>&1 && present+=("$p")
    done
    if [ "${#present[@]}" -eq 0 ]; then
        ok "nothing to remove"
        return
    fi
    info "to remove: ${present[*]}"
    confirm "Remove these?" || { warn "skipped"; return; }
    local noconfirm=()
    [ "$ASSUME_YES" = 1 ] && noconfirm=(--noconfirm)
    # One at a time, so something another package depends on doesn't block
    # the rest - it's just reported and left in place.
    for p in "${present[@]}"; do
        run sudo pacman -Rns "${noconfirm[@]}" "$p" || warn "could not remove $p (something depends on it) - left installed"
    done
}

step_shell() {
    step "Login shell"
    local current
    current=$(getent passwd "$USER" | cut -d: -f7)
    if [ "$(basename "$current")" = bash ]; then
        ok "already bash"
        return
    fi
    info "current login shell: $current (plasmalust's shell config is for bash)"
    if confirm "Switch your login shell to bash?"; then
        run sudo chsh -s /bin/bash "$USER" && ok "login shell set to bash (takes effect at next login)"
    else
        warn "kept $current - fastfetch/fzf/eza/yazi shell integration won't load there"
    fi
}

step_wallust() {
    step "wallust config"
    local tmp zen_profile="" as_dir=""
    tmp=$(mktemp)
    sed "s|/home/YOUR_USERNAME|$HOME|g" "$REPO/wallust.toml" > "$tmp"

    # Zen and Android Studio targets need per-machine paths - fill them in
    # if the app is there, otherwise drop the entry (it would just create
    # stray directories for an app that isn't installed).
    if [ -f "$HOME/.config/zen/profiles.ini" ]; then
        zen_profile=$(awk -F= '/^\[Install/{i=1} i && $1=="Default"{print $2; exit}' "$HOME/.config/zen/profiles.ini")
        [ -n "$zen_profile" ] || zen_profile=$(awk -F= '$1=="Path"{print $2; exit}' "$HOME/.config/zen/profiles.ini")
    fi
    as_dir=$(ls -d "$HOME"/.config/Google/AndroidStudio* 2>/dev/null | sort -V | tail -n 1 || true)
    python3 - "$tmp" "$zen_profile" "$as_dir" <<'PY'
import re, sys
path, zen, as_dir = sys.argv[1:4]
text = open(path).read()
def drop(name, t):
    return re.sub(r"\n\[templates\.%s\]\n(?:(?!\[).*\n?)*" % re.escape(name), "\n", t)
if zen:
    text = text.replace("YOUR_PROFILE.Default (release)", zen)
else:
    text = drop("zen", text)
if as_dir:
    text = re.sub(r"/[^\"]*/AndroidStudioXXXX\.X", as_dir, text)
else:
    text = drop("android-studio", text)
    text = drop("android-studio-ui-theme", text)
open(path, "w").write(re.sub(r"\n{3,}", "\n\n", text))
PY
    put_file "$tmp" "$HOME/.config/wallust/wallust.toml"
    rm -f "$tmp"
    # Linked, not copied, so `git pull` in the repo updates the templates too.
    put_link "$REPO/templates" "$HOME/.config/wallust/templates"
}

step_dotfiles() {
    step "Dotfiles"
    # kitty: only replace a config that doesn't already pull in the wallust
    # theme (a stock/absent one); a customised one just gets the include.
    local kc="$HOME/.config/kitty/kitty.conf"
    if [ ! -f "$kc" ]; then
        put_file "$REPO/dotfiles/kitty.conf" "$kc"
    elif ! grep -q '^include current-theme.conf' "$kc"; then
        put_block "$kc" "include current-theme.conf"
    fi

    # Skipped when ~/.bashrc already has this setup by hand (outside our
    # markers) - loading ble.sh or the fastfetch greeting twice breaks things.
    if awk '/^# >>> plasmalust >>>$/{s=1} !s; /^# <<< plasmalust <<<$/{s=0}' "$HOME/.bashrc" 2>/dev/null |
            grep -qE 'ble-attach|wallust/fzf\.sh'; then
        ok "~/.bashrc already has the plasmalust shell setup (added by hand) - left alone"
    else
        put_block "$HOME/.bashrc" "$(cat "$REPO/dotfiles/bashrc-plasmalust.sh")"
    fi

    local vim_block vf
    vim_block=$(grep -v '^$' "$REPO/dotfiles/vimrc")
    for vf in "$HOME/.vimrc" "$HOME/.config/nvim/init.vim"; do
        if awk '/^" >>> plasmalust >>>$/{s=1} !s; /^" <<< plasmalust <<<$/{s=0}' "$vf" 2>/dev/null | grep -q 'wallust\.vim'; then
            continue
        fi
        put_block "$vf" "$vim_block" '"'
    done

    # bat: Garuda ships --theme="Catppuccin Mocha" - swap in the wallust one.
    local batc="$HOME/.config/bat/config"
    if ! grep -qx -- '--theme="Wallust"' "$batc" 2>/dev/null; then
        local tmp
        tmp=$(mktemp)
        { grep -v -- '^--theme=' "$batc" 2>/dev/null || true; echo '--theme="Wallust"'; } > "$tmp"
        put_file "$tmp" "$batc"
        rm -f "$tmp"
    fi

    local mpvc="$HOME/.config/mpv/mpv.conf"
    grep -qx 'include=~/.config/mpv/colors.conf' "$mpvc" 2>/dev/null ||
        put_block "$mpvc" "include=~/.config/mpv/colors.conf"

    # Zen: only the profile wallust.toml's userChrome.css target points at.
    local zen_dir
    zen_dir=$(grep -o '"[^"]*/\.config/zen/[^"]*/chrome/userChrome\.css"' "$HOME/.config/wallust/wallust.toml" 2>/dev/null |
              tr -d '"' | sed 's|/chrome/userChrome\.css$||' || true)
    if [ -n "$zen_dir" ] && [ -d "$zen_dir" ]; then
        put_file "$REPO/dotfiles/zen-user.js" "$zen_dir/user.js"
    fi
}

step_bin() {
    step "Scripts in ~/.local/bin"
    local s
    put_link "$REPO/set-theme" "$HOME/.local/bin/set-theme"
    for s in "$REPO"/scripts/*; do
        put_link "$s" "$HOME/.local/bin/$(basename "$s")"
    done
    put_link "$REPO/toybox/plasmalust-toybox" "$HOME/.local/bin/plasmalust-toybox"
}

step_wallpapers() {
    step "Wallpapers"
    local dir="$HOME/Pictures/wallpapers"
    run mkdir -p "$dir"
    if [ -n "$WALLPAPER_SRC" ]; then
        [ -d "$WALLPAPER_SRC" ] || die "--wallpapers: $WALLPAPER_SRC is not a directory"
        run cp -n "$WALLPAPER_SRC"/* "$dir"/ 2>/dev/null || true
        ok "copied wallpapers from $WALLPAPER_SRC"
    fi
    if [ -n "$(find "$dir" -maxdepth 1 -type f 2>/dev/null | head -n 1)" ]; then
        ok "$(find "$dir" -maxdepth 1 -type f | wc -l) wallpapers in ~/Pictures/wallpapers"
        return
    fi
    # Empty: seed it with the wallpapers Garuda ships (largest resolution of
    # each KDE wallpaper package), so the picker/overlay has something to show.
    local pkg img n=0
    for pkg in /usr/share/wallpapers/*/; do
        img=$(find "$pkg" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
                  -printf '%s %p\n' 2>/dev/null | sort -rn | head -n 1 | cut -d' ' -f2- || true)
        [ -n "$img" ] || continue
        run cp "$img" "$dir/$(basename "$pkg").${img##*.}"
        n=$((n + 1))
    done
    ok "seeded ~/Pictures/wallpapers with $n Garuda wallpapers (add your own there any time)"
}

step_kde() {
    step "KDE settings"
    run bash "$REPO/layout/kde-settings.sh"
}

step_polish() {
    step "System polish (Kvantum, KWin scripts, kitty/yazi defaults)"
    run mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"
    run bash "$REPO/system-polish/apply-system-polish.sh"
    # apply-system-polish.sh installs copies of the overlay launchers -
    # put the repo links back so they follow `git pull`.
    local s
    for s in plasmalust-wallpaper-overlay plasmalust-menu-overlay; do
        [ -L "$HOME/.local/bin/$s" ] || { run rm -f "$HOME/.local/bin/$s"; put_link "$REPO/scripts/$s" "$HOME/.local/bin/$s"; }
    done
}

step_widgets() {
    step "Desktop widgets"
    run bash "$REPO/plasma-widgets/install-widgets.sh"
    local s
    for s in plasmalust-set-wallpaper plasmalust-refresh-thumbnails; do
        [ -L "$HOME/.local/bin/$s" ] || { run rm -f "$HOME/.local/bin/$s"; put_link "$REPO/scripts/$s" "$HOME/.local/bin/$s"; }
    done
}

step_theme() {
    step "First theme run"
    WALLPAPER=$(pick_wallpaper)
    [ -n "$WALLPAPER" ] || die "no wallpaper image found (run the 'wallpapers' step, or pass --wallpapers DIR)."
    info "wallpaper: $WALLPAPER"
    run plasma-apply-wallpaperimage "$WALLPAPER"
    # sudo parts run from the 'system' step instead, once, explicitly.
    run env PLASMALUST_NO_SUDO=1 "$REPO/set-theme" "$WALLPAPER"
}

step_layout() {
    step "Panel + desktop widget layout"
    [ -n "${WALLPAPER:-}" ] || WALLPAPER=$(pick_wallpaper)
    [ -n "$WALLPAPER" ] || die "no wallpaper image found."
    info "this replaces your current panels (old layout is backed up)."
    confirm "Import the plasmalust panel/widget layout?" || { warn "skipped"; return; }
    # set-theme restarts plasmashell in the background - let that settle
    # before import-layout.py stops it again to swap the config files.
    [ "$DRY_RUN" = 1 ] || sleep 4
    run python3 "$REPO/layout/import-layout.py" "$WALLPAPER"
}

step_system() {
    step "GRUB, login screen and splash (sudo)"
    if ! pacman -Q garuda-mokka >/dev/null 2>&1; then
        warn "skipped - needs garuda-mokka's GRUB theme"
        return
    fi
    [ -f "$HOME/.cache/wallust/grub-theme.txt" ] || [ "$DRY_RUN" = 1 ] || die "run the 'theme' step first."
    local dm
    dm=$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" .service)
    confirm "Theme GRUB, the $dm login screen and the boot splash?" || { warn "skipped"; return; }
    run sudo "$REPO/grub-theme/install-grub-theme.sh"
    case "$dm" in
        sddm)        run sudo "$REPO/sddm-theme/install-sddm.sh" ;;
        plasmalogin) run sudo "$REPO/plasmalogin/install-plasmalogin.sh" ;;
        *)           warn "unknown login manager '$dm' - login screen left alone" ;;
    esac
    run sudo "$REPO/ksplash-theme/install-ksplash.sh"
}

# --- main ---------------------------------------------------------------

while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes) ASSUME_YES=1 ;;
        -n|--dry-run) DRY_RUN=1 ;;
        --icons) WITH_ICONS=1 ;;
        --only) ONLY="$2"; shift ;;
        --skip) SKIP="$2"; shift ;;
        --wallpapers) WALLPAPER_SRC="$2"; shift ;;
        -h|--help) sed -n '2,/^set -euo/{/^set -euo/d;s/^# \{0,1\}//;p}' "$0"; exit 0 ;;
        *) die "unknown option: $1 (see --help)" ;;
    esac
    shift
done
for s in ${ONLY//,/ } ${SKIP//,/ }; do
    [[ " $ALL_STEPS " == *" $s "* ]] || die "unknown step '$s' (steps: $ALL_STEPS)"
done

preflight
WALLPAPER=""
for s in $ALL_STEPS; do
    if want "$s"; then "step_$s"; fi
done

step "Done"
[ -d "$BACKUP_DIR" ] && info "replaced files are backed up in ${BACKUP_DIR/#$HOME/\~}"
info "Log out and back in once, so KWin picks up the new scripts/shortcuts"
info "(Meta+X menu, Meta+O wallpapers, Meta+E yazi, Meta+T kitty)."
info "Change wallpaper any time with the picker widget, Meta+O, or: set-theme /path/to/image"
