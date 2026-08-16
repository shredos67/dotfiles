import QtQuick

Item {
	id: root

	required property string kind
	required property string label
	property bool active: false
	property bool destructive: false
	property bool hovered: pointer.containsMouse

	signal triggered
	onKindChanged: mark.requestPaint()

	implicitWidth: ShellConfig.scaled(62)
	implicitHeight: ShellConfig.scaled(47)
	opacity: enabled ? 1 : 0.34
	scale: pointer.pressed ? 0.94 : hovered ? 1.025 : 1

	Behavior on opacity {
		NumberAnimation {
			duration: FloralSettings.duration(ShellConfig.visuals.motionFast)
			easing.type: Easing.OutCubic
		}
	}

	Behavior on scale {
		NumberAnimation {
			duration: FloralSettings.duration(ShellConfig.visuals.motionFast)
			easing.type: Easing.OutCubic
		}
	}

	Rectangle {
		anchors.fill: parent
		radius: ShellConfig.visuals.controlRadius
		color: {
			if (root.destructive && root.hovered)
				return FloralSettings.withAlpha(Theme.statusDanger, 0.17)
			if (root.active)
				return Theme.accentWashStrong
			return root.hovered ? Theme.panelHighlight : Theme.panelRaised
		}
		border.width: root.active || root.hovered
			? ShellConfig.bar.buttonBorderWidth
			: ShellConfig.bar.hairlineThickness
		border.color: {
			if (root.destructive && root.hovered)
				return Theme.statusDanger
			if (root.active || root.hovered)
				return Theme.frameBorder
			return Theme.frameBorderFaint
		}

		Behavior on color {
			ColorAnimation {
				duration: FloralSettings.duration(ShellConfig.visuals.motionFast)
				easing.type: Easing.OutCubic
			}
		}

		Behavior on border.color {
			ColorAnimation {
				duration: FloralSettings.duration(ShellConfig.visuals.motionFast)
				easing.type: Easing.OutCubic
			}
		}
	}

	Canvas {
		id: mark

		anchors {
			horizontalCenter: parent.horizontalCenter
			top: parent.top
			topMargin: ShellConfig.scaled(7)
		}
		width: ShellConfig.scaled(17)
		height: width
		antialiasing: true
		property color markColor: root.destructive && root.hovered
			? Theme.statusDanger
			: root.active || root.hovered
				? Theme.moduleLabel : Theme.moduleValue

		onMarkColorChanged: requestPaint()
		onWidthChanged: requestPaint()
		onHeightChanged: requestPaint()
		onPaint: {
			const context = getContext("2d")
			const w = width
			const h = height
			const line = Math.max(1.4, ShellConfig.uiScale * 1.2)

			context.reset()
			context.strokeStyle = markColor
			context.fillStyle = markColor
			context.lineWidth = line
			context.lineCap = "round"
			context.lineJoin = "round"

			if (root.kind === "focus") {
				context.beginPath()
				context.moveTo(w * 0.08, h * 0.35)
				context.lineTo(w * 0.08, h * 0.08)
				context.lineTo(w * 0.35, h * 0.08)
				context.moveTo(w * 0.65, h * 0.08)
				context.lineTo(w * 0.92, h * 0.08)
				context.lineTo(w * 0.92, h * 0.35)
				context.moveTo(w * 0.92, h * 0.65)
				context.lineTo(w * 0.92, h * 0.92)
				context.lineTo(w * 0.65, h * 0.92)
				context.moveTo(w * 0.35, h * 0.92)
				context.lineTo(w * 0.08, h * 0.92)
				context.lineTo(w * 0.08, h * 0.65)
				context.stroke()
				context.beginPath()
				context.arc(w * 0.5, h * 0.5, line, 0, Math.PI * 2)
				context.fill()
			} else if (root.kind === "float") {
				context.strokeRect(w * 0.08, h * 0.26, w * 0.58, h * 0.58)
				context.strokeRect(w * 0.34, h * 0.08, w * 0.58, h * 0.58)
			} else if (root.kind === "maximize") {
				context.strokeRect(w * 0.10, h * 0.10, w * 0.80, h * 0.80)
				context.beginPath()
				context.moveTo(w * 0.12, h * 0.28)
				context.lineTo(w * 0.88, h * 0.28)
				context.stroke()
			} else if (root.kind === "pin") {
				context.save()
				context.translate(w * 0.5, h * 0.5)
				context.rotate(-Math.PI / 4)
				context.strokeRect(-w * 0.26, -h * 0.30, w * 0.52, h * 0.24)
				context.beginPath()
				context.moveTo(0, -h * 0.06)
				context.lineTo(0, h * 0.35)
				context.moveTo(-w * 0.18, h * 0.17)
				context.lineTo(w * 0.18, h * 0.17)
				context.stroke()
				context.restore()
			} else {
				context.beginPath()
				context.moveTo(w * 0.20, h * 0.20)
				context.lineTo(w * 0.80, h * 0.80)
				context.moveTo(w * 0.80, h * 0.20)
				context.lineTo(w * 0.20, h * 0.80)
				context.stroke()
			}
		}
	}

	Text {
		anchors {
			horizontalCenter: parent.horizontalCenter
			bottom: parent.bottom
			bottomMargin: ShellConfig.scaled(6)
		}
		text: root.label.toLowerCase()
		color: root.destructive && root.hovered
			? Theme.statusDanger
			: root.active ? Theme.moduleLabel : Theme.textMuted
		renderType: Text.NativeRendering
		font {
			family: ShellConfig.typography.monoFamily
			styleName: ShellConfig.typography.fineStyle
			pixelSize: ShellConfig.scaled(9)
			weight: root.active ? Font.DemiBold : Font.Medium
		}
	}

	MouseArea {
		id: pointer

		anchors.fill: parent
		hoverEnabled: true
		enabled: root.enabled
		cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
		onClicked: root.triggered()
	}
}
