import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: config.backgroundColor ? config.backgroundColor : "#151311"

    property color colorPrimary: config.primaryColor ? config.primaryColor : "#EBD4BD"
    property color colorAccent: config.accentColor ? config.accentColor : "#957B68"
    property color colorPanel: config.secondaryColor ? config.secondaryColor : "#292726"
    property color colorError: config.errorColor ? config.errorColor : "#F38BA8"

    Image {
        anchors.fill: parent
        source: config.background ? config.background : ""
        fillMode: Image.PreserveAspectCrop
        visible: source !== ""
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.35
    }

    Text {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height * 0.14
        color: root.colorPrimary
        font.pixelSize: 64

        function refresh() { text = Qt.formatTime(new Date(), "hh:mm") }
        Component.onCompleted: refresh()

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clock.refresh()
        }
    }

    Text {
        anchors.top: clock.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        color: root.colorPrimary
        opacity: 0.8
        font.pixelSize: 20
        text: Qt.formatDate(new Date(), "dddd, MMMM d")
    }

    Rectangle {
        id: loginPanel
        width: 340
        height: loginColumn.implicitHeight + 48
        radius: 16
        anchors.centerIn: parent
        color: Qt.rgba(root.colorPanel.r, root.colorPanel.g, root.colorPanel.b, 0.85)

        ColumnLayout {
            id: loginColumn
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 72
                height: 72
                radius: 36
                color: root.colorAccent

                Text {
                    anchors.centerIn: parent
                    text: userCombo.currentText.length > 0 ? userCombo.currentText.charAt(0).toUpperCase() : "?"
                    font.pixelSize: 28
                    color: root.colorPanel
                }
            }

            ComboBox {
                id: userCombo
                Layout.fillWidth: true
                model: userModel
                textRole: "name"
                currentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
            }

            TextField {
                id: passwordField
                Layout.fillWidth: true
                echoMode: TextInput.Password
                placeholderText: "Password"
                focus: true
                onAccepted: sddm.login(userCombo.currentText, passwordField.text, sessionCombo.currentIndex)
            }

            Text {
                id: errorText
                Layout.fillWidth: true
                color: root.colorError
                visible: text.length > 0
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true

                ComboBox {
                    id: sessionCombo
                    Layout.fillWidth: true
                    model: sessionModel
                    textRole: "name"
                    currentIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
                }

                Button {
                    text: "Login"
                    onClicked: sddm.login(userCombo.currentText, passwordField.text, sessionCombo.currentIndex)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                Button {
                    text: "Reboot"
                    visible: sddm.canReboot
                    onClicked: sddm.reboot()
                }
                Button {
                    text: "Shutdown"
                    visible: sddm.canPowerOff
                    onClicked: sddm.powerOff()
                }
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorText.text = "Login failed"
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
    }

    Component.onCompleted: passwordField.forceActiveFocus()
}
