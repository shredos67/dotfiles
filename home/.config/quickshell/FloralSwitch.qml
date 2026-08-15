import QtQuick

Item {
    id: root

    property bool checked: false
    property bool hovered: pointer.containsMouse
    signal toggled(bool checked)

    implicitWidth: 54
    implicitHeight: 30
    activeFocusOnTab: true

    function flip() {
        toggled(!checked);
    }

    Keys.onSpacePressed: flip()
    Keys.onReturnPressed: flip()

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked
            ? FloralSettings.withAlpha(FloralSettings.accentColor, 0.27)
            : FloralSettings.withAlpha(Theme.panelHighlight, 0.84)
        border.width: 1
        border.color: root.checked
            ? FloralSettings.withAlpha(FloralSettings.accentColor, 0.84)
            : Theme.frameBorderFaint

        Behavior on color {
            ColorAnimation { duration: FloralSettings.duration(150) }
        }

        Behavior on border.color {
            ColorAnimation { duration: FloralSettings.duration(150) }
        }
    }

    Rectangle {
        id: handle

        x: root.checked ? root.width - width - 5 : 5
        anchors.verticalCenter: parent.verticalCenter
        width: 20
        height: 20
        radius: 10
        color: root.checked ? FloralSettings.accentColor : Theme.textMuted
        scale: pointer.pressed ? 0.88 : root.hovered ? 1.08 : 1

        Rectangle {
            anchors.centerIn: parent
            width: 6
            height: 6
            radius: 3
            color: Theme.panel
            opacity: root.checked ? 0.9 : 0.55
        }

        Behavior on x {
            NumberAnimation {
                duration: FloralSettings.duration(190)
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: FloralSettings.duration(120)
                easing.type: Easing.OutCubic
            }
        }

        Behavior on color {
            ColorAnimation { duration: FloralSettings.duration(150) }
        }
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.flip()
    }
}
