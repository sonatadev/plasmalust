import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Layout.preferredWidth: 150
    Layout.preferredHeight: 46

    RunCommand {
        id: runner
    }

    function launch(cmd) {
        runner.exec("bash -c " + shellQuote(cmd));
    }

    function shellQuote(s) {
        return "'" + s.replace(/'/g, "'\\''") + "'";
    }

    Canvas {
        id: frame
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const accent = Kirigami.Theme.highlightColor;
            const bg = Kirigami.Theme.backgroundColor;
            const m = 6, fl = 12;

            ctx.shadowColor = Qt.rgba(accent.r, accent.g, accent.b, 0.55);
            ctx.shadowBlur = 10;

            ctx.fillStyle = Qt.rgba(bg.r, bg.g, bg.b, 0.78);
            ctx.strokeStyle = Qt.rgba(accent.r, accent.g, accent.b, 0.6);
            ctx.lineWidth = 1.2;
            ctx.fillRect(m, m, width - 2 * m, height - 2 * m);
            ctx.strokeRect(m, m, width - 2 * m, height - 2 * m);

            ctx.strokeStyle = accent;
            ctx.lineWidth = 2;
            function corner(x, y, dx, dy) {
                ctx.beginPath();
                ctx.moveTo(x, y + dy * fl);
                ctx.lineTo(x, y);
                ctx.lineTo(x + dx * fl, y);
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(x + dx * 5, y + dy * 5, 2, 0, Math.PI * 2);
                ctx.fillStyle = accent;
                ctx.fill();
            }
            corner(m, m, 1, 1);
            corner(width - m, m, -1, 1);
            corner(m, height - m, 1, -1);
            corner(width - m, height - m, -1, -1);
        }
    }

    Connections {
        target: Kirigami.Theme
        function onHighlightColorChanged() { frame.requestPaint(); }
        function onBackgroundColorChanged() { frame.requestPaint(); }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Text {
            text: "menu"
            font.family: "monospace"
            font.pixelSize: 14
            font.bold: true
            color: Kirigami.Theme.textColor
        }
        Item { Layout.fillWidth: true }
        Text {
            text: "▾"
            font.pixelSize: 14
            color: Kirigami.Theme.highlightColor
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: menu.popup()
    }

    QQC2.Menu {
        id: menu

        QQC2.MenuItem { text: "terminal"; onTriggered: root.launch("kitty") }
        QQC2.MenuItem { text: "files"; onTriggered: root.launch("dolphin") }
        QQC2.MenuItem { text: "discord"; onTriggered: root.launch("vesktop") }
        QQC2.MenuItem { text: "spotify"; onTriggered: root.launch("spotify") }
        QQC2.MenuItem { text: "steam"; onTriggered: root.launch("steam") }

        QQC2.MenuSeparator {}

        QQC2.Menu {
            title: "toybox"
            QQC2.MenuItem { text: "fetch"; onTriggered: root.launch("kitty -e bash -c 'fastfetch; read -n1'") }
            QQC2.MenuItem { text: "pride"; onTriggered: root.launch("kitty -e bash -c 'hyfetch; read -n1'") }
            QQC2.MenuItem { text: "matrix"; onTriggered: root.launch("kitty -e unimatrix") }
            QQC2.MenuItem { text: "fire"; onTriggered: root.launch("kitty -e aafire") }
            QQC2.MenuItem { text: "aquarium"; onTriggered: root.launch("kitty -e asciiquarium") }
            QQC2.MenuItem { text: "clock"; onTriggered: root.launch("kitty -e peaclock") }
            QQC2.MenuItem { text: "map"; onTriggered: root.launch("kitty -e mapscii") }
            QQC2.MenuItem { text: "monitor"; onTriggered: root.launch("kitty -e btop") }
            QQC2.MenuItem { text: "audio"; onTriggered: root.launch("kitty -e cava") }
        }

        QQC2.MenuSeparator {}

        QQC2.MenuItem { text: "lock"; onTriggered: root.launch("qdbus6 org.freedesktop.ScreenSaver /ScreenSaver Lock") }
        QQC2.MenuItem { text: "logout"; onTriggered: root.launch("qdbus6 org.kde.Shutdown /Shutdown logout") }
        QQC2.MenuItem { text: "reboot"; onTriggered: root.launch("qdbus6 org.kde.Shutdown /Shutdown logoutAndReboot") }
        QQC2.MenuItem { text: "shutdown"; onTriggered: root.launch("qdbus6 org.kde.Shutdown /Shutdown logoutAndShutdown") }
    }
}
