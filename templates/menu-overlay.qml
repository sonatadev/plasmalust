import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.plasma5support as P5Support

Window {
    id: root
    visible: true
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"
    width: 220
    height: content.implicitHeight + 24

    readonly property color bg: "{{ background }}"
    readonly property color fg: "{{ foreground }}"
    readonly property color accent: "{{ color4 }}"

    Component.onCompleted: {
        x = Screen.width / 2 - width / 2;
        y = Screen.height / 2 - height / 2;
    }

    property bool everActivated: false
    onActiveChanged: {
        if (active) everActivated = true;
        else if (everActivated) root.close();
    }

    function shellQuote(s) {
        return "'" + s.replace(/'/g, "'\\''") + "'";
    }

    function launch(cmd) {
        runner.exec("bash -c " + shellQuote(cmd));
        root.close();
    }

    P5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []
        function exec(cmd) { connectSource(cmd); }
        onNewData: disconnectSource(source)
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(root.bg.r, root.bg.g, root.bg.b, 0.94)
        radius: 10
        border.width: 1
        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.55)

        Canvas {
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const accent = root.accent;
                const m = 8, fl = 16;
                ctx.strokeStyle = accent;
                ctx.lineWidth = 1.5;
                function corner(x, y, dx, dy) {
                    ctx.beginPath();
                    ctx.moveTo(x, y + dy * fl);
                    ctx.lineTo(x, y);
                    ctx.lineTo(x + dx * fl, y);
                    ctx.stroke();
                }
                corner(m, m, 1, 1);
                corner(width - m, m, -1, 1);
                corner(m, height - m, 1, -1);
                corner(width - m, height - m, -1, -1);
            }
            Component.onCompleted: requestPaint()
        }

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 2

            MenuHeading { text: "menu" }
            MenuAction { text: "terminal"; onTriggered: root.launch("kitty") }
            MenuAction { text: "files"; onTriggered: root.launch("kitty --single-instance --title yazi -e yazi") }
            MenuAction { text: "discord"; onTriggered: root.launch("vesktop") }
            MenuAction { text: "spotify"; onTriggered: root.launch("spotify") }
            MenuAction { text: "steam"; onTriggered: root.launch("steam") }

            MenuSep {}

            MenuHeading { text: "toybox" }
            MenuAction { text: "fetch"; onTriggered: root.launch("kitty -e bash -c 'fastfetch; read -n1'") }
            MenuAction { text: "pride"; onTriggered: root.launch("kitty -e bash -c 'hyfetch; read -n1'") }
            MenuAction { text: "matrix"; onTriggered: root.launch("kitty -e unimatrix") }
            MenuAction { text: "fire"; onTriggered: root.launch("kitty -e aafire") }
            MenuAction { text: "aquarium"; onTriggered: root.launch("kitty -e asciiquarium") }
            MenuAction { text: "clock"; onTriggered: root.launch("kitty -e peaclock") }
            MenuAction { text: "map"; onTriggered: root.launch("kitty -e mapscii") }
            MenuAction { text: "monitor"; onTriggered: root.launch("kitty -e btop") }
            MenuAction { text: "audio"; onTriggered: root.launch("kitty -e cava") }
            MenuAction { text: "bonsai"; onTriggered: root.launch("kitty -e cbonsai -S") }
            MenuAction { text: "stars"; onTriggered: root.launch("kitty -e astroterm -c -C -g -u -q -a 38.11 -o 15.66") }
            MenuAction { text: "palette"; onTriggered: root.launch("kitty -e plasmalust-toybox") }

            MenuSep {}

            MenuHeading { text: "power" }
            MenuAction { text: "lock"; onTriggered: root.launch("qdbus6 org.freedesktop.ScreenSaver /ScreenSaver Lock") }
            MenuAction { text: "logout"; onTriggered: root.launch("qdbus6 org.kde.Shutdown /Shutdown logout") }
            MenuAction { text: "reboot"; onTriggered: root.launch("qdbus6 org.kde.Shutdown /Shutdown logoutAndReboot") }
            MenuAction { text: "shutdown"; onTriggered: root.launch("qdbus6 org.kde.Shutdown /Shutdown logoutAndShutdown") }

            Item { Layout.preferredHeight: 4 }
        }
    }

    component MenuHeading: Text {
        Layout.fillWidth: true
        Layout.topMargin: 4
        font.family: "monospace"
        font.pixelSize: 10
        font.bold: true
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.7)
    }

    component MenuSep: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.topMargin: 4
        Layout.bottomMargin: 2
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25)
    }

    component MenuAction: Rectangle {
        id: actionRoot
        signal triggered()
        property alias text: label.text
        Layout.fillWidth: true
        Layout.preferredHeight: 24
        radius: 4
        color: actionArea.containsMouse ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18) : "transparent"

        Text {
            id: label
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            font.family: "monospace"
            font.pixelSize: 13
            color: root.fg
        }

        MouseArea {
            id: actionArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: actionRoot.triggered()
        }
    }
}
