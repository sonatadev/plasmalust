# Run fastfetch on interactive shell start, text-only. The portrait logo
# is a fixed-position image, drawn at whatever size the window happens to
# be at that exact moment - but tiling window managers often resize a
# freshly-opened window right after creation, which invalidates the
# already-drawn image's layout and leaves it a garbled mess (checking
# column count first doesn't help, since the race is against a resize
# that hasn't happened *yet* when fastfetch runs). Run `ff` manually for
# the full portrait version once the window has settled.
[[ $- == *i* ]] && command -v fastfetch &> /dev/null && fastfetch --logo none
