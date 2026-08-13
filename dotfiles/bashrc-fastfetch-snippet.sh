# Run fastfetch on interactive shell start. The portrait logo is a fixed
# 26-column image - in narrow/tiled terminal panes there isn't room for it
# plus the info text, which wraps character-by-character into a garbled
# mess. Below 80 columns, skip the logo entirely instead.
if [[ $- == *i* ]] && command -v fastfetch &> /dev/null; then
    if [ "$(tput cols 2>/dev/null || echo 999)" -lt 80 ]; then
        fastfetch --logo none
    else
        fastfetch
    fi
fi
