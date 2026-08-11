import QtQuick
import QtQuick.Shapes

Item {
	id: root

	signal clicked

	property color iconColour: pointer.containsMouse
		? Theme.statusDanger
		: Theme.moduleValue

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
		radius: 0
		color: pointer.pressed
			? Theme.panelHighlight
			: pointer.containsMouse ? Theme.panelRaised : "transparent"
		border.width: pointer.containsMouse ? ShellConfig.bar.contentBorderWidth : 0
		border.color: Theme.statusDanger

		Behavior on color {
			ColorAnimation { duration: ShellConfig.bar.menuAnimationMs }
		}
	}

	Item {
		id: powerMark

		anchors.centerIn: parent
		width: ShellConfig.bar.powerIconSize
		height: ShellConfig.bar.powerIconSize
		rotation: pointer.containsMouse ? 10 : 0

		Behavior on rotation {
			NumberAnimation {
				duration: ShellConfig.bar.menuAnimationMs
				easing.type: Easing.OutBack
			}
		}

		Shape {
			anchors.fill: parent
			antialiasing: true

			ShapePath {
				fillColor: "transparent"
				strokeColor: root.iconColour
				strokeWidth: ShellConfig.bar.powerIconStrokeWidth
				capStyle: ShapePath.RoundCap

				PathAngleArc {
					centerX: powerMark.width / 2
					centerY: powerMark.height / 2 + 1
					radiusX: powerMark.width / 2 - 1
					radiusY: powerMark.height / 2 - 1
					startAngle: -42
					sweepAngle: 264
					moveToStart: true
				}
			}
		}

		Rectangle {
			anchors.horizontalCenter: parent.horizontalCenter
			y: 0
			width: ShellConfig.bar.powerIconStrokeWidth
			height: powerMark.height / 2 + 1
			radius: width / 2
			color: root.iconColour
		}
	}

	Behavior on iconColour {
		ColorAnimation { duration: ShellConfig.bar.menuAnimationMs }
	}

	MouseArea {
		id: pointer

		anchors.fill: parent
		anchors.rightMargin: -ShellConfig.bar.cornerButtonHorizontalExtension
		anchors.topMargin: -ShellConfig.bar.cornerButtonVerticalExtension
		anchors.bottomMargin: -ShellConfig.bar.cornerButtonVerticalExtension
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: root.clicked()
	}
}
