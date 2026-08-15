import QtQuick

Rectangle {
    id: root

    property alias text: field.text
    property string placeholderText: ""
    property bool password: false
    signal accepted

    implicitHeight: 46
    radius: 11
    color: Theme.panelRaised
    border.width: field.activeFocus ? 2 : 1
    border.color: field.activeFocus
        ? FloralSettings.accentColor
        : Theme.frameBorderFaint

    function takeFocus() {
        field.forceActiveFocus();
    }

    TextInput {
        id: field

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 15
            rightMargin: 15
        }
        color: Theme.moduleValue
        selectionColor: FloralSettings.accentColor
        selectedTextColor: Theme.panel
        clip: true
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        passwordCharacter: "•"
        renderType: Text.NativeRendering
        font {
            family: ShellConfig.typography.monoFamily
            styleName: ShellConfig.typography.fineStyle
            pixelSize: 14
        }
        onAccepted: root.accepted()

        Text {
            anchors.fill: parent
            visible: field.text.length === 0 && !field.activeFocus
            text: root.placeholderText
            color: Theme.textMuted
            verticalAlignment: Text.AlignVCenter
            renderType: Text.NativeRendering
            font: field.font
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: FloralSettings.duration(130)
            easing.type: Easing.InOutCubic
        }
    }
}
