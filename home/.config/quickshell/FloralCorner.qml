import QtQuick
import Quickshell

Item {
	id: root
	visible: FloralSettings.ornaments

	enum Location {
		TopLeft,
		TopRight,
		BottomLeft,
		BottomRight
	}

	property int location: FloralCorner.TopLeft
	property color ornamentColor: Theme.frameBorder
	property real strength: 0.34

	readonly property rect clipRect: {
		switch (location) {
		case FloralCorner.TopRight:
			return Qt.rect(628, 0, 626, 626)
		case FloralCorner.BottomLeft:
			return Qt.rect(0, 628, 626, 626)
		case FloralCorner.BottomRight:
			return Qt.rect(628, 628, 626, 626)
		default:
			return Qt.rect(0, 0, 626, 626)
		}
	}

	Image {
		anchors.fill: parent
		source: `file://${Quickshell.env("HOME")}/.config/hypr/assets/imgborders-floral.png?theme=${encodeURIComponent(root.ornamentColor.toString())}`
		sourceClipRect: root.clipRect
		fillMode: Image.PreserveAspectFit
		smooth: true
		mipmap: true
		opacity: root.strength
		cache: true
	}
}
