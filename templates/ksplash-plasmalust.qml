import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: root
    color: "{{ background }}"

    property int stage
    readonly property color accent: "{{ color4 }}"
    readonly property color accent2: "{{ color5 }}"
    readonly property color fg: "{{ foreground }}"

    onStageChanged: {
        if (stage == 2) {
            introAnimation.running = true;
        } else if (stage == 5) {
            introAnimation.target = content;
            introAnimation.from = 1;
            introAnimation.to = 0;
            introAnimation.running = true;
        }
    }

    // Vignette - subtle radial darkening toward the edges, instead of a
    // flat fill, gives the whole screen some depth.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.lighter(root.color, 1.12) }
            GradientStop { position: 0.55; color: root.color }
            GradientStop { position: 1.0; color: Qt.darker(root.color, 1.35) }
        }
    }

    // Faint scattered stars for atmosphere - deterministic (seeded), so it
    // doesn't redraw differently between boot stages.
    Canvas {
        id: stars
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            let seed = 1337;
            function rand() {
                seed = (seed * 9301 + 49297) % 233280;
                return seed / 233280;
            }
            for (let i = 0; i < 70; i++) {
                const x = rand() * width;
                const y = rand() * height;
                const r = rand() * 1.4 + 0.3;
                ctx.beginPath();
                ctx.arc(x, y, r, 0, Math.PI * 2);
                ctx.fillStyle = Qt.rgba(root.fg.r, root.fg.g, root.fg.b, rand() * 0.35 + 0.08);
                ctx.fill();
            }
        }
        Component.onCompleted: requestPaint()
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        Canvas {
            id: frame
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const accent = root.accent;
                const m = 28, fl = 58;

                ctx.strokeStyle = accent;
                ctx.lineWidth = 2;
                function corner(x, y, dx, dy) {
                    ctx.beginPath();
                    ctx.moveTo(x, y + dy * fl);
                    ctx.lineTo(x, y);
                    ctx.lineTo(x + dx * fl, y);
                    ctx.stroke();

                    // tick marks along each arm
                    for (const t of [0.35, 0.65]) {
                        ctx.beginPath();
                        ctx.moveTo(x, y + dy * fl * t);
                        ctx.lineTo(x + dx * 6, y + dy * fl * t);
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.moveTo(x + dx * fl * t, y);
                        ctx.lineTo(x + dx * fl * t, y + dy * 6);
                        ctx.stroke();
                    }

                    ctx.beginPath();
                    ctx.arc(x, y + dy * fl, 3, 0, Math.PI * 2);
                    ctx.stroke();
                    ctx.beginPath();
                    ctx.arc(x + dx * fl, y, 3, 0, Math.PI * 2);
                    ctx.stroke();

                    const s = 14, cx = x + dx * s, cy = y + dy * s;
                    ctx.beginPath();
                    ctx.moveTo(cx, cy - 5);
                    ctx.lineTo(cx + 5, cy);
                    ctx.lineTo(cx, cy + 5);
                    ctx.lineTo(cx - 5, cy);
                    ctx.closePath();
                    ctx.fillStyle = accent;
                    ctx.fill();

                    ctx.beginPath();
                    ctx.arc(x + dx * 4, y + dy * 4, 1.6, 0, Math.PI * 2);
                    ctx.fillStyle = accent;
                    ctx.fill();
                }
                corner(m, m, 1, 1);
                corner(width - m, m, -1, 1);
                corner(m, height - m, 1, -1);
                corner(width - m, height - m, -1, -1);
            }
        }

        // Layered glow behind the portrait - poor-man's blur via stacked,
        // increasingly transparent rings, pulsing gently.
        Item {
            id: glow
            anchors.centerIn: portraitFrame
            width: portraitFrame.width
            height: portraitFrame.height

            Repeater {
                model: 4
                Rectangle {
                    anchors.centerIn: parent
                    width: glow.width + index * 16
                    height: glow.height + index * 16
                    radius: 6
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16 - index * 0.03)
                }
            }

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0.6; to: 1.0; duration: 1600; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.0; to: 0.6; duration: 1600; easing.type: Easing.InOutSine }
            }
        }

        // Magic: small runes/sparks slowly orbiting the portrait, each
        // twinkling on its own independent cycle.
        Item {
            id: orbitRoot
            anchors.centerIn: portraitFrame
            width: portraitFrame.width + 140
            height: portraitFrame.height + 140

            RotationAnimator on rotation {
                from: 0
                to: 360
                duration: 42000
                loops: Animation.Infinite
                running: Kirigami.Units.longDuration > 1
            }

            Repeater {
                model: [
                    { angle: 20,  radius: 0.52, kind: "diamond", size: 7,  color: root.accent },
                    { angle: 95,  radius: 0.58, kind: "ring",    size: 10, color: root.accent2 },
                    { angle: 165, radius: 0.50, kind: "spark",   size: 9,  color: root.fg },
                    { angle: 230, radius: 0.56, kind: "diamond", size: 5,  color: root.accent2 },
                    { angle: 285, radius: 0.60, kind: "spark",   size: 6,  color: root.accent },
                    { angle: 330, radius: 0.53, kind: "ring",    size: 6,  color: root.accent }
                ]

                Item {
                    id: orbitShape
                    required property var modelData
                    required property int index

                    readonly property real ang: modelData.angle * Math.PI / 180
                    x: orbitRoot.width / 2 + Math.cos(ang) * orbitRoot.width * modelData.radius - width / 2
                    y: orbitRoot.height / 2 + Math.sin(ang) * orbitRoot.height * modelData.radius - height / 2
                    width: modelData.size * 2
                    height: modelData.size * 2
                    // counter-rotate so the shape itself stays upright while orbitRoot spins
                    rotation: -orbitRoot.rotation

                    Canvas {
                        anchors.fill: parent
                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            const c = orbitShape.modelData.color;
                            const s = orbitShape.modelData.size;
                            const cx = width / 2, cy = height / 2;
                            ctx.fillStyle = c;
                            ctx.strokeStyle = c;
                            ctx.lineWidth = 1.4;

                            if (orbitShape.modelData.kind === "diamond") {
                                ctx.beginPath();
                                ctx.moveTo(cx, cy - s);
                                ctx.lineTo(cx + s, cy);
                                ctx.lineTo(cx, cy + s);
                                ctx.lineTo(cx - s, cy);
                                ctx.closePath();
                                ctx.fill();
                            } else if (orbitShape.modelData.kind === "ring") {
                                ctx.beginPath();
                                ctx.arc(cx, cy, s * 0.7, 0, Math.PI * 2);
                                ctx.stroke();
                            } else if (orbitShape.modelData.kind === "spark") {
                                ctx.beginPath();
                                ctx.moveTo(cx - s, cy); ctx.lineTo(cx + s, cy);
                                ctx.moveTo(cx, cy - s); ctx.lineTo(cx, cy + s);
                                ctx.stroke();
                            }
                        }
                        Component.onCompleted: requestPaint()
                    }

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        PauseAnimation { duration: orbitShape.index * 260 }
                        NumberAnimation { from: 0.15; to: 0.9; duration: 900 + orbitShape.index * 120; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.9; to: 0.15; duration: 900 + orbitShape.index * 120; easing.type: Easing.InOutSine }
                    }
                }
            }
        }

        Rectangle {
            id: portraitFrame
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -Kirigami.Units.gridUnit * 2
            width: 220
            height: width * (370 / 300)
            color: "transparent"
            border.color: root.accent
            border.width: 1

            Image {
                anchors.fill: parent
                anchors.margins: 3
                source: "images/portrait.png"
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: false
            }
        }

        Text {
            id: title
            anchors.top: portraitFrame.bottom
            anchors.topMargin: 22
            anchors.horizontalCenter: parent.horizontalCenter
            text: "plasmalust"
            font.family: "monospace"
            font.pixelSize: 17
            font.bold: true
            font.letterSpacing: 1
            color: root.fg
        }

        Rectangle {
            anchors.top: title.bottom
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            width: 90
            height: 1
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.5)
        }

        Canvas {
            id: spinner
            width: 30
            height: 30
            anchors.top: portraitFrame.bottom
            anchors.topMargin: 44
            anchors.horizontalCenter: parent.horizontalCenter
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.lineCap = "round";

                ctx.strokeStyle = Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22);
                ctx.lineWidth = 2;
                ctx.beginPath();
                ctx.arc(width / 2, height / 2, width / 2 - 2, 0, Math.PI * 2);
                ctx.stroke();

                ctx.strokeStyle = root.accent;
                ctx.lineWidth = 3;
                ctx.beginPath();
                ctx.arc(width / 2, height / 2, width / 2 - 2, 0, Math.PI * 1.4);
                ctx.stroke();

                ctx.strokeStyle = root.accent2;
                ctx.lineWidth = 1.5;
                ctx.beginPath();
                ctx.arc(width / 2, height / 2, width / 2 - 7, Math.PI, Math.PI * 2.1);
                ctx.stroke();
            }
            Component.onCompleted: requestPaint()

            RotationAnimator on rotation {
                from: 0
                to: 360
                duration: 1400
                loops: Animation.Infinite
                running: Kirigami.Units.longDuration > 1
            }
        }

        Text {
            id: statusText
            anchors.top: spinner.bottom
            anchors.topMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: "monospace"
            font.pixelSize: 11
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.55)

            readonly property var messages: [
                "waking up",
                "loading shaders",
                "summoning widgets",
                "tuning colors",
                "almost there"
            ]
            property int idx: 0
            text: messages[idx]

            Timer {
                interval: 850
                running: true
                repeat: true
                onTriggered: statusText.idx = (statusText.idx + 1) % statusText.messages.length
            }
        }
    }

    OpacityAnimator {
        id: introAnimation
        running: false
        target: content
        from: 0
        to: 1
        duration: Kirigami.Units.veryLongDuration * 2
        easing.type: Easing.InOutQuad
    }
}
