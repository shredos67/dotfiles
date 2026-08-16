import QtQuick
import Quickshell.Hyprland

Item {
	id: root
	property int maximumWidth: 280
	readonly property bool hovered: pointer.containsMouse
	signal clicked

	implicitWidth: Math.min(titleLabel.implicitWidth, maximumWidth)
	implicitHeight: ShellConfig.bar.mediaButtonSize
	scale: pointer.pressed ? 0.98 : root.hovered ? 1.012 : 1

	Behavior on scale {
		NumberAnimation {
			duration: ShellConfig.visuals.motionFast
			easing.type: Easing.OutCubic
		}
	}

	Rectangle {
		anchors.fill: parent
		radius: ShellConfig.visuals.controlRadius
		color: root.hovered ? Theme.panelRaised : "transparent"
		border.width: root.hovered ? ShellConfig.bar.hairlineThickness : 0
		border.color: Theme.frameBorderSoft

		Behavior on color {
			ColorAnimation { duration: ShellConfig.visuals.motionFast }
		}
	}

	Text {
		id: titleLabel
		anchors {
			left: parent.left
			right: parent.right
			verticalCenter: parent.verticalCenter
			leftMargin: root.hovered ? ShellConfig.scaled(6) : 0
			rightMargin: root.hovered ? ShellConfig.scaled(6) : 0
		}
		text: String(Hyprland.activeToplevel?.title || "desktop").toLowerCase()
		color: Theme.moduleValue
		elide: Text.ElideRight
		font {
			family: ShellConfig.typography.monoFamily
			pixelSize: ShellConfig.bar.windowFontSize
		}
	}

	MouseArea {
		id: pointer

		anchors {
			fill: parent
			topMargin: -ShellConfig.bar.popupTriggerTopExtension
		}
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: root.clicked()
	}
}
