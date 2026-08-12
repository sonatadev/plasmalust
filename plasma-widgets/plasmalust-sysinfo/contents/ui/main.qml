import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Layout.preferredWidth: 500
    Layout.preferredHeight: 360

    property string osName: ""
    property string kernel: ""
    property string wm: ""
    property string shell: ""
    property string uptime: ""
    property real cpuPct: 0
    property real memPct: 0
    property real diskPct: 0
    property real batPct: -1
    property int reloadTick: 0

    RunCommand {
        id: runner
    }

    function refresh() {
        runner.exec("fastfetch --format json -s OS:Kernel:WM:Shell:Uptime:CPUUsage:Memory:Disk:Battery --logo none", function (stdout) {
            try {
                const parsed = JSON.parse(stdout);
                const map = {};
                for (const entry of parsed) {
                    if (entry.type && entry.result !== undefined) map[entry.type] = entry.result;
                }
                if (map.OS) root.osName = map.OS.name || map.OS.prettyName || "";
                if (map.Kernel) root.kernel = map.Kernel.release || "";
                if (map.WM) root.wm = map.WM.prettyName || map.WM.processName || "";
                if (map.Shell) root.shell = map.Shell.prettyName || "";
                if (map.Uptime && typeof map.Uptime.uptime === "number") {
                    const sec = map.Uptime.uptime / 1000;
                    const h = Math.floor(sec / 3600);
                    const m = Math.floor((sec % 3600) / 60);
                    root.uptime = h + "h " + m + "m";
                }
                if (Array.isArray(map.CPUUsage) && map.CPUUsage.length) {
                    root.cpuPct = map.CPUUsage.reduce((a, b) => a + b, 0) / map.CPUUsage.length;
                }
                if (map.Memory) {
                    root.memPct = (map.Memory.used / map.Memory.total) * 100;
                }
                if (Array.isArray(map.Disk) && map.Disk.length) {
                    root.diskPct = (map.Disk[0].bytes.used / map.Disk[0].bytes.total) * 100;
                }
                if (Array.isArray(map.Battery) && map.Battery.length) {
                    root.batPct = map.Battery[0].capacity;
                } else {
                    root.batPct = -1;
                }
            } catch (e) {
                console.log("plasmalust-sysinfo: parse error", e);
            }
        });
        root.reloadTick++;
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 20000
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

            ctx.shadowColor = Qt.rgba(accent.r, accent.g, accent.b, 0.55);
            ctx.shadowBlur = 10;

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
        anchors.margins: 26
        spacing: 16
        clip: true

        Rectangle {
            Layout.preferredWidth: 195
            Layout.preferredHeight: 240
            Layout.alignment: Qt.AlignTop
            border.color: Kirigami.Theme.highlightColor
            border.width: 1
            color: "transparent"

            Image {
                anchors.fill: parent
                anchors.margins: 3
                fillMode: Image.PreserveAspectCrop
                source: "file:///home/YOUR_USERNAME/.cache/wallust/portrait-dither.png?" + root.reloadTick
                cache: false
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            Text {
                text: root.osName || "..."
                font.family: "monospace"
                font.pixelSize: 15
                font.bold: true
                color: Kirigami.Theme.textColor
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.5)
            }

            InfoRow { label: "kernel"; value: root.kernel }
            InfoRow { label: "wm"; value: root.wm }
            InfoRow { label: "shell"; value: root.shell }
            InfoRow { label: "uptime"; value: root.uptime }

            Item { Layout.preferredHeight: 4 }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "cpu"; font.family: "monospace"; font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor; Layout.preferredWidth: 40 }
                    MeterBar { value: root.cpuPct; Layout.fillWidth: true }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "mem"; font.family: "monospace"; font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor; Layout.preferredWidth: 40 }
                    MeterBar { value: root.memPct; Layout.fillWidth: true }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "disk"; font.family: "monospace"; font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor; Layout.preferredWidth: 40 }
                    MeterBar { value: root.diskPct; Layout.fillWidth: true }
                }
                RowLayout {
                    Layout.fillWidth: true
                    visible: root.batPct >= 0
                    Text { text: "batt"; font.family: "monospace"; font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor; Layout.preferredWidth: 40 }
                    MeterBar { value: root.batPct; Layout.fillWidth: true }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
