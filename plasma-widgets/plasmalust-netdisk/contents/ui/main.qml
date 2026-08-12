import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Layout.preferredWidth: 320
    Layout.preferredHeight: 170

    property string iface: ""
    property string disk: ""
    property bool ready: false

    property real prevRx: -1
    property real prevTx: -1
    property real prevRead: -1
    property real prevWrite: -1

    property string downSpeed: "--"
    property string upSpeed: "--"
    property string readSpeed: "--"
    property string writeSpeed: "--"

    readonly property int pollIntervalMs: 2000

    RunCommand {
        id: runner
    }

    function fmtRate(bytesPerSec) {
        if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + " b/s";
        if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(1) + " kb/s";
        return (bytesPerSec / (1024 * 1024)).toFixed(1) + " mb/s";
    }

    function detect() {
        const cmd = "IFACE=$(ip route show default | awk '{print $5; exit}'); " +
            "ROOT=$(findmnt -n -o SOURCE / | sed 's/\\[.*\\]//'); " +
            "DISK=$(lsblk -no pkname \"$ROOT\" 2>/dev/null); " +
            "echo \"$IFACE $DISK\"";
        runner.exec("bash -c " + shellQuote(cmd), function (stdout) {
            const parts = (stdout || "").trim().split(/\s+/);
            if (parts.length >= 2 && parts[0] && parts[1]) {
                root.iface = parts[0];
                root.disk = parts[1];
                root.ready = true;
                root.poll();
            }
        });
    }

    function shellQuote(s) {
        return "'" + s.replace(/'/g, "'\\''") + "'";
    }

    function poll() {
        if (!root.ready) return;
        const cmd = "echo $(cat /sys/class/net/" + root.iface + "/statistics/rx_bytes) " +
            "$(cat /sys/class/net/" + root.iface + "/statistics/tx_bytes) " +
            "$(awk -v d=" + root.disk + " '$3==d{print $6*512, $10*512}' /proc/diskstats)";
        runner.exec("bash -c " + shellQuote(cmd), function (stdout) {
            const parts = (stdout || "").trim().split(/\s+/).map(Number);
            if (parts.length < 4 || parts.some(isNaN)) return;
            const [rx, tx, rd, wr] = parts;
            const secs = root.pollIntervalMs / 1000;
            if (root.prevRx >= 0) {
                root.downSpeed = root.fmtRate(Math.max(0, rx - root.prevRx) / secs);
                root.upSpeed = root.fmtRate(Math.max(0, tx - root.prevTx) / secs);
                root.readSpeed = root.fmtRate(Math.max(0, rd - root.prevRead) / secs);
                root.writeSpeed = root.fmtRate(Math.max(0, wr - root.prevWrite) / secs);
            }
            root.prevRx = rx; root.prevTx = tx; root.prevRead = rd; root.prevWrite = wr;
        });
    }

    Component.onCompleted: detect()

    Timer {
        interval: root.pollIntervalMs
        running: true
        repeat: true
        onTriggered: root.poll()
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
        anchors.margins: 20
        spacing: 10

        Text {
            text: root.iface ? ("net/disk  ·  " + root.iface) : "net/disk"
            font.family: "monospace"
            font.pixelSize: 14
            font.bold: true
            color: Kirigami.Theme.textColor
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.bottomMargin: 2
            color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.4)
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 6
            columnSpacing: 18

            Text { text: "down"; font.family: "monospace"; font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor }
            Text { text: "up"; font.family: "monospace"; font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor }
            Text { text: root.downSpeed; font.family: "monospace"; font.pixelSize: 16; color: Kirigami.Theme.textColor }
            Text { text: root.upSpeed; font.family: "monospace"; font.pixelSize: 16; color: Kirigami.Theme.textColor }

            Text { text: "read"; font.family: "monospace"; font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor }
            Text { text: "write"; font.family: "monospace"; font.pixelSize: 11; font.bold: true; color: Kirigami.Theme.highlightColor }
            Text { text: root.readSpeed; font.family: "monospace"; font.pixelSize: 16; color: Kirigami.Theme.textColor }
            Text { text: root.writeSpeed; font.family: "monospace"; font.pixelSize: 16; color: Kirigami.Theme.textColor }
        }

        Item { Layout.fillHeight: true }
    }
}
