import QtQuick
import Quickshell.Services.Mpris

Item {
	id: root

	readonly property var activePlayer: Mpris.players.values.find(player => player.isPlaying)
		?? Mpris.players.values[0]
		?? null
	readonly property bool active: activePlayer !== null
	readonly property bool hovered: summaryHover.hovered
	readonly property string trackText: {
		if (!activePlayer)
			return "Nothing playing"

		const title = activePlayer.trackTitle || activePlayer.identity || "Unknown track"
		const artist = activePlayer.trackArtist
		return artist ? `${title} — ${artist}` : title
	}

	implicitWidth: ShellConfig.bar.mediaSummaryWidth
	implicitHeight: ShellConfig.bar.mediaButtonSize

	Rectangle {
		anchors.fill: parent
		radius: 0
		color: root.hovered ? Theme.panelRaised : "transparent"
		border.width: root.hovered ? ShellConfig.bar.contentBorderWidth : 0
		border.color: Theme.frameBorder

		Behavior on color {
			ColorAnimation { duration: ShellConfig.bar.mediaAnimationMs }
		}
	}

	Row {
		id: summaryRow

		anchors.centerIn: parent
		spacing: ShellConfig.bar.mediaSpacing

		Text {
			height: ShellConfig.bar.mediaButtonSize
			text: "med:"
			color: Theme.moduleLabel
			verticalAlignment: Text.AlignVCenter
			font {
				family: ShellConfig.typography.monoFamily
				styleName: ShellConfig.typography.fineStyle
				pixelSize: ShellConfig.bar.valueFontSize
				weight: ShellConfig.bar.labelFontWeight
			}
		}

		Text {
			width: ShellConfig.bar.mediaTextWidth
			height: ShellConfig.bar.mediaButtonSize
			text: root.trackText.toLowerCase()
			color: Theme.moduleValue
			elide: Text.ElideRight
			verticalAlignment: Text.AlignVCenter
			font {
				family: ShellConfig.typography.monoFamily
				pixelSize: ShellConfig.bar.mediaFontSize
			}
		}
	}

	Item {
		anchors {
			fill: parent
			topMargin: -ShellConfig.bar.popupTriggerTopExtension
		}

		HoverHandler {
			id: summaryHover
		}
	}
}
