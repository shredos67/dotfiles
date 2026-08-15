import QtQuick

Item {
    id: root

    property real from: 0
    property real to: 1
    property real value: 0.5
    property real stepSize: 0.05
    property bool hovered: pointer.containsMouse
    signal moved(real value)

    readonly property real ratio: to <= from ? 0
        : Math.max(0, Math.min(1, (value - from) / (to - from)))

    implicitWidth: 240
    implicitHeight: 30
    activeFocusOnTab: true

    function setFromPosition(position) {
        const ratio = Math.max(0, Math.min(1, position / width));
        const raw = from + ratio * (to - from);
        const stepped = stepSize > 0
            ? Math.round(raw / stepSize) * stepSize
            : raw;
        moved(Math.max(from, Math.min(to, stepped)));
    }

    function nudge(direction) {
        const amount = stepSize > 0 ? stepSize : (to - from) / 20;
        moved(Math.max(from, Math.min(to, value + amount * direction)));
    }

    Keys.onLeftPressed: nudge(-1)
    Keys.onRightPressed: nudge(1)

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 5
        radius: height / 2
        color: FloralSettings.withAlpha(Theme.panelHighlight, 0.9)
        border.width: 1
        border.color: Theme.frameBorderFaint

        Rectangle {
            width: parent.width * root.ratio
            height: parent.height
            radius: parent.radius
            color: FloralSettings.accentColor

            Behavior on width {
                NumberAnimation {
                    duration: pointer.pressed ? 0 : FloralSettings.duration(120)
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Rectangle {
        x: Math.max(0, Math.min(root.width - width,
            root.ratio * root.width - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: pointer.pressed ? 11 : root.hovered ? 13 : 11
        height: pointer.pressed ? 22 : root.hovered ? 24 : 22
        radius: width / 2
        color: Theme.moduleValue
        border.width: 2
        border.color: FloralSettings.accentColor

        Behavior on x {
            NumberAnimation {
                duration: pointer.pressed ? 0 : FloralSettings.duration(120)
                easing.type: Easing.OutCubic
            }
        }

        Behavior on width {
            NumberAnimation { duration: FloralSettings.duration(100) }
        }

        Behavior on height {
            NumberAnimation { duration: FloralSettings.duration(100) }
        }
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: event => root.setFromPosition(event.x)
        onPositionChanged: event => {
            if (pressed)
                root.setFromPosition(event.x);
        }
    }
}
