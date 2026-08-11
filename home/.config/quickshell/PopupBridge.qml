import QtQuick

Item {
	id: root

	property bool active: false
	readonly property real visualTop: ShellConfig.bar.mediaPopupHoverBridge
		- ShellConfig.bar.mediaPopupBorderOverlap
	readonly property real faintTop: ShellConfig.bar.mediaPopupHoverBridge
		- ShellConfig.bar.engravedInset
	readonly property real inset: ShellConfig.bar.popupInnerInset
	readonly property real bridgeBottom: visualTop
		+ ShellConfig.bar.mediaPopupBounceBridge

	visible: active
	height: bridgeBottom

	Rectangle {
		x: 0
		y: root.visualTop
		width: root.width
		height: ShellConfig.bar.mediaPopupBounceBridge
		color: Theme.panel

		Rectangle {
			anchors.fill: parent
			color: Theme.panelSheen
		}
	}

	Rectangle {
		x: root.inset + ShellConfig.bar.hairlineThickness
		y: root.faintTop - ShellConfig.frame.lineThickness
		width: root.width - root.inset * 2
			- ShellConfig.bar.hairlineThickness * 2
		height: ShellConfig.bar.hairlineThickness + 6
		color: Theme.panel

		Rectangle {
			anchors.fill: parent
			color: Theme.panelSheen
		}
	}

	Rectangle {
		x: 0
		y: root.visualTop
		width: ShellConfig.frame.lineThickness
		height: ShellConfig.bar.mediaPopupBounceBridge
		color: Theme.frameBorder
	}

	Rectangle {
		x: root.width - width
		y: root.visualTop
		width: ShellConfig.frame.lineThickness
		height: ShellConfig.bar.mediaPopupBounceBridge
		color: Theme.frameBorder
	}

	Rectangle {
		x: root.inset
		y: root.faintTop
		width: ShellConfig.bar.hairlineThickness
		height: root.bridgeBottom - root.faintTop
		color: Theme.frameBorderFaint
	}

	Rectangle {
		x: root.width - root.inset - width
		y: root.faintTop
		width: ShellConfig.bar.hairlineThickness
		height: root.bridgeBottom - root.faintTop
		color: Theme.frameBorderFaint
	}
}
