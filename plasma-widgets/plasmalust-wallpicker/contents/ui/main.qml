import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Layout.preferredWidth: 640
    Layout.preferredHeight: 560

    property bool collapsed: true
    readonly property int collapsedHeight: 56

    width: Layout.preferredWidth
    height: collapsed ? collapsedHeight : Layout.preferredHeight

    Behavior on height {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
    }

    property var wallpapers: []
    property string filterText: ""
    property string applyingName: ""

    readonly property var filtered: {
        if (!filterText) return wallpapers;
        const q = filterText.toLowerCase();
        return wallpapers.filter(w => w.name.toLowerCase().includes(q));
    }

    RunCommand {
        id: runner
    }

    function load() {
        runner.exec("cat /home/YOUR_USERNAME/.cache/wallust/thumbnails/index.json", function (stdout) {
            try {
                root.wallpapers = JSON.parse(stdout || "[]");
            } catch (e) {
                root.wallpapers = [];
            }
        });
    }

    function shellQuote(s) {
        return "'" + s.replace(/'/g, "'\\''") + "'";
    }

    function apply(entry) {
        root.applyingName = entry.name;
        runner.exec("/home/YOUR_USERNAME/.local/bin/plasmalust-set-wallpaper " + shellQuote(entry.original), function () {
            root.applyingName = "";
        });
    }

    Component.onCompleted: load()

    Canvas {
        id: frame
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const accent = Kirigami.Theme.highlightColor;
            const bg = Kirigami.Theme.backgroundColor;
            const m = 6, fl = 18;

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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8
        clip: true

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Item {
                width: 16
                height: 16
                Canvas {
                    id: chevron
                    anchors.fill: parent
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        ctx.fillStyle = Kirigami.Theme.highlightColor;
                        ctx.beginPath();
                        if (root.collapsed) {
                            // pointing right
                            ctx.moveTo(5, 2); ctx.lineTo(12, 8); ctx.lineTo(5, 14);
                        } else {
                            // pointing down
                            ctx.moveTo(2, 5); ctx.lineTo(8, 12); ctx.lineTo(14, 5);
                        }
                        ctx.closePath();
                        ctx.fill();
                    }
                }
                Connections {
                    target: root
                    function onCollapsedChanged() { chevron.requestPaint(); }
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.collapsed = !root.collapsed
                }
            }
            Text {
                text: "wallpapers"
                font.family: "monospace"
                font.pixelSize: 15
                font.bold: true
                color: Kirigami.Theme.textColor
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.collapsed = !root.collapsed
                }
            }
            Item { Layout.fillWidth: true }
            Text {
                visible: root.applyingName !== ""
                text: "applying " + root.applyingName + "..."
                font.family: "monospace"
                font.pixelSize: 11
                color: Kirigami.Theme.highlightColor
            }
        }

        Rectangle {
            visible: !root.collapsed
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            radius: 4
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
            border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.5)
            border.width: 1

            QQC2.TextField {
                anchors.fill: parent
                anchors.margins: 1
                background: Item {}
                placeholderText: "filter..."
                font.family: "monospace"
                font.pixelSize: 12
                color: Kirigami.Theme.textColor
                onTextChanged: root.filterText = text
            }
        }

        GridView {
            id: grid
            visible: !root.collapsed
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: 96
            cellHeight: 82
            clip: true
            model: root.filtered

            delegate: Item {
                required property var modelData
                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 4
                    color: "transparent"
                    border.width: hoverArea.containsMouse ? 2 : 1
                    border.color: hoverArea.containsMouse
                        ? Kirigami.Theme.highlightColor
                        : Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.35)

                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        source: "file://" + modelData.thumb
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.apply(modelData)
                }
            }
        }
    }
}
