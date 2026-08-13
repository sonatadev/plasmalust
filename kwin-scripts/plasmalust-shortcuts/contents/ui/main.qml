import QtQuick
import org.kde.kwin
import org.kde.plasma.plasma5support as P5Support

// App-launcher shortcuts (menu overlay, wallpaper overlay, yazi) as a KWin
// script instead of the standard kglobalshortcutsrc "_launch" desktop-file
// mechanism. The desktop-file approach was tried first and looked correct
// end to end - kglobalaccel showed each shortcut registered, active, with
// the right keycode, and invoking it over D-Bus launched the app fine -
// but the physical keypress never reached kglobalaccel after a real
// logout/login, meaning kwin_wayland's own compositor-level key grab
// wasn't in sync with kglobalaccel's registry. Declarative KWin-script
// ShortcutHandlers don't go through that path at all (confirmed reliable
// already for the Meta+Shift+Arrow resize shortcuts), so this runs the
// same commands through one instead.
Item {
    P5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []
        function exec(cmd) { connectSource(cmd); }
        onNewData: disconnectSource(source)
    }

    ShortcutHandler {
        name: "PlasmalustMenuOverlay"
        text: "Plasmalust: Open menu"
        sequence: "Meta+X"
        onActivated: runner.exec("plasmalust-menu-overlay")
    }
    ShortcutHandler {
        name: "PlasmalustWallpaperOverlay"
        text: "Plasmalust: Open wallpaper picker"
        sequence: "Meta+O"
        onActivated: runner.exec("plasmalust-wallpaper-overlay")
    }
    ShortcutHandler {
        name: "PlasmalustYazi"
        text: "Plasmalust: Open yazi"
        sequence: "Meta+E"
        onActivated: runner.exec("kitty --single-instance --title yazi -e yazi")
    }
}
