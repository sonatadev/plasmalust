import QtQuick
import org.kde.kwin

// Hyprland-style Meta+Shift+Arrow window resize. Works on both floating
// and tiled windows - it just adjusts frameGeometry directly, which tiling
// extensions (krohnkite) pick up and cascade through the layout the same
// way their own resize shortcuts do.
Item {
    readonly property int step: 40
    readonly property int minWidth: 200
    readonly property int minHeight: 120

    function resizeActive(dw, dh) {
        const w = Workspace.activeWindow;
        if (!w || !w.resizeable) {
            return;
        }
        const g = w.frameGeometry;
        const newWidth = Math.max(minWidth, g.width + dw);
        const newHeight = Math.max(minHeight, g.height + dh);
        w.frameGeometry = { x: g.x, y: g.y, width: newWidth, height: newHeight };
    }

    ShortcutHandler {
        name: "PlasmalustResizeGrowWidth"
        text: "Plasmalust: Grow window width"
        sequence: "Meta+Shift+Right"
        onActivated: resizeActive(step, 0)
    }
    ShortcutHandler {
        name: "PlasmalustResizeShrinkWidth"
        text: "Plasmalust: Shrink window width"
        sequence: "Meta+Shift+Left"
        onActivated: resizeActive(-step, 0)
    }
    ShortcutHandler {
        name: "PlasmalustResizeGrowHeight"
        text: "Plasmalust: Grow window height"
        sequence: "Meta+Shift+Down"
        onActivated: resizeActive(0, step)
    }
    ShortcutHandler {
        name: "PlasmalustResizeShrinkHeight"
        text: "Plasmalust: Shrink window height"
        sequence: "Meta+Shift+Up"
        onActivated: resizeActive(0, -step)
    }
}
