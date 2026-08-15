import QtQuick
import QtQuick.Effects

Item {
	id: root

	default property alias content: contentLayer.data

	property color fillColor: Theme.panel
	property color borderColor: Theme.frameBorder
	property color innerBorderColor: Theme.frameBorderFaint
	property real radius: ShellConfig.visuals.surfaceRadius
	property real borderWidth: ShellConfig.frame.lineThickness
	property real innerInset: ShellConfig.visuals.innerInset
	property bool elevated: true
	property bool ornamented: false
	property real ornamentStrength: 0.16
	property real ornamentSize: Math.min(width, height) * 0.46

	RectangularShadow {
		anchors.fill: surface
		visible: root.elevated
		radius: root.radius
		blur: ShellConfig.visuals.shadowBlur
		spread: ShellConfig.visuals.shadowSpread
		offset: Qt.vector2d(0, ShellConfig.visuals.shadowOffsetY)
		color: Theme.shadowColor
		cached: true
	}

	Rectangle {
		id: surface

		anchors.fill: parent
		radius: root.radius
		color: root.fillColor
		border.width: root.borderWidth
		border.color: root.borderColor

		Rectangle {
			anchors.fill: parent
			anchors.margins: root.innerInset
			radius: Math.max(0, surface.radius - root.innerInset)
			color: "transparent"
			border.width: ShellConfig.visuals.innerLineWidth
			border.color: root.innerBorderColor
		}

		Rectangle {
			anchors.fill: parent
			anchors.margins: root.borderWidth
			radius: Math.max(0, surface.radius - root.borderWidth)
			color: Theme.panelSheen
		}
	}

	FloralCorner {
		visible: root.ornamented
		anchors {
			left: parent.left
			top: parent.top
		}
		width: root.ornamentSize
		height: width
		location: FloralCorner.TopLeft
		strength: root.ornamentStrength
	}

	FloralCorner {
		visible: root.ornamented
		anchors {
			right: parent.right
			bottom: parent.bottom
		}
		width: root.ornamentSize
		height: width
		location: FloralCorner.BottomRight
		strength: root.ornamentStrength
	}

	Item {
		id: contentLayer
		anchors.fill: parent
	}
}
