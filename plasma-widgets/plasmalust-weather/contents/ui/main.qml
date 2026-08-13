import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Layout.preferredWidth: 320
    Layout.preferredHeight: 190

    property string place: "..."
    property string tempC: "--"
    property string feelsC: "--"
    property string humidity: "--"
    property string windKmph: "--"
    property string desc: "loading..."
    property bool hasData: false

    RunCommand {
        id: runner
    }

    function refresh() {
        runner.exec("curl -s --max-time 8 'wttr.in/?format=j1'", function (stdout) {
            try {
                const data = JSON.parse(stdout);
                const cc = data.current_condition[0];
                root.place = data.nearest_area[0].areaName[0].value;
                root.tempC = cc.temp_C;
                root.feelsC = cc.FeelsLikeC;
                root.humidity = cc.humidity;
                root.windKmph = cc.windspeedKmph;
                root.desc = cc.weatherDesc[0].value.toLowerCase();
                root.hasData = true;
            } catch (e) {
                root.hasData = false;
            }
        });
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 30 * 60 * 1000
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
        spacing: 6

        Text {
            text: root.place
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

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Text {
                text: root.hasData ? (root.tempC + "°c") : "--"
                font.family: "monospace"
                font.pixelSize: 38
                font.bold: true
                color: Kirigami.Theme.highlightColor
            }
            ColumnLayout {
                spacing: 2
                Text {
                    text: root.desc
                    font.family: "monospace"
                    font.pixelSize: 12
                    color: Kirigami.Theme.textColor
                }
                Text {
                    text: "feels " + root.feelsC + "°c"
                    font.family: "monospace"
                    font.pixelSize: 11
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.7)
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 20
            Text {
                text: "humid  " + root.humidity + "%"
                font.family: "monospace"
                font.pixelSize: 11
                color: Kirigami.Theme.highlightColor
            }
            Text {
                text: "wind  " + root.windKmph + "km/h"
                font.family: "monospace"
                font.pixelSize: 11
                color: Kirigami.Theme.highlightColor
            }
        }
    }
}
