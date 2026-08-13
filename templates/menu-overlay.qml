import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.plasma5support as P5Support

Window {
    id: root
    visible: true
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"
    width: 190
    height: mainList.implicitHeight + 20

    // Anti-tiling is handled by adding this window's resourceClass
    // (org.qt-project.qml, shared by all qml6-launched popups) to
    // krohnkite's own ignoreClass config (system-polish install step), so
    // krohnkite never manages this window at all. floatingClass was tried
    // first: krohnkite still captures a "floatGeometry" snapshot for
    // floated windows and re-commits it on every layout pass, and that
    // snapshot is taken from the window's still-negotiating initial size
    // (before content settles) - it forced this popup to a wrong, huge,
    // half-workarea size every time. Before that, locking
    // minimumHeight/maximumHeight to this dynamic content-driven height
    // was tried, which raced content layout instead: KWin latched the
    // constraint before mainList.implicitHeight had settled, wedging the
    // window at ~20px tall. Qt.Tool was tried before that and did nothing
    // (KWin still reported isUtility=false under Wayland here).

    readonly property color bg: "{{ background }}"
    readonly property color fg: "{{ foreground }}"
    readonly property color accent: "{{ color4 }}"
    readonly property color accent2: "{{ color5 }}"

    // Entrance fade: a static popup appearing instantly reads as a plain
    // dialog, not a "menu". (Window isn't an Item, so it doesn't support
    // a transform property like scale - the inner Panel does its own
    // scale-in instead.)
    opacity: 0

    Component.onCompleted: {
        x = Screen.width / 2 - width / 2;
        y = Screen.height / 2 - height / 2 - 60;
        entrance.start();
    }

    NumberAnimation {
        id: entrance
        target: root
        property: "opacity"
        to: 1.0
        duration: 110
    }

    property bool everActivated: false
    onActiveChanged: {
        if (active) everActivated = true;
        else if (everActivated) root.close();
    }

    property bool toyboxOpen: false

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
        color: Qt.rgba(root.bg.r, root.bg.g, root.bg.b, 0.95)
        radius: 10
        border.width: 1
        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.55)
        transformOrigin: Item.Center
        scale: 0.94
        Component.onCompleted: scaleIn.start()
        NumberAnimation {
            id: scaleIn
            target: parent
            property: "scale"
            to: 1.0
            duration: 140
            easing.type: Easing.OutBack
        }

        Canvas {
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const accent = root.accent;
                const m = 7, fl = 13;
                ctx.strokeStyle = accent;
                ctx.lineWidth = 1.4;
                function corner(x, y, dx, dy) {
                    ctx.beginPath();
                    ctx.moveTo(x, y + dy * fl);
                    ctx.lineTo(x, y);
                    ctx.lineTo(x + dx * fl, y);
                    ctx.stroke();
                    const s = 6, cx = x + dx * s, cy = y + dy * s;
                    ctx.beginPath();
                    ctx.moveTo(cx, cy - 2.5);
                    ctx.lineTo(cx + 2.5, cy);
                    ctx.lineTo(cx, cy + 2.5);
                    ctx.lineTo(cx - 2.5, cy);
                    ctx.closePath();
                    ctx.fillStyle = accent;
                    ctx.fill();
                }
                corner(m, m, 1, 1);
                corner(width - m, m, -1, 1);
                corner(m, height - m, 1, -1);
                corner(width - m, height - m, -1, -1);
            }
            Component.onCompleted: requestPaint()
        }

        ColumnLayout {
            id: mainList
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 1

            MenuHeading { text: "apps" }
            MenuAction { itemText: "terminal"; onTriggered: root.launch("kitty") }
            MenuAction { itemText: "files"; onTriggered: root.launch("kitty --single-instance --title yazi -e yazi") }
            MenuAction { itemText: "discord"; onTriggered: root.launch("vesktop") }
            MenuAction { itemText: "spotify"; onTriggered: root.launch("spotify") }
            MenuAction { itemText: "steam"; onTriggered: root.launch("steam") }
            MenuAction {
                itemText: "toybox"
                submenu: true
                submenuOpen: root.toyboxOpen
                onTriggered: root.toyboxOpen = !root.toyboxOpen
            }

            // Inline expand/collapse instead of a hover flyout - a second
            // top-level Window would be needed to draw outside this one's
            // bounds (a Window clips to its own surface), which is more
            // machinery than a menu this size needs.
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                spacing: 1
                visible: root.toyboxOpen
                clip: true

                MenuAction { itemText: "fetch"; small: true; onTriggered: root.launch("kitty -e bash -c 'fastfetch; read -n1'") }
                MenuAction { itemText: "pride"; small: true; onTriggered: root.launch("kitty -e bash -c 'hyfetch; read -n1'") }
                MenuAction { itemText: "matrix"; small: true; onTriggered: root.launch("kitty -e unimatrix") }
                MenuAction { itemText: "fire"; small: true; onTriggered: root.launch("kitty -e aafire") }
                MenuAction { itemText: "aquarium"; small: true; onTriggered: root.launch("kitty -e asciiquarium") }
                MenuAction { itemText: "clock"; small: true; onTriggered: root.launch("kitty -e peaclock") }
                MenuAction { itemText: "map"; small: true; onTriggered: root.launch("kitty -e mapscii") }
                MenuAction { itemText: "monitor"; small: true; onTriggered: root.launch("kitty -e btop") }
                MenuAction { itemText: "audio"; small: true; onTriggered: root.launch("kitty -e cava") }
                MenuAction { itemText: "bonsai"; small: true; onTriggered: root.launch("kitty -e cbonsai -S") }
                MenuAction { itemText: "stars"; small: true; onTriggered: root.launch("kitty -e astroterm -c -C -g -u -q -a 38.11 -o 15.66") }
                MenuAction { itemText: "palette"; small: true; onTriggered: root.launch("kitty -e plasmalust-toybox") }
            }

            MenuSep {}

            MenuHeading { text: "system" }
            MenuAction { itemText: "lock"; onTriggered: root.launch("qdbus6 org.freedesktop.ScreenSaver /ScreenSaver Lock") }
            MenuAction { itemText: "logout"; onTriggered: root.launch("qdbus6 org.kde.Shutdown /Shutdown logout") }
            MenuAction { itemText: "reboot"; onTriggered: root.launch("qdbus6 org.kde.Shutdown /Shutdown logoutAndReboot") }
            MenuAction { itemText: "shutdown"; onTriggered: root.launch("qdbus6 org.kde.Shutdown /Shutdown logoutAndShutdown") }
        }
    }

    component MenuHeading: Text {
        Layout.fillWidth: true
        Layout.bottomMargin: 2
        font.family: "monospace"
        font.pixelSize: 9
        font.bold: true
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.6)
    }

    component MenuSep: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.topMargin: 3
        Layout.bottomMargin: 3
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25)
    }

    component MenuAction: Rectangle {
        id: actionRoot
        signal triggered()
        property string itemText: ""
        property bool submenu: false
        property bool submenuOpen: false
        property bool small: false
        readonly property bool hovered: actionArea.containsMouse

        Layout.fillWidth: true
        Layout.preferredHeight: small ? 21 : 24
        radius: 5
        color: hovered ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.2) : "transparent"
        Behavior on color { ColorAnimation { duration: 90 } }

        Rectangle {
            id: bullet
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 5
            height: 5
            rotation: 45
            color: actionRoot.hovered ? root.accent2 : root.accent
            opacity: actionRoot.hovered ? 1.0 : 0.6
            scale: actionRoot.hovered ? 1.3 : 1.0
            Behavior on scale { NumberAnimation { duration: 90 } }
            Behavior on color { ColorAnimation { duration: 90 } }
        }

        Text {
            anchors.left: bullet.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: actionRoot.itemText
            font.family: "monospace"
            font.pixelSize: actionRoot.small ? 12 : 13
            color: root.fg
        }

        Text {
            visible: actionRoot.submenu
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: actionRoot.submenuOpen ? "▾" : "▸"
            font.pixelSize: 11
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.7)
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
