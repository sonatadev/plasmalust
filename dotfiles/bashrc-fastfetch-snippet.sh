# Run fastfetch (with the portrait logo) on interactive shell start. The
# logo is a fixed-position image, drawn at whatever size the window happens
# to be at that exact moment - tiling window managers resize a freshly
# opened window right after creation, and if fastfetch measures its size
# before that settles, the image ends up garbled. Two guards: a short
# delay so the size check below sees the window's settled size rather
# than racing the resize, and a hard width floor so genuinely narrow
# tiled panes never even attempt the image (there's no delay that fixes
# "too small to hold the logo at all").
if [[ $- == *i* ]] && command -v fastfetch &> /dev/null; then
    sleep 0.06
    if [ "$(tput cols 2>/dev/null || echo 999)" -lt 80 ]; then
        fastfetch --logo none
    else
        fastfetch
    fi
fi
