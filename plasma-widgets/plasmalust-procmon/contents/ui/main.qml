import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Layout.preferredWidth: 460
    Layout.preferredHeight: 300

    property var procs: []

    RunCommand {
        id: runner
    }

    function refresh() {
        runner.exec("ps -eo pid,comm,user,%mem,%cpu --sort=-%cpu --no-headers", function (stdout) {
            const lines = (stdout || "").trim().split("\n").slice(0, 8);
            const rows = [];
            for (const line of lines) {
                const parts = line.trim().split(/\s+/);
                if (parts.length < 5) continue;
                const pid = parts[0];
                const user = parts[parts.length - 2];
                const mem = parts[parts.length - 3];
                const cpu = parts[parts.length - 1];
                const name = parts.slice(1, parts.length - 3).join(" ");
                rows.push({ pid: pid, name: name, user: user, mem: mem, cpu: cpu });
            }
            root.procs = rows;
        });
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 2500
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
            const m = 6, fl = 18;

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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 4
        clip: true

        Text {
            text: "processes"
            font.family: "monospace"
            font.pixelSize: 15
            font.bold: true
            color: Kirigami.Theme.textColor
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.bottomMargin: 4
            color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.5)
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "pid"; Layout.preferredWidth: 55; font.family: "monospace"; font.pixelSize: 10; font.bold: true; color: Kirigami.Theme.highlightColor }
            Text { text: "name"; Layout.fillWidth: true; font.family: "monospace"; font.pixelSize: 10; font.bold: true; color: Kirigami.Theme.highlightColor }
            Text { text: "user"; Layout.preferredWidth: 65; font.family: "monospace"; font.pixelSize: 10; font.bold: true; color: Kirigami.Theme.highlightColor }
            Text { text: "mem%"; Layout.preferredWidth: 45; horizontalAlignment: Text.AlignRight; font.family: "monospace"; font.pixelSize: 10; font.bold: true; color: Kirigami.Theme.highlightColor }
            Text { text: "cpu%"; Layout.preferredWidth: 45; horizontalAlignment: Text.AlignRight; font.family: "monospace"; font.pixelSize: 10; font.bold: true; color: Kirigami.Theme.highlightColor }
        }

        Repeater {
            model: root.procs
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                Text { text: modelData.pid; Layout.preferredWidth: 55; font.family: "monospace"; font.pixelSize: 11; color: Kirigami.Theme.textColor }
                Text { text: modelData.name; Layout.fillWidth: true; elide: Text.ElideRight; font.family: "monospace"; font.pixelSize: 11; color: Kirigami.Theme.textColor }
                Text { text: modelData.user; Layout.preferredWidth: 65; elide: Text.ElideRight; font.family: "monospace"; font.pixelSize: 11; color: Kirigami.Theme.textColor }
                Text { text: modelData.mem; Layout.preferredWidth: 45; horizontalAlignment: Text.AlignRight; font.family: "monospace"; font.pixelSize: 11; color: Kirigami.Theme.textColor }
                Text {
                    text: modelData.cpu
                    Layout.preferredWidth: 45
                    horizontalAlignment: Text.AlignRight
                    font.family: "monospace"
                    font.pixelSize: 11
                    font.bold: parseFloat(modelData.cpu) >= 20
                    color: parseFloat(modelData.cpu) >= 20 ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
