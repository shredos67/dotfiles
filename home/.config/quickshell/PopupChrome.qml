import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.components

Item {
	id: root

	readonly property real edge: ShellConfig.frame.lineThickness
	readonly property real inset: ShellConfig.bar.popupInnerInset
	readonly property real cornerRadius: ShellConfig.bar.popupCornerRadius
	readonly property real faintRadius: Math.max(0, cornerRadius - inset / 2)
	readonly property real faintLeft: inset
	readonly property real faintRight: width - inset
	readonly property real faintBottom: height - inset

	RectangularShadow {
		anchors.fill: outerFrame
		visible: FloralSettings.shadows
		radius: 0
		topLeftRadius: 0
		topRightRadius: 0
		bottomLeftRadius: root.cornerRadius + root.edge
		bottomRightRadius: bottomLeftRadius
		blur: ShellConfig.visuals.shadowBlur
		spread: ShellConfig.visuals.shadowSpread
		offset: Qt.vector2d(0, ShellConfig.visuals.shadowOffsetY)
		color: Theme.shadowColor
		cached: true
	}

	StyledRect {
		id: outerFrame

		anchors.fill: parent
		radius: 0
		bottomLeftRadius: root.cornerRadius + root.edge
		bottomRightRadius: bottomLeftRadius
		color: Theme.frameBorder
	}

	StyledRect {
		id: panel

		x: root.edge
		width: parent.width - root.edge * 2
		height: parent.height - root.edge
		radius: 0
		bottomLeftRadius: root.cornerRadius
		bottomRightRadius: bottomLeftRadius
		color: Theme.panel

		Rectangle {
			anchors.fill: parent
			color: Theme.panelSheen
		}
	}

	Shape {
		anchors.fill: parent
		antialiasing: true
		preferredRendererType: Shape.CurveRenderer

		ShapePath {
			fillColor: "transparent"
			strokeColor: Theme.frameBorderFaint
			strokeWidth: ShellConfig.bar.hairlineThickness
			capStyle: ShapePath.FlatCap
			joinStyle: ShapePath.RoundJoin
			startX: root.faintLeft
			startY: 0

			PathLine {
				x: root.faintLeft
				y: root.faintBottom - root.faintRadius
			}
			PathCubic {
				x: root.faintLeft + root.faintRadius
				y: root.faintBottom
				control1X: root.faintLeft
				control1Y: root.faintBottom
				control2X: root.faintLeft + root.faintRadius
				control2Y: root.faintBottom
			}
			PathLine {
				x: root.faintRight - root.faintRadius
				y: root.faintBottom
			}
			PathCubic {
				x: root.faintRight
				y: root.faintBottom - root.faintRadius
				control1X: root.faintRight
				control1Y: root.faintBottom
				control2X: root.faintRight
				control2Y: root.faintBottom - root.faintRadius
			}
			PathLine {
				x: root.faintRight
				y: 0
			}
		}
	}

	Rectangle {
		anchors.horizontalCenter: parent.horizontalCenter
		y: root.faintBottom - height / 2
		width: ShellConfig.bar.separatorDiamondSize
		height: width
		rotation: 45
		color: Theme.panel
		border.width: ShellConfig.bar.hairlineThickness
		border.color: Theme.frameBorderSoft
	}
}
