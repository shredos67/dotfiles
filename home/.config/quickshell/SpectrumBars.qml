import QtQuick

Item {
	id: root

	property int count: 18
	property real spacing: 2
	property real minimumLevel: 0.06
	property real levelGain: 1
	property color lowColour: Theme.accentSecondary
	property color middleColour: Theme.moduleLabel
	property color highColour: Theme.frameBorder

	Row {
		anchors.fill: parent
		spacing: root.spacing

		Repeater {
			model: root.count

			Item {
				required property int index

				width: Math.max(1, (root.width
					- root.spacing * (root.count - 1)) / root.count)
				height: root.height

				Rectangle {
					anchors {
						left: parent.left
						right: parent.right
						bottom: parent.bottom
					}
					height: Math.max(width, parent.height * Math.max(
						root.minimumLevel,
						Math.min(1, AudioSpectrum.levelFor(index, root.count)
							* root.levelGain)))
					radius: width / 2
					opacity: 0.56 + AudioSpectrum.levelFor(index, root.count) * 0.44
					gradient: Gradient {
						GradientStop { position: 0; color: root.highColour }
						GradientStop { position: 0.48; color: root.middleColour }
						GradientStop { position: 1; color: root.lowColour }
					}

					Behavior on height {
						NumberAnimation {
							duration: 72
							easing.type: Easing.OutCubic
						}
					}

					Behavior on opacity {
						NumberAnimation { duration: 90 }
					}
				}
			}
		}
	}
}
