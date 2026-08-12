import QtQuick

Item {
    id: root
    property string kind: "play" // play, pause, previous, next
    property color iconColor: "white"
    signal clicked()

    width: 20
    height: 20

    onIconColorChanged: canvas.requestPaint()
    onKindChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = root.iconColor;
            const w = width, h = height, cx = w / 2, cy = h / 2;

            function triangle(x, y, size, dir) {
                ctx.beginPath();
                if (dir > 0) {
                    ctx.moveTo(x - size / 2, y - size / 2);
                    ctx.lineTo(x - size / 2, y + size / 2);
                    ctx.lineTo(x + size / 2, y);
                } else {
                    ctx.moveTo(x + size / 2, y - size / 2);
                    ctx.lineTo(x + size / 2, y + size / 2);
                    ctx.lineTo(x - size / 2, y);
                }
                ctx.closePath();
                ctx.fill();
            }

            const barW = w * 0.13, barH = h * 0.52;

            if (root.kind === "play") {
                triangle(cx + w * 0.02, cy, w * 0.55, 1);
            } else if (root.kind === "pause") {
                const gap = w * 0.12;
                ctx.fillRect(cx - gap - barW, cy - barH / 2, barW, barH);
                ctx.fillRect(cx + gap, cy - barH / 2, barW, barH);
            } else if (root.kind === "previous") {
                ctx.fillRect(cx - w * 0.34, cy - barH / 2, barW, barH);
                triangle(cx + w * 0.1, cy, w * 0.45, -1);
            } else if (root.kind === "next") {
                triangle(cx - w * 0.1, cy, w * 0.45, 1);
                ctx.fillRect(cx + w * 0.34 - barW, cy - barH / 2, barW, barH);
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
