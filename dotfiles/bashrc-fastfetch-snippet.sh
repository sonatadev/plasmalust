# Run fastfetch (with the portrait logo) on interactive shell start. The
# logo is a fixed-position image, drawn at whatever size the window happens
# to be at that exact moment - tiling window managers resize a freshly
# opened window right after creation, and if fastfetch measures its size
# before that settles, the image ends up garbled. A SIGWINCH-based
# self-heal (catch the resize, clear, redraw) was tried first but ble.sh
# installs its own signal handling that interferes with a plain `trap`,
# so the redraw silently lost the logo too. A short fixed delay is simpler
# and reliable: tiling happens within a few ms of window creation, so
# waiting 150ms is plenty and isn't perceptible as lag.
if [[ $- == *i* ]] && command -v fastfetch &> /dev/null; then
    sleep 0.15
    fastfetch
fi
