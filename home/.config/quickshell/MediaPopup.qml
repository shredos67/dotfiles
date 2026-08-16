import QtQuick
import qs.components

Item {
	id: root

	required property var player
	required property bool triggerHovered
	property int preferredWidth: 392
	property int preferredHeight: 164
	property int artworkSize: 112
	property int padding: 14
	property int artworkGap: 15
	property int cornerRadius: 13
	property int spectrumBands: 22

	readonly property bool hovered: popupHover.hovered
	readonly property bool shouldOpen: triggerHovered || hovered
	readonly property real visualTop: ShellConfig.bar.mediaPopupHoverBridge
		- ShellConfig.bar.mediaPopupBorderOverlap
	readonly property real panelHeight: preferredHeight
		+ ShellConfig.bar.mediaPopupBorderOverlap
	readonly property real animationOverflow:
		ShellConfig.bar.mediaPopupBounceBridge
	readonly property real slideOffset: -panelHeight * offsetScale
	readonly property real revealHeight: visible
		? panelHeight + animationOverflow : 0
	readonly property real trackLength: player ? player.length : 0
	readonly property real trackPosition: player ? player.position : 0
	readonly property real progress: trackLength > 0 && trackLength < 2147483647
		? Math.max(0, Math.min(1, trackPosition / trackLength))
		: 0
	readonly property real averageLevel: AudioSpectrum.levelFor(0, 1)
	property real offsetScale: shouldOpen ? 0 : 1

	function artworkUrl(): string {
		if (!player)
			return ""
		if (player.trackArtUrl)
			return player.trackArtUrl

		const url = player.metadata["xesam:url"] ?? ""
		if (url.startsWith("https://www.youtube.com/watch")) {
			const match = url.match(/[?&]v=([\w-]{11})/)
			const id = match ? match[1] : ""
			return id ? `https://img.youtube.com/vi/${id}/hqdefault.jpg` : ""
		}
		return ""
	}

	function formatTime(seconds: real): string {
		if (!isFinite(seconds) || seconds < 0)
			return "0:00"

		const whole = Math.floor(seconds)
		const minutes = Math.floor(whole / 60)
		const remainder = whole % 60
		return `${minutes}:${remainder < 10 ? "0" : ""}${remainder}`
	}

	function seekTo(ratio: real): void {
		if (!player || !player.positionSupported || trackLength <= 0)
			return

		player.position = Math.max(0, Math.min(1, ratio)) * trackLength
	}

	visible: offsetScale < 1
	width: preferredWidth
	height: visualTop + panelHeight + animationOverflow

	Behavior on offsetScale {
		Anim {}
	}

	Timer {
		running: root.visible && (root.player ? root.player.isPlaying : false)
		interval: ShellConfig.bar.mediaPopupProgressUpdateMs
		repeat: true
		triggeredOnStart: true
		onTriggered: {
			if (root.player)
				root.player.positionChanged()
		}
	}

	PopupBridge {
		active: root.shouldOpen
		width: root.width
	}

	Item {
		x: 0
		y: root.visualTop
		width: root.width
		height: root.panelHeight + root.animationOverflow
		clip: true

		Item {
			x: 0
			y: root.slideOffset
			width: root.width
			height: root.panelHeight

			PopupChrome { anchors.fill: parent }

			Rectangle {
				x: root.padding + 4
				y: 15
				width: root.artworkSize
				height: width
				radius: root.cornerRadius
				color: Qt.rgba(0, 0, 0, 0.30)
				opacity: 0.72 + root.averageLevel * 0.28
				scale: 1 + root.averageLevel * 0.025

				Behavior on scale {
					NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
				}
			}

			StyledClippingRect {
				id: artworkFrame

				x: root.padding
				y: 11
				width: root.artworkSize
				height: width
				radius: root.cornerRadius
				color: Theme.frameBorder

				StyledClippingRect {
					anchors.fill: parent
					anchors.margins: 2
					radius: Math.max(0, root.cornerRadius - 2)
					color: Theme.panelRaised

					Rectangle {
						anchors.centerIn: parent
						width: parent.width * 0.52
						height: width
						radius: width / 2
						color: "transparent"
						border.width: 1
						border.color: Theme.frameBorderSoft

						Rectangle {
							anchors.centerIn: parent
							width: parent.width * 0.22
							height: width
							radius: width / 2
							color: Theme.moduleLabel
							opacity: 0.7
						}
					}

					Image {
						anchors.fill: parent
						source: root.artworkUrl()
						asynchronous: true
						cache: true
						fillMode: Image.PreserveAspectCrop
						sourceSize: Qt.size(width, height)
						opacity: status === Image.Ready ? 1 : 0
						scale: status === Image.Ready
							? 1 + root.averageLevel * 0.018 : 1

						Behavior on opacity {
							NumberAnimation { duration: 220 }
						}

						Behavior on scale {
							NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
						}
					}

					Rectangle {
						anchors {
							left: parent.left
							right: parent.right
							bottom: parent.bottom
						}
						height: 18
						color: Theme.panel
						opacity: 0.38
					}

					SpectrumBars {
						anchors {
							left: parent.left
							right: parent.right
							bottom: parent.bottom
							margins: 4
						}
						height: 12
						active: root.shouldOpen
						count: 18
						spacing: 1.5
						minimumLevel: 0.08
						levelGain: 0.82
					}
				}
			}

			Item {
				id: details

				x: root.padding + root.artworkSize + root.artworkGap
				y: 11
				width: parent.width - x - root.padding
				height: parent.height - y - 10

				Text {
					id: title

					width: parent.width
					text: root.player
						? (root.player.trackTitle || root.player.identity || "nothing playing")
						: "nothing playing"
					color: Theme.moduleValue
					elide: Text.ElideRight
					font {
						family: ShellConfig.typography.monoFamily
						pixelSize: 16
						weight: Font.DemiBold
					}
				}

				Text {
					id: artist

					y: title.height + 1
					width: parent.width
					text: root.player
						? (root.player.trackArtist || root.player.identity || "") : ""
					color: Theme.textMuted
					elide: Text.ElideRight
					font {
						family: ShellConfig.typography.monoFamily
						pixelSize: 12
					}
				}

				SpectrumBars {
					id: spectrum

					y: 44
					width: parent.width
					height: 34
					active: root.shouldOpen
					count: root.spectrumBands
					spacing: 2
					minimumLevel: 0.06
					levelGain: 1.08
				}

				Rectangle {
					id: progressTrack

					y: 86
					width: parent.width
					height: 6
					radius: height / 2
					color: Theme.panelHighlight

					Rectangle {
						width: parent.width * root.progress
						height: parent.height
						radius: parent.radius
						color: Theme.moduleLabel

						Behavior on width {
							NumberAnimation {
								duration: ShellConfig.bar.mediaPopupProgressUpdateMs
								easing.type: Easing.Linear
							}
						}
					}

					Rectangle {
						visible: progressPointer.containsMouse
						x: Math.max(0, Math.min(parent.width - width,
							parent.width * root.progress - width / 2))
						anchors.verticalCenter: parent.verticalCenter
						width: 10
						height: width
						radius: width / 2
						color: Theme.moduleValue
					}

					MouseArea {
						id: progressPointer

						anchors {
							fill: parent
							topMargin: -6
							bottomMargin: -6
						}
						enabled: root.player
							? root.player.positionSupported : false
						hoverEnabled: true
						cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
						onPressed: mouse => root.seekTo(mouse.x / width)
						onPositionChanged: mouse => {
							if (pressed)
								root.seekTo(mouse.x / width)
						}
					}
				}

				Text {
					y: 97
					text: root.formatTime(root.trackPosition)
					color: Theme.textMuted
					font {
						family: ShellConfig.typography.monoFamily
						pixelSize: 10
					}
				}

				Text {
					y: 97
					anchors.right: parent.right
					text: root.formatTime(root.trackLength)
					color: Theme.textMuted
					font {
						family: ShellConfig.typography.monoFamily
						pixelSize: 10
					}
				}

				Row {
					y: 116
					anchors.horizontalCenter: parent.horizontalCenter
					spacing: 14

					MediaControlButton {
						kind: "previous"
						available: root.player
							? root.player.canGoPrevious : false
						onTriggered: {
							if (root.player)
								root.player.previous()
						}
					}

					MediaControlButton {
						kind: "toggle"
						playing: root.player ? root.player.isPlaying : false
						available: root.player
							? (root.player.canTogglePlaying || root.player.canPlay)
							: false
						onTriggered: {
							if (root.player)
								root.player.togglePlaying()
						}
					}

					MediaControlButton {
						kind: "next"
						available: root.player ? root.player.canGoNext : false
						onTriggered: {
							if (root.player)
								root.player.next()
						}
					}
				}
			}
		}
	}

	HoverHandler {
		id: popupHover
		enabled: root.offsetScale < 1
	}
}
