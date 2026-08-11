import QtQuick
import qs.services

Item {
	id: root
	readonly property var romanNumerals: ["I", "II", "III", "IV"]

	implicitWidth: workspaceRow.implicitWidth
	implicitHeight: ShellConfig.bar.workspaceButtonSize

	Row {
		id: workspaceRow

		spacing: ShellConfig.bar.workspaceSpacing

		Repeater {
			model: ShellConfig.bar.workspaceCount

			delegate: Rectangle {
				id: workspaceButton

				required property int index

				readonly property int workspaceId: index + 1
				readonly property var workspaceData: Hypr.workspaces.values.find(workspace => workspace.id === workspaceId) ?? null
				readonly property bool occupied: (workspaceData?.lastIpcObject.windows ?? 0) > 0
				readonly property bool active: Hypr.activeWsId === workspaceId

				width: ShellConfig.bar.workspaceButtonWidth
				height: ShellConfig.bar.workspaceButtonSize
				radius: height / 2
				color: active
					? Theme.panelHighlight
					: pointer.containsMouse ? Theme.panelRaised : "transparent"
				border.width: active || pointer.containsMouse
					? ShellConfig.bar.contentBorderWidth : 0
				border.color: Theme.frameBorder
				scale: pointer.pressed ? 0.82 : pointer.containsMouse ? 1.08 : 1

				Text {
					anchors.fill: parent
					horizontalAlignment: Text.AlignHCenter
					verticalAlignment: Text.AlignVCenter
					text: root.romanNumerals[workspaceButton.index]
						?? String(workspaceButton.workspaceId)
					color: workspaceButton.active
						? Theme.moduleLabel
						: workspaceButton.occupied ? Theme.moduleValue : Theme.textMuted
					font {
						family: ShellConfig.typography.monoFamily
						pixelSize: ShellConfig.bar.workspaceFontSize
						weight: workspaceButton.active ? Font.DemiBold : Font.Normal
					}

					Behavior on color {
						ColorAnimation { duration: ShellConfig.bar.workspaceAnimationMs }
					}
				}

				MouseArea {
					id: pointer

					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: Hypr.dispatch(Hypr.usingLua
						? `hl.dsp.focus({ workspace = "${workspaceButton.workspaceId}" })`
						: `workspace ${workspaceButton.workspaceId}`)
				}

				Behavior on color {
					ColorAnimation { duration: ShellConfig.bar.workspaceAnimationMs }
				}

				Behavior on scale {
					NumberAnimation {
						duration: ShellConfig.bar.workspaceAnimationMs
						easing.type: Easing.OutBack
					}
				}
			}
		}
	}
}
