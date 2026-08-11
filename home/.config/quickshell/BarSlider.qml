import QtQuick

Item {
	id: root

	required property real value

	signal moved(real value)

	property real pointerValue: value
	readonly property real visualValue: pointer.pressed
		? pointerValue
		: Math.max(0, Math.min(1, value))

	implicitHeight: ShellConfig.bar.controlSliderHeight

	onValueChanged: {
		if (!pointer.pressed)
			pointerValue = Math.max(0, Math.min(1, value))
	}

	function setFromX(position: real): void {
		pointerValue = Math.max(0, Math.min(1,
			(position - track.x) / track.width))
		moved(pointerValue)
	}

	Rectangle {
		id: track

		anchors {
			left: parent.left
			right: parent.right
			leftMargin: handle.width / 2
			rightMargin: handle.width / 2
			verticalCenter: parent.verticalCenter
		}
		height: ShellConfig.bar.controlSliderTrackHeight
		radius: 0
		color: Theme.panelHighlight

		Rectangle {
			width: parent.width * root.visualValue
			height: parent.height
			radius: parent.radius
			color: Theme.moduleLabel

			Behavior on width {
				enabled: !pointer.pressed
				NumberAnimation { duration: ShellConfig.bar.mediaAnimationMs }
			}
		}
	}

	Rectangle {
		id: handle

		x: track.x + track.width * root.visualValue - width / 2
		anchors.verticalCenter: parent.verticalCenter
		width: ShellConfig.bar.controlSliderHandleWidth
		height: ShellConfig.bar.controlSliderHandleHeight
		radius: 0
		color: pointer.pressed || pointer.containsMouse
			? Theme.frameBorder
			: Theme.moduleValue
		border.width: 1
		border.color: Theme.frameBorder

		Behavior on x {
			enabled: !pointer.pressed
			NumberAnimation { duration: ShellConfig.bar.mediaAnimationMs }
		}

		Behavior on color {
			ColorAnimation { duration: ShellConfig.bar.mediaAnimationMs }
		}
	}

	MouseArea {
		id: pointer

		anchors.fill: parent
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor

		onPressed: event => root.setFromX(event.x)
		onPositionChanged: event => {
			if (pressed)
				root.setFromX(event.x)
		}
		onWheel: event => {
			const direction = event.angleDelta.y > 0 ? 1 : -1
			const next = Math.max(0, Math.min(1, root.value
				+ direction * ShellConfig.bar.controlSliderWheelStep))
			root.pointerValue = next
			root.moved(next)
		}
	}
}
