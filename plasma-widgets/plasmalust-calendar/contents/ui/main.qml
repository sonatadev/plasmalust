import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Layout.preferredWidth: 320
    Layout.preferredHeight: 320

    property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()

    readonly property var monthNames: ["january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december"]
    readonly property var dayLetters: ["mo", "tu", "we", "th", "fr", "sa", "su"]

    readonly property var cells: {
        const first = new Date(viewYear, viewMonth, 1);
        // Monday-first weekday index (0=Mon..6=Sun)
        const startOffset = (first.getDay() + 6) % 7;
        const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate();
        const list = [];
        for (let i = 0; i < startOffset; i++) list.push(null);
        for (let d = 1; d <= daysInMonth; d++) list.push(d);
        while (list.length % 7 !== 0 || list.length < 42) list.push(null);
        return list;
    }

    function isToday(d) {
        return d === today.getDate() && viewMonth === today.getMonth() && viewYear === today.getFullYear();
    }

    function prevMonth() {
        if (viewMonth === 0) { viewMonth = 11; viewYear -= 1; } else { viewMonth -= 1; }
    }
    function nextMonth() {
        if (viewMonth === 11) { viewMonth = 0; viewYear += 1; } else { viewMonth += 1; }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.today = new Date()
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
                ctx.arc(x, y + dy * fl, 2.5, 0, Math.PI * 2);
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(x + dx * fl, y, 2.5, 0, Math.PI * 2);
                ctx.stroke();

                const s = 8, cx = x + dx * s, cy = y + dy * s;
                ctx.beginPath();
                ctx.moveTo(cx, cy - 3.5);
                ctx.lineTo(cx + 3.5, cy);
                ctx.lineTo(cx, cy + 3.5);
                ctx.lineTo(cx - 3.5, cy);
                ctx.closePath();
                ctx.fillStyle = accent;
                ctx.fill();

                ctx.beginPath();
                ctx.arc(x + dx * 3, y + dy * 3, 1.8, 0, Math.PI * 2);
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
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "‹"
                font.pixelSize: 18
                font.bold: true
                color: Kirigami.Theme.highlightColor
                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: root.prevMonth() }
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.monthNames[root.viewMonth] + " " + root.viewYear
                font.family: "monospace"
                font.pixelSize: 15
                font.bold: true
                color: Kirigami.Theme.textColor
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "›"
                font.pixelSize: 18
                font.bold: true
                color: Kirigami.Theme.highlightColor
                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: root.nextMonth() }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.4)
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 4
            columnSpacing: 2

            Repeater {
                model: root.dayLetters
                delegate: Text {
                    required property string modelData
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.family: "monospace"
                    font.pixelSize: 11
                    font.bold: true
                    color: Kirigami.Theme.highlightColor
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            rowSpacing: 2
            columnSpacing: 2

            Repeater {
                model: root.cells
                delegate: Item {
                    id: cell
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        radius: 12
                        visible: cell.modelData !== null
                        color: root.isToday(cell.modelData)
                            ? Kirigami.Theme.highlightColor
                            : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: cell.modelData || ""
                            font.family: "monospace"
                            font.pixelSize: 12
                            font.bold: root.isToday(cell.modelData)
                            color: root.isToday(cell.modelData)
                                ? Kirigami.Theme.backgroundColor
                                : Kirigami.Theme.textColor
                        }
                    }
                }
            }
        }
    }
}
