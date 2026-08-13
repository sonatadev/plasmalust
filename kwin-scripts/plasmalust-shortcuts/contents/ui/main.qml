import QtQuick
import org.kde.kwin
import org.kde.plasma.plasma5support as P5Support

// App-launcher shortcuts (menu overlay, wallpaper overlay, yazi) as a KWin
// script instead of the standard kglobalshortcutsrc "_launch" desktop-file
// mechanism, which was tried first: kglobalaccel showed each shortcut
// registered, active, with the right keycode, and invoking it over D-Bus
// launched the app fine, but the physical keypress itself never got that
// far after a real logout/login.
Item {
    P5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []
        function exec(cmd) { connectSource(cmd); }
        // The bare "onNewData: disconnectSource(source)" shorthand used in
        // the standalone qml6 popups doesn't work here - KWin's
        // declarativescript engine doesn't implicitly expose the signal's
        // sourceName parameter the way a full qml6 app does, and silently
        // throws "source is not defined" instead (visible in
        // journalctl for kwin_wayland), which was the actual reason these
        // shortcuts didn't do anything when pressed.
        onNewData: function (sourceName) { disconnectSource(sourceName); }
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
