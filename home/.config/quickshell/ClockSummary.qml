import QtQuick

Item {
	id: root

	required property date currentDate
	property bool active: false

	signal clicked
	signal secondaryClicked

	readonly property bool hovered: pointer.containsMouse

	implicitWidth: clockRow.implicitWidth
	implicitHeight: ShellConfig.bar.mediaButtonSize
	scale: pointer.pressed ? 0.98 : root.hovered ? 1.015 : 1

	Behavior on scale {
		NumberAnimation {
			duration: ShellConfig.visuals.motionFast
			easing.type: Easing.OutCubic
		}
	}

	Rectangle {
		anchors.fill: parent
		radius: ShellConfig.visuals.controlRadius
		color: root.active
			? Theme.accentWashStrong
			: root.hovered ? Theme.panelRaised : "transparent"
		border.width: root.active || root.hovered
			? ShellConfig.bar.hairlineThickness : 0
		border.color: root.active
			? Theme.frameBorder : Theme.frameBorderSoft

		Behavior on color {
			ColorAnimation { duration: ShellConfig.visuals.motionFast }
		}
	}

	Row {
		id: clockRow

		height: parent.height
		spacing: ShellConfig.bar.clockSummaryPadding

		Text {
			width: ShellConfig.bar.clockTimeValueWidth
			height: parent.height
			text: Qt.formatDateTime(root.currentDate, "HH:mm")
			color: Theme.moduleValue
			horizontalAlignment: Text.AlignHCenter
			verticalAlignment: Text.AlignVCenter
			font {
				family: ShellConfig.typography.monoFamily
				pixelSize: ShellConfig.bar.valueFontSize
				weight: Font.DemiBold
			}
		}

		ElegantSeparator {
			anchors.verticalCenter: parent.verticalCenter
		}

		Text {
			width: ShellConfig.bar.dateValueWidth
			height: parent.height
			text: Qt.formatDateTime(root.currentDate,
				"ddd, MMM d").toLowerCase()
			color: Theme.moduleValue
			horizontalAlignment: Text.AlignLeft
			verticalAlignment: Text.AlignVCenter
			font {
				family: ShellConfig.typography.monoFamily
				pixelSize: ShellConfig.bar.dateFontSize
				weight: Font.DemiBold
			}
		}
	}

	MouseArea {
		id: pointer

		anchors {
			fill: parent
			topMargin: -ShellConfig.bar.popupTriggerTopExtension
		}
		hoverEnabled: true
		acceptedButtons: Qt.LeftButton | Qt.RightButton
		cursorShape: Qt.PointingHandCursor
		onClicked: event => {
			if (event.button === Qt.RightButton)
				root.secondaryClicked()
			else
				root.clicked()
		}
	}
}
