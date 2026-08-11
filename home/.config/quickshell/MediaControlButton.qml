import QtQuick
import QtQuick.Shapes

Item {
	id: root

	required property string kind
	required property bool available
	property bool playing: false

	signal triggered

	implicitWidth: ShellConfig.bar.mediaPopupButtonSize
	implicitHeight: ShellConfig.bar.mediaPopupButtonSize
	opacity: available ? 1 : 0.35
	scale: pointer.pressed ? 0.82 : pointer.containsMouse ? 1.1 : 1

	Behavior on opacity {
		NumberAnimation { duration: ShellConfig.bar.mediaAnimationMs }
	}

	Behavior on scale {
		NumberAnimation {
			duration: ShellConfig.bar.mediaAnimationMs
			easing.type: Easing.OutBack
		}
	}

	Rectangle {
		anchors.fill: parent
		radius: 0
		color: pointer.pressed
			? Theme.panelHighlight
			: pointer.containsMouse ? Theme.panelRaised : "transparent"
		border.width: pointer.containsMouse
			? ShellConfig.bar.buttonBorderWidth : 0
		border.color: Theme.frameBorder

		Behavior on color {
			ColorAnimation { duration: ShellConfig.bar.mediaAnimationMs }
		}
	}

	Item {
		id: artwork

		anchors.centerIn: parent
		width: ShellConfig.bar.mediaPopupIconSize
		height: ShellConfig.bar.mediaPopupIconSize
		rotation: pointer.pressed
			? (root.kind === "previous" ? -8 : root.kind === "next" ? 8 : 0)
			: 0

		Behavior on rotation {
			NumberAnimation {
				duration: ShellConfig.bar.mediaAnimationMs
				easing.type: Easing.OutBack
			}
		}

		Shape {
			anchors.fill: parent
			visible: root.kind === "previous" || root.kind === "next"
			antialiasing: true

			ShapePath {
				fillColor: Theme.moduleValue
				strokeWidth: 0
				startX: root.kind === "previous" ? artwork.width - 1 : 1
				startY: 1
				PathLine {
					x: root.kind === "previous" ? 3 : artwork.width - 3
					y: artwork.height / 2
				}
				PathLine {
					x: root.kind === "previous" ? artwork.width - 1 : 1
					y: artwork.height - 1
				}
				PathLine {
					x: root.kind === "previous" ? artwork.width - 1 : 1
					y: 1
				}
			}
		}

		Rectangle {
			visible: root.kind === "previous" || root.kind === "next"
			x: root.kind === "previous" ? 1 : artwork.width - width - 1
			anchors.verticalCenter: parent.verticalCenter
			width: 2
			height: artwork.height - 2
			radius: 0
			color: Theme.moduleValue
		}

		Shape {
			anchors.fill: parent
			visible: root.kind === "toggle"
			opacity: root.playing ? 0 : 1
			scale: root.playing ? 0.55 : 1
			antialiasing: true

			ShapePath {
				fillColor: Theme.moduleValue
				strokeWidth: 0
				startX: 2
				startY: 1
				PathLine { x: artwork.width - 1; y: artwork.height / 2 }
				PathLine { x: 2; y: artwork.height - 1 }
				PathLine { x: 2; y: 1 }
			}

			Behavior on opacity {
				NumberAnimation { duration: ShellConfig.bar.mediaAnimationMs }
			}
			Behavior on scale {
				NumberAnimation {
					duration: ShellConfig.bar.mediaAnimationMs
					easing.type: Easing.OutBack
				}
			}
		}

		Item {
			anchors.fill: parent
			visible: root.kind === "toggle"
			opacity: root.playing ? 1 : 0
			scale: root.playing ? 1 : 0.55

			Rectangle {
				anchors.left: parent.left
				anchors.leftMargin: 2
				anchors.verticalCenter: parent.verticalCenter
				width: 3
				height: parent.height - 2
				radius: 0
				color: Theme.moduleValue
			}

			Rectangle {
				anchors.right: parent.right
				anchors.rightMargin: 2
				anchors.verticalCenter: parent.verticalCenter
				width: 3
				height: parent.height - 2
				radius: 0
				color: Theme.moduleValue
			}

			Behavior on opacity {
				NumberAnimation { duration: ShellConfig.bar.mediaAnimationMs }
			}
			Behavior on scale {
				NumberAnimation {
					duration: ShellConfig.bar.mediaAnimationMs
					easing.type: Easing.OutBack
				}
			}
		}
	}

	MouseArea {
		id: pointer

		anchors.fill: parent
		enabled: root.available
		hoverEnabled: true
		cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
		onClicked: root.triggered()
	}
}
