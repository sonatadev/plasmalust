import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Dialogs
import org.kde.plasma.plasma5support as P5Support

Window {
    id: root
    visible: true
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"
    visibility: Window.FullScreen

    readonly property color bg: "{{ background }}"
    readonly property color fg: "{{ foreground }}"
    readonly property color accent: "{{ color4 }}"
    readonly property color accent2: "{{ color5 }}"

    property var wallpapers: []
    property string applyingName: ""
    readonly property var filtered: {
        if (!filterField.text) return wallpapers;
        const q = filterField.text.toLowerCase();
        return wallpapers.filter(w => w.name.toLowerCase().includes(q));
    }

    function shellQuote(s) {
        return "'" + s.replace(/'/g, "'\\''") + "'";
    }

    function loadIndex() {
        runner.exec("cat /home/YOUR_USERNAME/.cache/wallust/thumbnails/index.json", function (stdout) {
            try {
                root.wallpapers = JSON.parse(stdout || "[]");
            } catch (e) {
                root.wallpapers = [];
            }
        });
    }

    function apply(entry) {
        root.applyingName = entry.name;
        runner.exec("/home/YOUR_USERNAME/.local/bin/plasmalust-set-wallpaper " + shellQuote(entry.original), function () {
            root.close();
        });
    }

    function remove(entry) {
        runner.exec("rm -f " + shellQuote(entry.original) + " " + shellQuote(entry.thumb), function () {
            root.wallpapers = root.wallpapers.filter(w => w.original !== entry.original);
        });
    }

    P5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []
        property var callbacks: ({})
        function exec(cmd, callback) {
            if (callback) callbacks[cmd] = callback;
            connectSource(cmd);
        }
        onNewData: function (source, data) {
            const stdout = data["stdout"];
            disconnectSource(source);
            const cb = callbacks[source];
            if (cb) {
                delete callbacks[source];
                cb(stdout);
            }
        }
    }

    Component.onCompleted: loadIndex()

    // Click-outside-to-close backdrop
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.close()
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.82, 1180)
        height: Math.min(parent.height * 0.82, 780)
        color: Qt.rgba(root.bg.r, root.bg.g, root.bg.b, 0.92)
        radius: 14
        border.width: 1
        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.55)

        MouseArea { anchors.fill: parent }  // swallow clicks so they don't hit the backdrop

        Canvas {
            id: frame
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const accent = root.accent;
                const m = 14, fl = 34;
                ctx.strokeStyle = accent;
                ctx.lineWidth = 2;
                function corner(x, y, dx, dy) {
                    ctx.beginPath();
                    ctx.moveTo(x, y + dy * fl);
                    ctx.lineTo(x, y);
                    ctx.lineTo(x + dx * fl, y);
                    ctx.stroke();

                    const s = 10, cx = x + dx * s, cy = y + dy * s;
                    ctx.beginPath();
                    ctx.moveTo(cx, cy - 4);
                    ctx.lineTo(cx + 4, cy);
                    ctx.lineTo(cx, cy + 4);
                    ctx.lineTo(cx - 4, cy);
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
            anchors.fill: parent
            anchors.margins: 28
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "wallpapers"
                    font.family: "monospace"
                    font.pixelSize: 20
                    font.bold: true
                    color: root.fg
                }
                Text {
                    Layout.fillWidth: true
                    text: root.filtered.length + " / " + root.wallpapers.length
                    font.family: "monospace"
                    font.pixelSize: 12
                    color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.55)
                }
                Text {
                    visible: root.applyingName !== ""
                    text: "applying " + root.applyingName + "..."
                    font.family: "monospace"
                    font.pixelSize: 12
                    color: root.accent
                }
                Text {
                    text: "esc to close"
                    font.family: "monospace"
                    font.pixelSize: 11
                    color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.4)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 6
                color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.07)
                border.width: 1
                border.color: filterField.activeFocus
                    ? root.accent
                    : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.35)

                TextField {
                    id: filterField
                    anchors.fill: parent
                    anchors.margins: 1
                    background: Item {}
                    placeholderText: "filter..."
                    placeholderTextColor: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.4)
                    font.family: "monospace"
                    font.pixelSize: 13
                    color: root.fg
                    focus: true
                    Keys.onEscapePressed: root.close()
                }
            }

            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: 168
                cellHeight: 132
                model: root.filtered

                delegate: Item {
                    id: cell
                    required property var modelData
                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: 8
                        color: "transparent"
                        border.width: hoverArea.containsMouse ? 2 : 1
                        border.color: hoverArea.containsMouse
                            ? root.accent
                            : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.3)

                        Image {
                            anchors.fill: parent
                            anchors.margins: 3
                            source: "file://" + cell.modelData.thumb
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                        }

                        Text {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 4
                            visible: hoverArea.containsMouse
                            text: cell.modelData.name
                            font.family: "monospace"
                            font.pixelSize: 10
                            color: root.fg
                            elide: Text.ElideRight
                            style: Text.Outline
                            styleColor: Qt.rgba(0, 0, 0, 0.8)
                        }

                        Rectangle {
                            visible: hoverArea.containsMouse
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 4
                            width: 22
                            height: 22
                            radius: 11
                            color: deleteArea.containsMouse ? root.accent2 : Qt.rgba(0, 0, 0, 0.55)
                            border.width: 1
                            border.color: root.accent2

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                font.pixelSize: 14
                                font.bold: true
                                color: root.fg
                            }

                            MouseArea {
                                id: deleteArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    confirmDialog.pendingEntry = cell.modelData;
                                    confirmDialog.text = "Delete \"" + cell.modelData.name + "\" permanently?";
                                    confirmDialog.open();
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        anchors.margins: 6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.apply(cell.modelData)
                    }
                }
            }
        }
    }

    MessageDialog {
        id: confirmDialog
        property var pendingEntry: null
        buttons: MessageDialog.Yes | MessageDialog.No
        onButtonClicked: function (button) {
            if (button === MessageDialog.Yes && pendingEntry) {
                root.remove(pendingEntry);
            }
            pendingEntry = null;
        }
    }
}
