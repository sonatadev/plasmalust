import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Layout.preferredWidth: 460
    Layout.preferredHeight: 140

    property var bars: []

    RunCommand {
        id: runner
    }

    function refresh() {
        runner.exec("cat /home/YOUR_USERNAME/.cache/wallust/cava-bars", function (stdout) {
            const line = (stdout || "").trim();
            if (!line) return;
            const vals = line.split(";").filter(s => s.length > 0).map(Number);
            if (vals.length) root.bars = vals;
        });
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 90
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Canvas {
        id: frame
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const accent = Kirigami.Theme.highlightColor;
            const bg = Kirigami.Theme.backgroundColor;
            const m = 6, fl = 16;

            ctx.fillStyle = Qt.rgba(bg.r, bg.g, bg.b, 0.72);
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
        anchors.margins: 22
        spacing: 4
        clip: true

        Repeater {
            model: root.bars.length
            delegate: Rectangle {
                required property int index
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBottom
                Layout.preferredHeight: Math.max(3, (root.bars[index] / 100) * parent.height)
                radius: 1
                color: Kirigami.Theme.highlightColor
                opacity: 0.55 + 0.45 * (root.bars[index] / 100)

                Behavior on Layout.preferredHeight {
                    NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
                }
            }
        }
    }
}
