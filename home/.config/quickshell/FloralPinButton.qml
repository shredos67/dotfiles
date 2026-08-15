import QtQuick

Item {
    id: root

    property bool pinned: false
    property bool hovered: pointer.containsMouse
    signal clicked

    implicitWidth: ShellConfig.scaled(32)
    implicitHeight: ShellConfig.scaled(32)
    scale: pointer.pressed ? 0.9 : hovered ? 1.05 : 1

    Rectangle {
        anchors.fill: parent
        radius: ShellConfig.visuals.controlRadius
        color: root.pinned
            ? FloralSettings.withAlpha(FloralSettings.accentColor, 0.2)
            : root.hovered
                ? FloralSettings.elevatedColor
                : "transparent"
        border.width: root.pinned || root.hovered
            ? ShellConfig.bar.hairlineThickness
            : 0
        border.color: root.pinned
            ? FloralSettings.accentColor
            : Theme.frameBorderFaint

        Behavior on color {
            ColorAnimation { duration: FloralSettings.duration(120) }
        }
    }

    Item {
        id: pin

        anchors.centerIn: parent
        width: ShellConfig.scaled(16)
        height: ShellConfig.scaled(19)
        rotation: -38

        Rectangle {
            id: pinHead

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
            }
            width: ShellConfig.scaled(12)
            height: ShellConfig.scaled(7)
            radius: height / 2
            color: root.pinned
                ? FloralSettings.accentColor
                : "transparent"
            border.width: ShellConfig.bar.hairlineThickness
            border.color: root.pinned
                ? FloralSettings.accentColor
                : root.hovered
                    ? Theme.moduleValue
                    : Theme.textMuted
        }

        Rectangle {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: pinHead.bottom
            }
            width: ShellConfig.scaled(2)
            height: ShellConfig.scaled(9)
            radius: width / 2
            color: root.pinned || root.hovered
                ? FloralSettings.accentColor
                : Theme.textMuted
        }

        Rectangle {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: pinHead.bottom
                topMargin: ShellConfig.scaled(7)
            }
            width: ShellConfig.scaled(4)
            height: width
            rotation: 45
            color: root.pinned || root.hovered
                ? FloralSettings.accentColor
                : Theme.textMuted
        }

        Behavior on rotation {
            NumberAnimation {
                duration: FloralSettings.duration(180)
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.top
            bottomMargin: ShellConfig.scaled(7)
        }
        width: label.implicitWidth + ShellConfig.scaled(14)
        height: ShellConfig.scaled(25)
        radius: ShellConfig.scaled(8)
        color: FloralSettings.elevatedColor
        border.width: ShellConfig.bar.hairlineThickness
        border.color: Theme.frameBorderFaint
        opacity: root.hovered ? 1 : 0
        scale: root.hovered ? 1 : 0.92
        visible: opacity > 0
        z: 10

        Text {
            id: label

            anchors.centerIn: parent
            text: root.pinned ? "unpin" : "pin"
            color: Theme.moduleValue
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                styleName: ShellConfig.typography.fineStyle
                pixelSize: ShellConfig.scaled(10)
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: FloralSettings.duration(100) }
        }

        Behavior on scale {
            NumberAnimation {
                duration: FloralSettings.duration(140)
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Behavior on scale {
        NumberAnimation {
            duration: FloralSettings.duration(130)
            easing.type: Easing.OutCubic
        }
    }
}
