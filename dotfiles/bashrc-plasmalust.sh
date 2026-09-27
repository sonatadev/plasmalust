# Everything plasmalust's shell setup needs, as one block - install.sh puts
# this between "# >>> plasmalust >>>" / "# <<< plasmalust <<<" markers at the
# end of ~/.bashrc and replaces just that block on re-runs, leaving the rest
# of the file alone. The individual bashrc-*-snippet.sh files are the same
# pieces, for adding by hand instead.
#
# ble.sh (fish-style autosuggestions + syntax highlighting) is loaded with
# --noattach here and attached at the very end of the block, so it wraps
# everything defined before it - but that only works if this block is the
# last thing in ~/.bashrc, which is where install.sh appends it.

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

[[ $- == *i* ]] || return 0

[ -f /usr/share/blesh/ble.sh ] && source /usr/share/blesh/ble.sh --noattach

# fzf key bindings (Ctrl+R history, Ctrl+T file, Alt+C cd) + completion.
# Minus fzf's three "\C-z: emacs/vi-editing-mode" lines - a vi-mode toggle
# trick that stable ble.sh (0.3.4) doesn't support, so it printed
# "ble.sh (bind): unsupported readline function" on every new shell. ble.sh
# writes those through its own saved copy of stderr, so filtering stderr
# afterwards can't hide them; not binding them in the first place does.
[ -f /usr/share/fzf/key-bindings.bash ] && source <(grep -v 'editing-mode' /usr/share/fzf/key-bindings.bash)
[ -f /usr/share/fzf/completion.bash ] && source /usr/share/fzf/completion.bash

# wallust-generated fzf / eza colors
[ -f ~/.cache/wallust/fzf.sh ] && source ~/.cache/wallust/fzf.sh
[ -f ~/.cache/wallust/eza.sh ] && source ~/.cache/wallust/eza.sh

# yazi: wrap it so the shell cd's into wherever you were browsing on exit
function y() {
	local tmp cwd
	tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
alias fm="y"
alias ff="fastfetch"
alias toybox="plasmalust-toybox"

# fastfetch (portrait logo) on shell start - see bashrc-fastfetch-snippet.sh
# for why the short delay + width floor.
if command -v fastfetch &> /dev/null; then
    sleep 0.06
    if [ "$(tput cols 2>/dev/null || echo 999)" -lt 80 ]; then
        fastfetch --logo none
    else
        fastfetch
    fi
fi

# ble.sh: attach last, after everything above has set up its bindings.
[[ ${BLE_VERSION-} ]] && ble-attach
