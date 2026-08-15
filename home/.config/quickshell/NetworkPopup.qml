import QtQuick
import qs.components
import qs.components.misc
import qs.services 1.0

Item {
	id: root

	required property var connectedDevice
	required property bool wifi
	required property var activeNetwork
	required property string connectionName
	required property bool triggerHovered

	readonly property bool hovered: popupHover.hovered
	readonly property bool shouldOpen: triggerHovered || hovered
	readonly property real visualTop: ShellConfig.bar.mediaPopupHoverBridge
		- ShellConfig.bar.mediaPopupBorderOverlap
	readonly property real panelHeight: ShellConfig.bar.networkPopupHeight
		+ ShellConfig.bar.mediaPopupBorderOverlap
	readonly property real animationOverflow:
		ShellConfig.bar.mediaPopupBounceBridge
	readonly property real slideOffset: -panelHeight * offsetScale
	readonly property real revealHeight: visible
		? panelHeight + animationOverflow : 0
	readonly property var deviceDetails: wifi
		? Nmcli.wirelessDeviceDetails
		: Nmcli.ethernetDeviceDetails
	property real offsetScale: shouldOpen ? 0 : 1

	function compactNumber(value: real): string {
		if (value >= 100)
			return value.toFixed(0)
		if (value >= 10)
			return value.toFixed(1)
		return value.toFixed(2)
	}

	function formatRate(bytes: real): string {
		const formatted = NetworkUsage.formatBytes(bytes ?? 0)
		return `${compactNumber(formatted.value)} ${formatted.unit}`
	}

	function formatTotal(bytes: real): string {
		const formatted = NetworkUsage.formatBytesTotal(bytes ?? 0)
		return `${compactNumber(formatted.value)} ${formatted.unit}`
	}

	function frequencyLabel(): string {
		const frequency = Nmcli.active?.frequency ?? 0
		if (frequency >= 1000)
			return `${(frequency / 1000).toFixed(1)} GHz`
		return frequency > 0 ? `${frequency} MHz` : ""
	}

	function linkDescription(): string {
		if (!connectedDevice)
			return "Disconnected"

		const parts = []
		if (wifi) {
			parts.push("Wi-Fi")
			const strength = Nmcli.active?.strength ?? 0
			if (strength > 0)
				parts.push(`${strength}% signal`)
			const frequency = frequencyLabel()
			if (frequency)
				parts.push(frequency)
			const security = Nmcli.active?.security ?? ""
			if (security)
				parts.push(security)
		} else {
			parts.push("Ethernet")
			const speed = Nmcli.ethernetSpeed
				|| deviceDetails?.speed || ""
			if (speed)
				parts.push(speed)
		}
		return parts.join("  •  ")
	}

	function refreshDetails(): void {
		Nmcli.refreshStatus(status => {
			if (!status.connected)
				return
			if (root.wifi)
				Nmcli.getWirelessDeviceDetails(status.interface, () => {})
			else
				Nmcli.getEthernetDeviceDetails(status.interface, () => {})
		})
	}

	onShouldOpenChanged: {
		if (shouldOpen)
			refreshDetails()
	}

	visible: offsetScale < 1
	width: ShellConfig.bar.networkPopupWidth
	height: visualTop + panelHeight + animationOverflow

	Behavior on offsetScale {
		Anim {}
	}

	Loader {
		active: root.shouldOpen
		sourceComponent: Ref {
			service: NetworkUsage
		}
	}

	PopupBridge {
		active: root.shouldOpen
		width: root.width
	}

	Item {
		x: 0
		y: root.visualTop
		width: root.width
		height: root.panelHeight + root.animationOverflow
		clip: true

		Item {
			x: 0
			y: root.slideOffset
			width: root.width
			height: root.panelHeight

			PopupChrome { anchors.fill: parent }

			Column {
				anchors {
					left: parent.left
					right: parent.right
					top: parent.top
					leftMargin: ShellConfig.bar.networkPopupPadding
					rightMargin: ShellConfig.bar.networkPopupPadding
					topMargin: ShellConfig.bar.networkPopupContentTop
						- root.visualTop
				}
				spacing: ShellConfig.bar.networkPopupSectionSpacing

				Text {
					width: parent.width
					text: root.connectionName
					color: root.connectedDevice
						? Theme.moduleLabel
						: Theme.textMuted
					elide: Text.ElideRight
					font {
						family: ShellConfig.typography.monoFamily
						pixelSize: ShellConfig.bar.networkPopupTitleSize
						weight: Font.DemiBold
					}
				}

				Text {
					width: parent.width
					text: root.linkDescription()
					color: Theme.textMuted
					elide: Text.ElideRight
					font {
						family: ShellConfig.typography.monoFamily
						pixelSize: ShellConfig.bar.networkPopupTextSize
					}
				}

				Rectangle {
					width: parent.width
					height: 1
					color: Theme.separator
					opacity: 0.6
				}

				Column {
					width: parent.width
					spacing: ShellConfig.bar.networkPopupRowSpacing

					NetworkDetailRow {
						width: parent.width
						label: "INTERFACE"
						value: Nmcli.activeInterface || "—"
					}

					NetworkDetailRow {
						width: parent.width
						label: "IPV4"
						value: root.deviceDetails?.ipAddress || "—"
					}

					NetworkDetailRow {
						width: parent.width
						label: "GATEWAY"
						value: root.deviceDetails?.gateway || "—"
					}

					NetworkDetailRow {
						width: parent.width
						label: "DOWNLOAD"
						value: `${root.formatRate(NetworkUsage.downloadSpeed)}  •  ${root.formatTotal(NetworkUsage.downloadTotal)}`
					}

					NetworkDetailRow {
						width: parent.width
						label: "UPLOAD"
						value: `${root.formatRate(NetworkUsage.uploadSpeed)}  •  ${root.formatTotal(NetworkUsage.uploadTotal)}`
					}
				}
			}
		}
	}

	HoverHandler {
		id: popupHover
		enabled: root.offsetScale < 1
	}

	component NetworkDetailRow: Item {
		required property string label
		required property string value

		implicitHeight: Math.max(detailLabel.implicitHeight, detailValue.implicitHeight)

		Text {
			id: detailLabel
			anchors {
				left: parent.left
				verticalCenter: parent.verticalCenter
			}
			width: ShellConfig.bar.networkPopupLabelWidth
			text: parent.label.toLowerCase()
			color: Theme.moduleLabel
			font {
				family: ShellConfig.typography.monoFamily
				pixelSize: ShellConfig.bar.networkPopupTextSize
				weight: Font.DemiBold
			}
		}

		Text {
			id: detailValue
			anchors {
				left: detailLabel.right
				right: parent.right
				verticalCenter: parent.verticalCenter
			}
			text: parent.value
			color: Theme.moduleValue
			horizontalAlignment: Text.AlignRight
			elide: Text.ElideRight
			font {
				family: ShellConfig.typography.monoFamily
				pixelSize: ShellConfig.bar.networkPopupTextSize
			}
		}
	}
}
