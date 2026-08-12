import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

RowLayout {
    id: row
    property string label: ""
    property string value: ""
    Layout.fillWidth: true
    spacing: 8

    Text {
        text: row.label
        font.family: "monospace"
        font.pixelSize: 12
        font.bold: true
        color: Kirigami.Theme.highlightColor
        Layout.preferredWidth: 76
    }
    Text {
        text: row.value
        font.family: "monospace"
        font.pixelSize: 12
        color: Kirigami.Theme.textColor
        elide: Text.ElideRight
        Layout.fillWidth: true
    }
}
