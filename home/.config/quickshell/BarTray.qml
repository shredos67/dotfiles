pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Caelestia.Config
import qs.components

Item {
	id: root

	required property bool triggerHovered
	property bool pinnedOpen: false
	property string hoveredTitle: ""

	readonly property var trayItems: SystemTray.items.values
	readonly property int maximumItems: 15
	readonly property int itemCount: Math.min(maximumItems, trayItems.length)
	readonly property int columnCount: Math.max(1, Math.min(5, itemCount))
	readonly property int rowCount: Math.max(1,
		Math.ceil(itemCount / columnCount))
	readonly property int popupPadding: Math.min(ShellConfig.scaled(13), 16)
	readonly property int headerHeight: Math.min(ShellConfig.scaled(19), 23)
	readonly property int cellSize: Math.min(ShellConfig.scaled(35), 42)
	readonly property int cellSpacing: Math.min(ShellConfig.scaled(5), 6)
	readonly property int contentGap: Math.min(ShellConfig.scaled(7), 8)
	readonly property bool hovered: popupHover.hovered
	readonly property bool shouldOpen: itemCount > 0
		&& (triggerHovered || hovered || pinnedOpen)
	readonly property real visualTop: ShellConfig.bar.mediaPopupHoverBridge
		- ShellConfig.bar.mediaPopupBorderOverlap
	readonly property real panelHeight: ShellConfig.bar.mediaPopupBorderOverlap
		+ popupPadding * 2 + headerHeight + contentGap
		+ rowCount * cellSize + Math.max(0, rowCount - 1) * cellSpacing
	readonly property real animationOverflow:
		ShellConfig.bar.mediaPopupBounceBridge
	readonly property real slideOffset: -panelHeight * offsetScale
	readonly property real revealHeight: visible
		? panelHeight + animationOverflow : 0

	property real offsetScale: shouldOpen ? 0 : 1

	function togglePinned(): void {
		pinnedOpen = itemCount > 0 && !pinnedOpen;
	}

	function close(): void {
		pinnedOpen = false;
	}

	onItemCountChanged: {
		if (itemCount === 0)
			pinnedOpen = false;
	}

	visible: itemCount > 0 && offsetScale < 1
	width: Math.min(ShellConfig.scaled(270), 324)
	height: visualTop + panelHeight + animationOverflow

	Behavior on offsetScale {
		NumberAnimation {
			duration: FloralSettings.duration(ShellConfig.visuals.motionNormal)
			easing.type: Easing.OutCubic
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
					leftMargin: root.popupPadding
					rightMargin: root.popupPadding
					topMargin: root.popupPadding
						- root.visualTop
				}
				spacing: root.contentGap

				Item {
					width: parent.width
					height: root.headerHeight

					Text {
						anchors {
							left: parent.left
							right: countLabel.left
							rightMargin: ShellConfig.scaled(8)
							verticalCenter: parent.verticalCenter
						}
						text: root.hoveredTitle || "system tray"
						color: root.hoveredTitle
							? Theme.moduleValue : Theme.moduleLabel
						elide: Text.ElideRight
						renderType: Text.NativeRendering
						font {
							family: ShellConfig.typography.monoFamily
							styleName: ShellConfig.typography.fineStyle
							pixelSize: ShellConfig.bar.networkPopupTextSize
							weight: Font.DemiBold
						}
					}

					Text {
						id: countLabel

						anchors {
							right: parent.right
							verticalCenter: parent.verticalCenter
						}
						text: SystemTray.items.values.length > root.maximumItems
							? `${root.maximumItems}/${SystemTray.items.values.length}`
							: SystemTray.items.values.length.toString().padStart(2, "0")
						color: Theme.textMuted
						renderType: Text.NativeRendering
						font {
							family: ShellConfig.typography.monoFamily
							pixelSize: ShellConfig.bar.networkPopupTextSize
						}
					}
				}

				Grid {
					anchors.horizontalCenter: parent.horizontalCenter
					width: root.columnCount * root.cellSize
						+ Math.max(0, root.columnCount - 1) * root.cellSpacing
					columns: root.columnCount
					columnSpacing: root.cellSpacing
					rowSpacing: root.cellSpacing

					Repeater {
						model: root.trayItems.slice(0, root.maximumItems)

						Item {
							id: trayCell

							required property var modelData
							readonly property bool hovered: trayPointer.containsMouse
							readonly property string title:
								modelData.tooltipTitle
								|| modelData.title
								|| modelData.id
								|| "tray item"

							width: root.cellSize
							height: root.cellSize
							scale: trayPointer.pressed ? 0.94
								: trayCell.hovered ? 1.035 : 1

							Behavior on scale {
								NumberAnimation {
									duration: FloralSettings.duration(
										ShellConfig.visuals.motionFast)
									easing.type: Easing.OutCubic
								}
							}

							Rectangle {
								anchors.fill: parent
								radius: ShellConfig.visuals.controlRadius
								color: trayCell.hovered
									? Theme.panelHighlight : Theme.panelRaised
								border.width: trayCell.hovered
									? ShellConfig.bar.hairlineThickness : 0
								border.color: Theme.frameBorderSoft

								Behavior on color {
									ColorAnimation {
										duration: FloralSettings.duration(
											ShellConfig.visuals.motionFast)
										easing.type: Easing.OutCubic
									}
								}
							}

							MaterialIcon {
								anchors.centerIn: parent
								visible: !trayIcon.visible
								text: "apps"
								color: trayCell.hovered
									? Theme.moduleLabel : Theme.textMuted
								fontStyle: Tokens.font.icon.small
							}

							IconImage {
								id: trayIcon

								anchors.fill: parent
								anchors.margins: ShellConfig.scaled(8)
								source: trayCell.modelData.icon
								visible: String(source).length > 0
							}

							MouseArea {
								id: trayPointer

								anchors.fill: parent
								hoverEnabled: true
								acceptedButtons: Qt.LeftButton | Qt.RightButton
								cursorShape: Qt.PointingHandCursor
								onEntered: root.hoveredTitle = trayCell.title
								onExited: {
									if (root.hoveredTitle === trayCell.title)
										root.hoveredTitle = "";
								}
								onClicked: event => {
									if (event.button === Qt.RightButton)
										trayCell.modelData.secondaryActivate();
									else
										trayCell.modelData.activate();
									root.close();
								}
								onWheel: event => trayCell.modelData.scroll(
									event.angleDelta.y, false)
							}
						}
					}
				}
			}
		}
	}

	HoverHandler {
		id: popupHover

		enabled: root.offsetScale < 1
	}
}
