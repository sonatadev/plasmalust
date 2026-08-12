import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: meter
    property real value: 0
    property int segments: 14
    implicitHeight: 8

    Row {
        anchors.fill: parent
        spacing: 3
        Repeater {
            model: meter.segments
            delegate: Rectangle {
                required property int index
                width: (meter.width - (meter.segments - 1) * 3) / meter.segments
                height: parent.height
                radius: 1
                color: (index / meter.segments * 100) < meter.value
                    ? Kirigami.Theme.highlightColor
                    : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.16)
            }
        }
    }
}
