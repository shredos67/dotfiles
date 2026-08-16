import QtQuick
import QtQuick.Shapes

Item {
    id: root

    required property string kind
    property bool available: true
    property bool playing: false
    property bool prominent: false
    signal clicked

    implicitWidth: prominent ? 54 : 44
    implicitHeight: implicitWidth
    opacity: available ? 1 : 0.34
    scale: pointer.pressed ? 0.92 : pointer.containsMouse ? 1.045 : 1

    Rectangle {
        anchors.fill: parent
        radius: Math.max(11, FloralSettings.popupRadius)
        color: pointer.containsMouse
            ? FloralSettings.withAlpha(FloralSettings.accentColor, 0.19)
            : root.prominent
                ? FloralSettings.withAlpha(Theme.panelHighlight, 0.76)
                : FloralSettings.withAlpha(Theme.panelRaised, 0.52)
        border.width: root.prominent || pointer.containsMouse ? 1.5 : 1
        border.color: pointer.containsMouse
            ? FloralSettings.accentColor : Theme.frameBorderFaint
    }

    Item {
        id: mark

        anchors.centerIn: parent
        width: root.prominent ? 18 : 15
        height: width

        Shape {
            anchors.fill: parent
            visible: root.kind === "previous" || root.kind === "next"
            antialiasing: true

            ShapePath {
                fillColor: Theme.moduleValue
                strokeWidth: 0
                startX: root.kind === "previous" ? mark.width - 1 : 1
                startY: 1
                PathLine {
                    x: root.kind === "previous" ? 3 : mark.width - 3
                    y: mark.height / 2
                }
                PathLine {
                    x: root.kind === "previous" ? mark.width - 1 : 1
                    y: mark.height - 1
                }
                PathLine {
                    x: root.kind === "previous" ? mark.width - 1 : 1
                    y: 1
                }
            }
        }

        Rectangle {
            visible: root.kind === "previous" || root.kind === "next"
            x: root.kind === "previous" ? 1 : mark.width - width - 1
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: mark.height - 2
            radius: 1
            color: Theme.moduleValue
        }

        Shape {
            anchors.fill: parent
            visible: root.kind === "toggle" && !root.playing
            antialiasing: true

            ShapePath {
                fillColor: Theme.moduleValue
                strokeWidth: 0
                startX: 2
                startY: 1
                PathLine { x: mark.width - 1; y: mark.height / 2 }
                PathLine { x: 2; y: mark.height - 1 }
                PathLine { x: 2; y: 1 }
            }
        }

        Item {
            anchors.fill: parent
            visible: root.kind === "toggle" && root.playing

            Rectangle {
                anchors {
                    left: parent.left
                    leftMargin: 3
                    verticalCenter: parent.verticalCenter
                }
                width: 3
                height: parent.height - 2
                radius: 1.5
                color: Theme.moduleValue
            }

            Rectangle {
                anchors {
                    right: parent.right
                    rightMargin: 3
                    verticalCenter: parent.verticalCenter
                }
                width: 3
                height: parent.height - 2
                radius: 1.5
                color: Theme.moduleValue
            }
        }
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        enabled: root.available
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }

    Behavior on scale {
        NumberAnimation {
            duration: FloralSettings.duration(110)
            easing.type: Easing.OutCubic
        }
    }
}
