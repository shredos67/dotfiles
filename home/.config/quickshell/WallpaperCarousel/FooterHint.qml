import QtQuick
import qs

Row {
    id: root

    required property string keyText
    required property string labelText

    spacing: ShellConfig.scaled(7)

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: keyLabel.implicitWidth + ShellConfig.scaled(14)
        height: ShellConfig.scaled(25)
        radius: ShellConfig.visuals.controlRadius
        color: Theme.panelHighlight
        border.width: ShellConfig.notifications.borderWidth
        border.color: Theme.frameBorderSoft

        Rectangle {
            anchors.fill: parent
            anchors.margins: ShellConfig.scaled(3)
            radius: Math.max(0, parent.radius - ShellConfig.scaled(3))
            color: "transparent"
            border.width: ShellConfig.bar.hairlineThickness
            border.color: Theme.frameBorderFaint
        }

        Text {
            id: keyLabel

            anchors.centerIn: parent
            text: root.keyText
            color: Theme.moduleValue
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                styleName: ShellConfig.typography.fineStyle
                pixelSize: ShellConfig.wallpaperPicker.detailSize
            }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.labelText
        color: Theme.textMuted
        renderType: Text.NativeRendering
        font {
            family: ShellConfig.typography.monoFamily
            pixelSize: ShellConfig.wallpaperPicker.detailSize
        }
    }
}
