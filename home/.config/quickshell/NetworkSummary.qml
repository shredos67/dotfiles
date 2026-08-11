import QtQuick
import Quickshell.Networking

Item {
	id: root

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
	readonly property bool hovered: hoverHandler.hovered

	implicitWidth: summaryRow.implicitWidth
	implicitHeight: ShellConfig.bar.mediaButtonSize

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

		HoverHandler {
			id: hoverHandler
		}
	}
}
