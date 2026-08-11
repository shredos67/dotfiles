import QtQuick
import qs.components

Item {
	id: root

	required property string label
	required property real value
	required property bool triggerHovered

	signal valueMoved(real value)

	readonly property bool hovered: popupHover.hovered
	readonly property bool shouldOpen: triggerHovered || hovered
	readonly property real visualTop: ShellConfig.bar.mediaPopupHoverBridge
		- ShellConfig.bar.mediaPopupBorderOverlap
	readonly property real panelHeight: ShellConfig.bar.controlPopupHeight
		+ ShellConfig.bar.mediaPopupBorderOverlap
	readonly property real animationOverflow:
		ShellConfig.bar.mediaPopupBounceBridge
	readonly property real slideOffset: -panelHeight * offsetScale
	readonly property real revealHeight: visible
		? panelHeight + animationOverflow : 0
	property real offsetScale: shouldOpen ? 0 : 1

	visible: offsetScale < 1
	width: ShellConfig.bar.controlPopupWidth
	height: visualTop + panelHeight + animationOverflow

	Behavior on offsetScale {
		Anim {}
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
					leftMargin: ShellConfig.bar.controlPopupPadding
					rightMargin: ShellConfig.bar.controlPopupPadding
					topMargin: ShellConfig.bar.controlPopupContentTop
						- root.visualTop
				}
				spacing: ShellConfig.bar.controlPopupSpacing

				Row {
					anchors.horizontalCenter: parent.horizontalCenter
					spacing: ShellConfig.bar.controlSummarySpacing

					Text {
						text: root.label.toLowerCase()
						color: Theme.moduleLabel
						font {
							family: ShellConfig.typography.monoFamily
							pixelSize: ShellConfig.bar.mediaPopupTitleSize
							weight: Font.DemiBold
						}
					}

					Text {
						text: `${Math.round(root.value * 100)}%`
						color: Theme.moduleValue
						font {
							family: ShellConfig.typography.monoFamily
							pixelSize: ShellConfig.bar.mediaPopupTitleSize
						}
					}
				}

				BarSlider {
					width: parent.width
					value: root.value
					onMoved: value => root.valueMoved(value)
				}
			}
		}
	}

	HoverHandler {
		id: popupHover
		enabled: root.offsetScale < 1
	}
}
