pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets

PopupWindow {
	id: root

	property Item anchorItem: null
	property var trayItem: null
	property bool openAbove: false
	property bool mapped: false
	property bool shown: false
	property var menuStack: []
	property var titleStack: []
	property real pageOffset: 0

	readonly property bool opened: mapped
	readonly property var currentHandle: menuStack.length > 0
		? menuStack[menuStack.length - 1] : null
	readonly property string currentTitle: titleStack.length > 0
		? titleStack[titleStack.length - 1] : "actions"
	readonly property int panelWidth: Math.min(ShellConfig.scaled(300), 360)
	readonly property int headerHeight: Math.min(ShellConfig.scaled(54), 64)
	readonly property int listHeight: Math.max(ShellConfig.scaled(52),
		Math.min(ShellConfig.scaled(258), menuList.contentHeight))
	readonly property int panelHeight: headerHeight + listHeight
		+ ShellConfig.scaled(18)

	signal dismissed

	function displayName(item): string {
		if (!item)
			return "system tray";
		return item.tooltipTitle || item.title || item.id || "system tray";
	}

	function openFor(item: Item, tray, above: bool): void {
		if (!item || !tray || !tray.hasMenu || !tray.menu)
			return;

		anchorItem = item;
		trayItem = tray;
		openAbove = above;
		menuStack = [tray.menu];
		titleStack = [displayName(tray)];
		pageOffset = above ? 8 : -8;
		shown = false;
		mapped = true;
		Qt.callLater(() => {
			if (root.mapped) {
				root.pageOffset = 0;
				root.shown = true;
			}
		});
	}

	function beginClose(): void {
		if (!mapped)
			return;
		shown = false;
		closeTimer.restart();
	}

	function closeNow(): void {
		closeTimer.stop();
		mapped = false;
		shown = false;
		menuStack = [];
		titleStack = [];
		trayItem = null;
		anchorItem = null;
		dismissed();
	}

	function push(entry): void {
		pageOffset = 13;
		shown = false;
		menuStack = menuStack.concat([entry]);
		titleStack = titleStack.concat([entry.text || "actions"]);
		Qt.callLater(() => {
			if (root.mapped) {
				root.pageOffset = 0;
				root.shown = true;
			}
		});
	}

	function pop(): void {
		if (menuStack.length <= 1) {
			beginClose();
			return;
		}
		pageOffset = -13;
		shown = false;
		menuStack = menuStack.slice(0, -1);
		titleStack = titleStack.slice(0, -1);
		Qt.callLater(() => {
			if (root.mapped) {
				root.pageOffset = 0;
				root.shown = true;
			}
		});
	}

	function selectEntry(entry): void {
		if (!entry || !entry.enabled)
			return;
		if (entry.hasChildren) {
			push(entry);
			return;
		}
		entry.triggered();
		beginClose();
	}

	visible: mapped
	grabFocus: true
	color: "transparent"
	implicitWidth: panelWidth + ShellConfig.scaled(20)
	implicitHeight: panelHeight + ShellConfig.scaled(20)

	anchor.item: anchorItem
	anchor.rect.x: anchorItem
		? Math.round(anchorItem.width / 2 - width / 2) : 0
	anchor.rect.y: anchorItem
		? (openAbove
			? -height - ShellConfig.scaled(6)
			: anchorItem.height + ShellConfig.scaled(6))
		: 0
	anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.FlipY

	onVisibleChanged: {
		if (!visible && mapped)
			closeNow();
	}

	Timer {
		id: closeTimer

		interval: FloralSettings.duration(ShellConfig.visuals.motionFast)
		repeat: false
		onTriggered: root.closeNow()
	}

	QsMenuOpener {
		id: menuOpener

		menu: root.currentHandle
	}

	FloralSurface {
		id: surface

		x: ShellConfig.scaled(10)
		y: ShellConfig.scaled(10) + (root.shown ? 0
			: root.openAbove ? 6 : -6)
		width: root.panelWidth
		height: root.panelHeight
		radius: ShellConfig.visuals.surfaceRadius
		fillColor: Theme.panel
		borderColor: Theme.frameBorder
		innerBorderColor: Theme.frameBorderFaint
		ornamented: true
		ornamentStrength: 0.13
		ornamentSize: Math.min(width * 0.34, ShellConfig.scaled(110))
		opacity: root.shown ? 1 : 0
		scale: root.shown ? 1 : 0.975
		transformOrigin: root.openAbove ? Item.Bottom : Item.Top

		Behavior on y {
			NumberAnimation {
				duration: FloralSettings.duration(
					ShellConfig.visuals.motionFast)
				easing.type: Easing.OutCubic
			}
		}

		Behavior on opacity {
			NumberAnimation {
				duration: FloralSettings.duration(
					ShellConfig.visuals.motionFast)
				easing.type: Easing.OutCubic
			}
		}

		Behavior on scale {
			NumberAnimation {
				duration: FloralSettings.duration(
					ShellConfig.visuals.motionFast)
				easing.type: Easing.OutCubic
			}
		}

		Item {
			id: header

			anchors {
				left: parent.left
				right: parent.right
				top: parent.top
				leftMargin: ShellConfig.scaled(13)
				rightMargin: ShellConfig.scaled(13)
				topMargin: ShellConfig.scaled(8)
			}
			height: root.headerHeight - ShellConfig.scaled(9)

			Item {
				id: backButton

				anchors {
					left: parent.left
					verticalCenter: parent.verticalCenter
				}
				width: 31
				height: 31
				visible: root.menuStack.length > 1

				Rectangle {
					anchors.fill: parent
					radius: ShellConfig.visuals.controlRadius
					color: backPointer.containsMouse
						? Theme.panelHighlight : Theme.panelRaised
					border.width: 1
					border.color: Theme.frameBorderSoft
				}

				Item {
					anchors.centerIn: parent
					width: 13
					height: 15

					Rectangle {
						x: 2
						y: 4
						width: 8
						height: 1
						rotation: -45
						color: Theme.moduleLabel
					}

					Rectangle {
						x: 2
						y: 10
						width: 8
						height: 1
						rotation: 45
						color: Theme.moduleLabel
					}
				}

				MouseArea {
					id: backPointer

					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: root.pop()
				}
			}

			IconImage {
				id: trayIcon

				anchors {
					left: backButton.visible ? backButton.right : parent.left
					leftMargin: backButton.visible ? 9 : 1
					verticalCenter: parent.verticalCenter
				}
				implicitSize: 24
				asynchronous: true
				visible: String(source).length > 0
				source: root.trayItem ? root.trayItem.icon : ""
			}

			Text {
				anchors {
					left: trayIcon.visible ? trayIcon.right
						: backButton.visible ? backButton.right : parent.left
					leftMargin: trayIcon.visible || backButton.visible ? 9 : 1
					right: closeButton.left
					rightMargin: 9
					verticalCenter: parent.verticalCenter
				}
				text: root.currentTitle
				color: Theme.moduleLabel
				elide: Text.ElideRight
				renderType: Text.NativeRendering
				font {
					family: ShellConfig.typography.monoFamily
					styleName: ShellConfig.typography.fineStyle
					pixelSize: ShellConfig.scaled(13)
					weight: Font.DemiBold
				}
			}

			Item {
				id: closeButton

				anchors {
					right: parent.right
					verticalCenter: parent.verticalCenter
				}
				width: 31
				height: 31

				Rectangle {
					anchors.fill: parent
					radius: ShellConfig.visuals.controlRadius
					color: closePointer.containsMouse
						? Theme.panelHighlight : Theme.panelRaised
					border.width: 1
					border.color: Theme.frameBorderSoft
				}

				Item {
					anchors.centerIn: parent
					width: 14
					height: 14

					Rectangle {
						anchors.centerIn: parent
						width: 13
						height: 1
						rotation: 45
						color: Theme.moduleValue
					}

					Rectangle {
						anchors.centerIn: parent
						width: 13
						height: 1
						rotation: -45
						color: Theme.moduleValue
					}
				}

				MouseArea {
					id: closePointer

					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: root.beginClose()
				}
			}
		}

		Rectangle {
			anchors {
				left: parent.left
				right: parent.right
				top: parent.top
				leftMargin: ShellConfig.scaled(13)
				rightMargin: ShellConfig.scaled(13)
				topMargin: root.headerHeight
			}
			height: 1
			color: Theme.frameBorderSoft
		}

		Item {
			anchors {
				left: parent.left
				right: parent.right
				top: parent.top
				bottom: parent.bottom
				leftMargin: ShellConfig.scaled(10)
				rightMargin: ShellConfig.scaled(10)
				topMargin: root.headerHeight + ShellConfig.scaled(5)
				bottomMargin: ShellConfig.scaled(8)
			}
			clip: true
			opacity: root.shown ? 1 : 0
			x: root.pageOffset

			Behavior on opacity {
				NumberAnimation {
					duration: FloralSettings.duration(
						ShellConfig.visuals.motionFast)
					easing.type: Easing.OutCubic
				}
			}

			Behavior on x {
				NumberAnimation {
					duration: FloralSettings.duration(
						ShellConfig.visuals.motionFast)
					easing.type: Easing.OutCubic
				}
			}

			ListView {
				id: menuList

				anchors.fill: parent
				clip: true
				spacing: 2
				boundsBehavior: Flickable.StopAtBounds
				flickDeceleration: 3600
				maximumFlickVelocity: 2100
				model: menuOpener.children

				delegate: FloralTrayMenuEntry {
					width: menuList.width
					onSelected: entry => root.selectEntry(entry)
				}
			}

			Rectangle {
				anchors {
					right: parent.right
					rightMargin: 1
				}
				visible: menuList.contentHeight > menuList.height
				width: 2
				height: Math.max(18, parent.height
					* parent.height / menuList.contentHeight)
				y: menuList.contentY <= 0 ? 0
					: Math.min(parent.height - height,
						menuList.contentY / Math.max(1,
							menuList.contentHeight - menuList.height)
							* (parent.height - height))
				radius: 1
				color: Theme.frameBorderSoft
			}

			Text {
				anchors.centerIn: parent
				visible: menuOpener.children.values.length === 0
				text: "no actions"
				color: Theme.textMuted
				renderType: Text.NativeRendering
				font {
					family: ShellConfig.typography.monoFamily
					styleName: ShellConfig.typography.fineStyle
					pixelSize: ShellConfig.scaled(12)
				}
			}
		}
	}

	Shortcut {
		sequence: "Escape"
		context: Qt.WindowShortcut
		enabled: root.mapped
		onActivated: {
			if (root.menuStack.length > 1)
				root.pop();
			else
				root.beginClose();
		}
	}
}
