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
    Layout.preferredHeight: 190

    property string trackTitle: ""
    property string trackArtist: ""
    property string trackAlbum: ""
    property string playbackStatus: ""
    property string artUrl: ""
    property real positionUs: 0
    property real lengthUs: 0
    property bool hasPlayer: false

    RunCommand {
        id: runner
    }

    function fmtTime(us) {
        const totalSec = Math.floor(us / 1000000);
        const m = Math.floor(totalSec / 60);
        const s = totalSec % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    function refresh() {
        runner.exec("playerctl metadata --format '{{title}}::{{artist}}::{{album}}::{{status}}::{{position}}::{{mpris:length}}::{{mpris:artUrl}}'", function (stdout) {
            const line = (stdout || "").trim();
            if (!line) {
                root.hasPlayer = false;
                root.positionUs = 0;
                root.lengthUs = 0;
                return;
            }
            const parts = line.split("::");
            if (parts.length < 7) {
                root.hasPlayer = false;
                root.positionUs = 0;
                root.lengthUs = 0;
                return;
            }
            root.hasPlayer = true;
            root.trackTitle = parts[0];
            root.trackArtist = parts[1];
            root.trackAlbum = parts[2];
            root.playbackStatus = parts[3];
            root.positionUs = parseFloat(parts[4]) || 0;
            root.lengthUs = parseFloat(parts[5]) || 0;
            root.artUrl = parts[6];
        });
    }

    function control(action) {
        runner.exec("playerctl " + action, function () { root.refresh(); });
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 2000
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

    RowLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16
        clip: true

        Rectangle {
            Layout.preferredWidth: 130
            Layout.preferredHeight: 130
            Layout.alignment: Qt.AlignVCenter
            border.color: Kirigami.Theme.highlightColor
            border.width: 1
            color: "transparent"

            Image {
                anchors.fill: parent
                anchors.margins: 3
                fillMode: Image.PreserveAspectCrop
                source: root.artUrl
                visible: root.hasPlayer && root.artUrl !== ""
                asynchronous: true
            }

            Text {
                anchors.centerIn: parent
                visible: !root.hasPlayer || root.artUrl === ""
                text: "♫"
                font.pixelSize: 40
                color: Kirigami.Theme.highlightColor
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: root.hasPlayer ? root.trackTitle : "nothing playing"
                font.family: "monospace"
                font.pixelSize: 15
                font.bold: true
                color: Kirigami.Theme.textColor
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: root.hasPlayer
                text: root.trackArtist + (root.trackAlbum ? "  ·  " + root.trackAlbum : "")
                font.family: "monospace"
                font.pixelSize: 12
                color: Kirigami.Theme.highlightColor
                elide: Text.ElideRight
            }

            Item { Layout.preferredHeight: 4 }

            MeterBar {
                Layout.fillWidth: true
                visible: root.hasPlayer
                segments: 24
                value: root.lengthUs > 0 ? (root.positionUs / root.lengthUs * 100) : 0
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.hasPlayer
                Text {
                    text: root.fmtTime(root.positionUs)
                    font.family: "monospace"
                    font.pixelSize: 10
                    color: Kirigami.Theme.textColor
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.fmtTime(root.lengthUs)
                    font.family: "monospace"
                    font.pixelSize: 10
                    color: Kirigami.Theme.textColor
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 18

                Item { Layout.fillWidth: true }

                QQC2.Label {
                    text: "⏮"
                    font.pixelSize: 18
                    color: Kirigami.Theme.textColor
                    MouseArea { anchors.fill: parent; onClicked: root.control("previous") }
                }
                QQC2.Label {
                    text: root.playbackStatus === "Playing" ? "⏸" : "▶"
                    font.pixelSize: 18
                    color: Kirigami.Theme.highlightColor
                    MouseArea { anchors.fill: parent; onClicked: root.control("play-pause") }
                }
                QQC2.Label {
                    text: "⏭"
                    font.pixelSize: 18
                    color: Kirigami.Theme.textColor
                    MouseArea { anchors.fill: parent; onClicked: root.control("next") }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }
}
