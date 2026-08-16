import QtQuick

Item {
    id: root

    required property string title
    property string detail: ""
    property string glyphKind: "overview"
    property int glyphSource: 0
    property bool selected: false
    property bool available: true
    property bool dangerous: false
    property bool compact: false
    signal clicked

    readonly property bool hovered: pointer.containsMouse
    readonly property color accent: dangerous
        ? Theme.statusDanger
        : FloralSettings.accentColor

    implicitHeight: compact ? 50 : 66
    opacity: available ? 1 : 0.42
    scale: pointer.pressed ? 0.975 : hovered ? 1.008 : 1

    Rectangle {
        anchors.fill: parent
        radius: Math.max(9, FloralSettings.popupRadius)
        color: root.selected
            ? FloralSettings.withAlpha(root.accent, 0.17)
            : root.hovered && root.available
                ? FloralSettings.elevatedColor
                : FloralSettings.withAlpha(Theme.panelRaised, 0.52)
        border.width: root.selected || root.hovered ? 1.5 : 1
        border.color: root.selected || root.hovered
            ? FloralSettings.withAlpha(root.accent, 0.82)
            : Theme.frameBorderFaint

        Behavior on color {
            ColorAnimation {
                duration: FloralSettings.duration(120)
                easing.type: Easing.InOutCubic
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: FloralSettings.duration(120)
                easing.type: Easing.InOutCubic
            }
        }
    }

    Rectangle {
        anchors {
            left: parent.left
            leftMargin: root.compact ? 12 : 14
            verticalCenter: parent.verticalCenter
        }
        width: root.compact ? 30 : 36
        height: width
        radius: Math.max(8, FloralSettings.popupRadius * 0.74)
        color: FloralSettings.withAlpha(root.accent,
            root.selected || root.hovered ? 0.20 : 0.10)
        border.width: 1
        border.color: FloralSettings.withAlpha(root.accent,
            root.selected || root.hovered ? 0.64 : 0.28)

        FloralDashboardGlyph {
            visible: root.glyphSource === 0
            anchors.centerIn: parent
            width: parent.width * 0.52
            height: width
            kind: root.glyphKind
            active: root.selected
            color: root.selected || root.hovered
                ? root.accent : Theme.moduleValue
        }

        FloralGlyph {
            visible: root.glyphSource === 1
            anchors.centerIn: parent
            width: parent.width * 0.52
            height: width
            kind: root.glyphKind
            active: root.selected
            color: root.selected || root.hovered
                ? root.accent : Theme.moduleValue
        }

        FloralSystemGlyph {
            visible: root.glyphSource === 2
            anchors.centerIn: parent
            width: parent.width * 0.54
            height: width
            kind: root.glyphKind
            color: root.selected || root.hovered
                ? root.accent : Theme.moduleValue
        }
    }

    Text {
        id: titleText

        anchors {
            left: parent.left
            leftMargin: root.compact ? 54 : 62
            right: parent.right
            rightMargin: 12
        }
        y: root.detail.length ? 11 : (root.height - height) / 2
        text: root.title
        color: root.dangerous && root.hovered
            ? Theme.statusDanger : Theme.moduleValue
        elide: Text.ElideRight
        renderType: Text.NativeRendering
        font {
            family: ShellConfig.typography.monoFamily
            styleName: ShellConfig.typography.fineStyle
            pixelSize: root.compact ? 13 : 14
            weight: Font.DemiBold
        }
    }

    Text {
        visible: root.detail.length > 0
        anchors {
            left: parent.left
            leftMargin: 62
            right: parent.right
            rightMargin: 12
            bottom: parent.bottom
            bottomMargin: 10
        }
        text: root.detail
        color: Theme.textMuted
        elide: Text.ElideRight
        renderType: Text.NativeRendering
        font {
            family: ShellConfig.typography.monoFamily
            styleName: ShellConfig.typography.fineStyle
            pixelSize: 11
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
            duration: FloralSettings.duration(100)
            easing.type: Easing.OutCubic
        }
    }
}
