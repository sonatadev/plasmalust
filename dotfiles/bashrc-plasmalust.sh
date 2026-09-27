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

# fzf key bindings (Ctrl+R history, Ctrl+T file, Alt+C cd) + completion
[ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash
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

# ble.sh: attach last. Stable blesh 0.3.4 warns (from a deferred task, so
# the filter has to stay on) about two compiled-in readline defaults it
# doesn't implement - harmless, just noise.
if [[ ${BLE_VERSION-} ]]; then
    exec 2> >(grep -v "ble.sh (bind): unsupported readline function '\(emacs\|vi\)-editing-mode'\." >&2)
    ble-attach
fi
