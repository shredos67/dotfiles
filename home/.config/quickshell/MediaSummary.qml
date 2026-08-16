import QtQuick
import Quickshell.Services.Mpris

Item {
	id: root

	property int spectrumWidth: 30
	property int spectrumBands: 8
	property int cornerRadius: 8

	readonly property var activePlayer: Mpris.players.values.find(player => player.isPlaying)
		?? Mpris.players.values[0]
		?? null
	readonly property bool active: activePlayer !== null
	readonly property bool playing: activePlayer
		? activePlayer.isPlaying : false
	readonly property bool hovered: summaryHover.hovered
	readonly property string trackText: {
		if (!activePlayer)
			return "nothing playing"

		const title = activePlayer.trackTitle
			|| activePlayer.identity || "unknown track"
		const artist = activePlayer.trackArtist
		return artist ? `${title}  ·  ${artist}` : title
	}

	implicitWidth: ShellConfig.bar.mediaSummaryWidth
	implicitHeight: ShellConfig.bar.mediaButtonSize

	Rectangle {
		id: surface

		anchors.fill: parent
		radius: root.cornerRadius
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

		Item {
			width: root.spectrumWidth
			height: ShellConfig.bar.mediaButtonSize - 6

			SpectrumBars {
				anchors.fill: parent
				active: root.hovered
				count: root.spectrumBands
				spacing: 1.4
				minimumLevel: root.playing ? 0.12 : 0.06
				levelGain: 1.12
				opacity: root.active ? 1 : 0.38
			}
		}

		Text {
			width: ShellConfig.bar.mediaTextWidth
			height: ShellConfig.bar.mediaButtonSize
			text: root.trackText
			color: root.active ? Theme.moduleValue : Theme.textMuted
			elide: Text.ElideRight
			verticalAlignment: Text.AlignVCenter
			font {
				family: ShellConfig.typography.monoFamily
				pixelSize: ShellConfig.bar.mediaFontSize
			}

			Behavior on color {
				ColorAnimation { duration: ShellConfig.bar.mediaAnimationMs }
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
