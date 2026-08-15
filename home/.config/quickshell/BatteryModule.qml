import QtQuick
import Quickshell.Services.UPower
import qs.components

Item {
	id: root
	signal clicked

	readonly property var battery: UPower.displayDevice
	readonly property int percentage: battery.ready
		? Math.round(battery.percentage * 100)
		: 0
	readonly property int fillPercentage: Math.max(0, Math.min(100,
		Math.round(percentage / 10) * 10))
	readonly property color chargeColour: percentage < 10
		? Theme.statusDanger
		: Theme.accentPrimary

	visible: battery.ready && battery.isPresent
	implicitWidth: ShellConfig.bar.batteryWidth + ShellConfig.bar.batteryPoleWidth
	implicitHeight: ShellConfig.bar.batteryHeight

	StyledRect {
		id: batteryBody

		anchors.left: parent.left
		anchors.verticalCenter: parent.verticalCenter
		width: ShellConfig.bar.batteryWidth
		height: ShellConfig.bar.batteryHeight
		radius: ShellConfig.bar.batteryCornerRadius
		color: Theme.panelRaised
		border.width: ShellConfig.bar.batteryBorderWidth
		border.color: root.chargeColour
		clip: true

		StyledRect {
			anchors {
				left: parent.left
				leftMargin: ShellConfig.bar.batteryBorderWidth
				top: parent.top
				topMargin: ShellConfig.bar.batteryBorderWidth
				bottom: parent.bottom
				bottomMargin: ShellConfig.bar.batteryBorderWidth
			}
			width: Math.max(0, (parent.width - ShellConfig.bar.batteryBorderWidth * 2)
				* root.fillPercentage / 100)
			radius: Math.max(0, batteryBody.radius
				- ShellConfig.bar.batteryBorderWidth)
			color: root.chargeColour

			Behavior on width {
				NumberAnimation { duration: ShellConfig.bar.batteryAnimationMs }
			}
		}

		Text {
			anchors.centerIn: parent
			z: 1
			text: root.percentage + "%"
			color: Theme.moduleValue
			font {
				family: ShellConfig.typography.monoFamily
				pixelSize: ShellConfig.bar.batteryFontSize
				weight: Font.DemiBold
			}
		}
	}

	StyledRect {
		anchors {
			left: batteryBody.right
			verticalCenter: batteryBody.verticalCenter
		}
		width: ShellConfig.bar.batteryPoleWidth
		height: ShellConfig.bar.batteryPoleHeight
		radius: 0
		topLeftRadius: 0
		bottomLeftRadius: 0
		topRightRadius: Math.min(width / 2, height / 2)
		bottomRightRadius: topRightRadius
		color: root.chargeColour
	}

	MouseArea {
		anchors {
			fill: parent
			topMargin: -ShellConfig.bar.popupTriggerTopExtension
		}
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: root.clicked()
	}
}
