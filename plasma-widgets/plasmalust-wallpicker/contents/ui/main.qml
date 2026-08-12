import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Layout.preferredWidth: 460
    Layout.preferredHeight: 260

    readonly property int lineHeight: 28
    property bool expanded: false
    property real revealHeight: expanded ? height : lineHeight

    Behavior on revealHeight {
        NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
    }
    onRevealHeightChanged: frame.requestPaint()

    HoverHandler {
        id: hoverWatch
        onHoveredChanged: root.expanded = hovered
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
            const h = root.revealHeight;

            ctx.fillStyle = Qt.rgba(bg.r, bg.g, bg.b, 0.78);
            ctx.strokeStyle = Qt.rgba(accent.r, accent.g, accent.b, 0.6);
            ctx.lineWidth = 1.2;
            ctx.fillRect(m, m, width - 2 * m, h - 2 * m);
            ctx.strokeRect(m, m, width - 2 * m, h - 2 * m);

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
            corner(m, h - m, 1, -1);
            corner(width - m, h - m, -1, -1);
        }
    }

    Connections {
        target: Kirigami.Theme
        function onHighlightColorChanged() { frame.requestPaint(); }
        function onBackgroundColorChanged() { frame.requestPaint(); }
    }

    RowLayout {
        height: root.lineHeight
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 10

        Text {
            text: "wallpapers"
            font.family: "monospace"
            font.pixelSize: 14
            font.bold: true
            color: Kirigami.Theme.textColor
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

    ColumnLayout {
        visible: root.expanded
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: root.lineHeight + 14
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        spacing: 8
        clip: true

        Rectangle {
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
