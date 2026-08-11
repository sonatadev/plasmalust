import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Rectangle {
    id: root
    // Bound to the actual screen size instead of a hardcoded 1920x1080 -
    // a fixed size that doesn't match the real window/screen gets scaled
    // to fit, which is what caused the "zoomed in" look.
    width: Screen.width
    height: Screen.height
    color: config.backgroundColor ? config.backgroundColor : "#151311"

    property color colorPrimary: config.primaryColor ? config.primaryColor : "#EBD4BD"
    property color colorAccent: config.accentColor ? config.accentColor : "#957B68"
    property color colorPanel: config.secondaryColor ? config.secondaryColor : "#292726"
    property color colorError: config.errorColor ? config.errorColor : "#F38BA8"

    // Every control below fully overrides background/contentItem instead of
    // relying on a QtQuick.Controls style - the SDDM greeter environment
    // doesn't reliably get Plasma's normal platform style applied, so the
    // default fallback rendering can look like plain unstyled widgets
    // ("HTML form with no CSS"). Overriding everything ourselves means the
    // look doesn't depend on which style Qt happens to auto-select there.
    property color fieldBackground: Qt.rgba(colorPrimary.r, colorPrimary.g, colorPrimary.b, 0.08)
    property color fieldBorder: Qt.rgba(colorPrimary.r, colorPrimary.g, colorPrimary.b, 0.25)

    Image {
        anchors.fill: parent
        source: config.background ? config.background : ""
        fillMode: Image.Stretch
        visible: source !== ""
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.3) }
            GradientStop { position: 0.55; color: Qt.rgba(0, 0, 0, 0.42) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.65) }
        }
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
                height: 40
                model: userModel
                textRole: "name"
                currentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0

                background: Rectangle {
                    radius: 8
                    color: root.fieldBackground
                    border.color: root.fieldBorder
                    border.width: 1
                }
                contentItem: Text {
                    text: userCombo.displayText
                    color: root.colorPrimary
                    font.pixelSize: 14
                    leftPadding: 12
                    verticalAlignment: Text.AlignVCenter
                }
                indicator: Text {
                    x: userCombo.width - width - 12
                    y: (userCombo.height - height) / 2
                    text: "▾"
                    color: root.colorPrimary
                }
                delegate: ItemDelegate {
                    width: userCombo.width
                    highlighted: userCombo.highlightedIndex === index
                    contentItem: Text {
                        text: name
                        color: root.colorPrimary
                        leftPadding: 12
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: highlighted ? Qt.rgba(root.colorAccent.r, root.colorAccent.g, root.colorAccent.b, 0.25) : "transparent"
                    }
                }
                popup: Popup {
                    y: userCombo.height + 4
                    width: userCombo.width
                    padding: 4
                    implicitHeight: contentItem.implicitHeight + 8

                    background: Rectangle {
                        radius: 8
                        color: root.colorPanel
                        border.color: root.fieldBorder
                        border.width: 1
                    }
                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: userCombo.popup.visible ? userCombo.delegateModel : null
                        currentIndex: userCombo.highlightedIndex
                    }
                }
            }

            TextField {
                id: passwordField
                Layout.fillWidth: true
                height: 40
                echoMode: TextInput.Password
                placeholderText: "Password"
                placeholderTextColor: Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.5)
                color: root.colorPrimary
                leftPadding: 12
                rightPadding: 12
                focus: true
                onAccepted: sddm.login(userCombo.currentText, passwordField.text, sessionCombo.currentIndex)

                background: Rectangle {
                    radius: 8
                    color: root.fieldBackground
                    border.color: root.fieldBorder
                    border.width: 1
                }
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
                    height: 40
                    model: sessionModel
                    textRole: "name"
                    currentIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0

                    background: Rectangle {
                        radius: 8
                        color: root.fieldBackground
                        border.color: root.fieldBorder
                        border.width: 1
                    }
                    contentItem: Text {
                        text: sessionCombo.displayText
                        color: root.colorPrimary
                        font.pixelSize: 13
                        leftPadding: 10
                        verticalAlignment: Text.AlignVCenter
                    }
                    indicator: Text {
                        x: sessionCombo.width - width - 10
                        y: (sessionCombo.height - height) / 2
                        text: "▾"
                        color: root.colorPrimary
                    }
                    delegate: ItemDelegate {
                        width: sessionCombo.width
                        highlighted: sessionCombo.highlightedIndex === index
                        contentItem: Text {
                            text: name
                            color: root.colorPrimary
                            leftPadding: 10
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: highlighted ? Qt.rgba(root.colorAccent.r, root.colorAccent.g, root.colorAccent.b, 0.25) : "transparent"
                        }
                    }
                    popup: Popup {
                        y: sessionCombo.height + 4
                        width: sessionCombo.width
                        padding: 4
                        implicitHeight: contentItem.implicitHeight + 8

                        background: Rectangle {
                            radius: 8
                            color: root.colorPanel
                            border.color: root.fieldBorder
                            border.width: 1
                        }
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: sessionCombo.popup.visible ? sessionCombo.delegateModel : null
                            currentIndex: sessionCombo.highlightedIndex
                        }
                    }
                }

                Button {
                    id: loginButton
                    text: "Login"
                    onClicked: sddm.login(userCombo.currentText, passwordField.text, sessionCombo.currentIndex)

                    background: Rectangle {
                        radius: 8
                        color: loginButton.down ? Qt.darker(root.colorAccent, 1.2) : root.colorAccent
                    }
                    contentItem: Text {
                        text: loginButton.text
                        color: root.colorPanel
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                Button {
                    id: rebootButton
                    text: "Reboot"
                    visible: sddm.canReboot
                    onClicked: sddm.reboot()

                    background: Rectangle {
                        radius: 8
                        color: rebootButton.down ? root.fieldBorder : root.fieldBackground
                        border.color: root.fieldBorder
                        border.width: 1
                    }
                    contentItem: Text {
                        text: rebootButton.text
                        color: root.colorPrimary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                Button {
                    id: shutdownButton
                    text: "Shutdown"
                    visible: sddm.canPowerOff
                    onClicked: sddm.powerOff()

                    background: Rectangle {
                        radius: 8
                        color: shutdownButton.down ? root.fieldBorder : root.fieldBackground
                        border.color: root.fieldBorder
                        border.width: 1
                    }
                    contentItem: Text {
                        text: shutdownButton.text
                        color: root.colorPrimary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
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
