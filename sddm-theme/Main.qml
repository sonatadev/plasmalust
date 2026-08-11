import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Rectangle {
    id: root
    // Bound to the actual screen size instead of a hardcoded 1920x1080 -
    // a fixed size that doesn't match the real window/screen gets scaled
    // to fit, which is what caused an earlier "zoomed in" look.
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
        y: root.height * 0.12
        color: root.colorPrimary
        font.pixelSize: 68

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
        opacity: 0.75
        font.pixelSize: 20
        text: Qt.formatDate(new Date(), "dddd, MMMM d")
    }

    // No boxed "form panel" - elements float directly over the darkened
    // wallpaper instead, which is what made the previous version look like
    // a generic web form rather than a lock screen.
    ColumnLayout {
        id: loginColumn
        width: 340
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.height * 0.06
        spacing: 10

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 120
            height: 120
            radius: 60
            color: root.colorAccent

            Text {
                anchors.centerIn: parent
                text: userCombo.currentText.length > 0 ? userCombo.currentText.charAt(0).toUpperCase() : "?"
                font.pixelSize: 44
                color: root.colorPanel
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            text: userCombo.currentText
            color: root.colorPrimary
            font.pixelSize: 22
            font.bold: true
        }

        // Only shown if there's actually more than one user - otherwise
        // this would just be a pointless dropdown always sitting there for
        // the overwhelmingly common single-user case.
        ComboBox {
            id: userCombo
            Layout.alignment: Qt.AlignHCenter
            visible: userModel.count > 1
            implicitHeight: 24
            model: userModel
            textRole: "name"
            currentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0

            background: Item {}
            contentItem: Text {
                text: "Switch user ▾"
                color: root.colorPrimary
                opacity: 0.65
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
            }
            indicator: Item {}
            delegate: ItemDelegate {
                width: 200
                height: 40
                highlighted: userCombo.highlightedIndex === index
                contentItem: Text {
                    text: name
                    color: root.colorPrimary
                    font.pixelSize: 15
                    leftPadding: 14
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: highlighted ? Qt.rgba(root.colorAccent.r, root.colorAccent.g, root.colorAccent.b, 0.25) : "transparent"
                }
            }
            popup: Popup {
                y: userCombo.height + 4
                x: (userCombo.width - width) / 2
                width: 200
                padding: 4
                implicitHeight: contentItem.implicitHeight + 8

                background: Rectangle {
                    radius: 10
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

        // Password field with an inline circular submit button, instead of
        // a separate "Login" button crammed into the same row as the
        // session picker.
        Item {
            Layout.fillWidth: true
            Layout.topMargin: 18
            Layout.preferredHeight: 56

            TextField {
                id: passwordField
                anchors.fill: parent
                font.pixelSize: 17
                echoMode: TextInput.Password
                placeholderText: "Password"
                placeholderTextColor: Qt.rgba(root.colorPrimary.r, root.colorPrimary.g, root.colorPrimary.b, 0.5)
                color: root.colorPrimary
                leftPadding: 20
                rightPadding: 56
                focus: true
                onAccepted: sddm.login(userCombo.currentText, passwordField.text, sessionCombo.currentIndex)

                background: Rectangle {
                    radius: height / 2
                    color: root.fieldBackground
                    border.color: root.fieldBorder
                    border.width: 1
                }
            }

            Button {
                id: submitButton
                width: 40
                height: 40
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                onClicked: sddm.login(userCombo.currentText, passwordField.text, sessionCombo.currentIndex)

                background: Rectangle {
                    radius: 20
                    color: submitButton.down ? Qt.darker(root.colorAccent, 1.2) : root.colorAccent
                }
                contentItem: Text {
                    text: "→"
                    color: root.colorPanel
                    font.pixelSize: 20
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Text {
            id: errorText
            Layout.fillWidth: true
            Layout.topMargin: 4
            color: root.colorError
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            visible: text.length > 0
            wrapMode: Text.WordWrap
        }

        // Subtle, de-emphasized - most people never touch this, so it
        // shouldn't compete visually with the password field.
        ComboBox {
            id: sessionCombo
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            implicitHeight: 24
            model: sessionModel
            textRole: "name"
            currentIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0

            background: Item {}
            contentItem: Text {
                text: sessionCombo.displayText + "  ▾"
                color: root.colorPrimary
                opacity: 0.65
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
            }
            indicator: Item {}
            delegate: ItemDelegate {
                width: 200
                height: 40
                highlighted: sessionCombo.highlightedIndex === index
                contentItem: Text {
                    text: name
                    color: root.colorPrimary
                    font.pixelSize: 15
                    leftPadding: 14
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: highlighted ? Qt.rgba(root.colorAccent.r, root.colorAccent.g, root.colorAccent.b, 0.25) : "transparent"
                }
            }
            popup: Popup {
                y: sessionCombo.height + 4
                x: (sessionCombo.width - width) / 2
                width: 200
                padding: 4
                implicitHeight: contentItem.implicitHeight + 8

                background: Rectangle {
                    radius: 10
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
    }

    // Power controls tucked in a screen corner, detached from the login
    // form entirely - a cleaner, more common modern-lock-screen convention
    // than cramming them into the same card as the password field.
    RowLayout {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 12

        Button {
            id: rebootButton
            text: "Reboot"
            height: 36
            visible: sddm.canReboot
            onClicked: sddm.reboot()

            background: Rectangle {
                radius: 18
                color: rebootButton.down ? root.fieldBorder : root.fieldBackground
                border.color: root.fieldBorder
                border.width: 1
            }
            contentItem: Text {
                text: rebootButton.text
                color: root.colorPrimary
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                leftPadding: 10
                rightPadding: 10
            }
        }
        Button {
            id: shutdownButton
            text: "Shutdown"
            height: 36
            visible: sddm.canPowerOff
            onClicked: sddm.powerOff()

            background: Rectangle {
                radius: 18
                color: shutdownButton.down ? root.fieldBorder : root.fieldBackground
                border.color: root.fieldBorder
                border.width: 1
            }
            contentItem: Text {
                text: shutdownButton.text
                color: root.colorPrimary
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                leftPadding: 10
                rightPadding: 10
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
