import QtQuick
import QtQuick.Effects
import Quickshell

Item {
	id: root

	signal clicked

	implicitWidth: ShellConfig.bar.menuButtonSize
	implicitHeight: ShellConfig.bar.menuButtonSize
	scale: pointer.pressed ? 0.82 : pointer.containsMouse ? 1.08 : 1

	Behavior on scale {
		NumberAnimation {
			duration: ShellConfig.bar.menuAnimationMs
			easing.type: Easing.OutBack
		}
	}

	Rectangle {
		anchors.fill: parent
		radius: ShellConfig.visuals.controlRadius
		color: pointer.pressed
			? Theme.panelHighlight
			: pointer.containsMouse ? Theme.panelRaised : "transparent"
		border.width: pointer.containsMouse ? ShellConfig.bar.contentBorderWidth : 0
		border.color: Theme.frameBorder
		scale: pointer.containsMouse ? 1 : 0.84
		opacity: pointer.containsMouse || pointer.pressed ? 1 : 0

		Behavior on color {
			ColorAnimation { duration: ShellConfig.bar.menuAnimationMs }
		}

		Behavior on scale {
			NumberAnimation {
				duration: ShellConfig.visuals.motionFast
				easing.type: Easing.OutBack
			}
		}

		Behavior on opacity {
			NumberAnimation { duration: ShellConfig.visuals.motionFast }
		}
	}

	Image {
		id: fedoraLogo

		anchors.centerIn: parent
		width: ShellConfig.bar.launcherIconSize
		height: ShellConfig.bar.launcherIconSize
		source: Quickshell.iconPath("fedora-logo-icon", true)
		fillMode: Image.PreserveAspectFit
		smooth: true
		mipmap: true
		visible: false
	}

	MultiEffect {
		anchors.fill: fedoraLogo
		source: fedoraLogo
		colorization: 1
		colorizationColor: Theme.moduleLabel
		rotation: pointer.containsMouse ? 8 : 0

		Behavior on rotation {
			NumberAnimation {
				duration: ShellConfig.bar.menuAnimationMs
				easing.type: Easing.OutBack
			}
		}
	}

	MouseArea {
		id: pointer

		anchors.fill: parent
		anchors.leftMargin: -ShellConfig.bar.cornerButtonHorizontalExtension
		anchors.topMargin: -ShellConfig.bar.cornerButtonVerticalExtension
		anchors.bottomMargin: -ShellConfig.bar.cornerButtonVerticalExtension
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: root.clicked()
	}
}
