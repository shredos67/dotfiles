pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.SystemTray

Item {
	id: root

	signal clicked

	readonly property var trayItems: SystemTray.items.values
	readonly property int itemCount: trayItems.length
	readonly property bool hovered: pointer.containsMouse

	visible: FloralSettings.dockTray
		&& !FloralSettings.dockEnabled
		&& itemCount > 0
	implicitWidth: summaryRow.implicitWidth
	implicitHeight: ShellConfig.bar.mediaButtonSize
	scale: pointer.pressed ? 0.96 : pointer.containsMouse ? 1.025 : 1

	Behavior on scale {
		NumberAnimation {
			duration: FloralSettings.duration(ShellConfig.visuals.motionFast)
			easing.type: Easing.OutCubic
		}
	}

	Rectangle {
		anchors.fill: parent
		anchors.margins: -ShellConfig.bar.mediaSummaryPadding
		radius: ShellConfig.visuals.controlRadius
		color: root.hovered ? Theme.panelRaised : "transparent"
		border.width: root.hovered ? ShellConfig.bar.hairlineThickness : 0
		border.color: Theme.frameBorderSoft

		Behavior on color {
			ColorAnimation {
				duration: FloralSettings.duration(ShellConfig.visuals.motionFast)
				easing.type: Easing.OutCubic
			}
		}
	}

	Row {
		id: summaryRow

		anchors.centerIn: parent
		spacing: ShellConfig.bar.mediaSpacing

		Text {
			anchors.verticalCenter: parent.verticalCenter
			text: "tray:"
			color: Theme.moduleLabel
			renderType: Text.NativeRendering
			font {
				family: ShellConfig.typography.monoFamily
				styleName: ShellConfig.typography.fineStyle
				pixelSize: ShellConfig.bar.valueFontSize
				weight: ShellConfig.bar.labelFontWeight
			}
		}

		Text {
			anchors.verticalCenter: parent.verticalCenter
			text: root.itemCount.toString().padStart(2, "0")
			color: Theme.moduleValue
			renderType: Text.NativeRendering
			font {
				family: ShellConfig.typography.monoFamily
				pixelSize: ShellConfig.bar.valueFontSize
			}
		}
	}

	MouseArea {
		id: pointer

		anchors.fill: parent
		anchors.topMargin: -ShellConfig.bar.popupTriggerTopExtension
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: root.clicked()
	}
}
