import QtQuick
import Quickshell.Networking

Item {
	id: root
	signal clicked

	readonly property var connectedDevice: Networking.devices.values.find(
		device => device.connected
	) ?? null
	readonly property bool wifi: connectedDevice
		&& connectedDevice.type === DeviceType.Wifi
	readonly property var activeNetwork: connectedDevice
		? connectedDevice.networks.values.find(network => network.connected) ?? null
		: null
	readonly property string connectionName: connectedDevice
		? wifi
			? (activeNetwork ? activeNetwork.name : "Wi-Fi")
			: "Wired"
		: "Offline"
	readonly property bool hovered: summaryPointer.containsMouse

	implicitWidth: summaryRow.implicitWidth
	implicitHeight: ShellConfig.bar.mediaButtonSize
	scale: root.hovered ? 1.025 : 1

	Behavior on scale {
		NumberAnimation {
			duration: ShellConfig.visuals.motionFast
			easing.type: Easing.OutBack
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
			ColorAnimation { duration: ShellConfig.visuals.motionFast }
		}
	}

	Row {
		id: summaryRow

		anchors.centerIn: parent
		spacing: ShellConfig.bar.mediaSpacing

		Text {
			anchors.verticalCenter: parent.verticalCenter
			text: "net:"
			color: Theme.moduleLabel
			font {
				family: ShellConfig.typography.monoFamily
				styleName: ShellConfig.typography.fineStyle
				pixelSize: ShellConfig.bar.valueFontSize
				weight: ShellConfig.bar.labelFontWeight
			}
		}

		Text {
			anchors.verticalCenter: parent.verticalCenter
			width: Math.min(implicitWidth, ShellConfig.bar.networkMaximumWidth)
			text: root.connectionName
			color: root.connectedDevice ? Theme.moduleValue : Theme.textMuted
			elide: Text.ElideRight
			font {
				family: ShellConfig.typography.monoFamily
				pixelSize: ShellConfig.bar.valueFontSize
			}
		}
	}

	Item {
		anchors {
			fill: parent
			topMargin: -ShellConfig.bar.popupTriggerTopExtension
		}

		MouseArea {
			id: summaryPointer

			anchors.fill: parent
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			onClicked: root.clicked()
		}
	}
}
