import QtQuick
import qs.components

Item {
	id: root

	required property var player
	required property bool triggerHovered

	readonly property bool hovered: popupHover.hovered
	readonly property bool shouldOpen: triggerHovered || hovered
	readonly property real visualTop: ShellConfig.bar.mediaPopupHoverBridge
		- ShellConfig.bar.mediaPopupBorderOverlap
	readonly property real panelHeight: ShellConfig.bar.mediaPopupHeight
		+ ShellConfig.bar.mediaPopupBorderOverlap
	readonly property real animationOverflow:
		ShellConfig.bar.mediaPopupBounceBridge
	readonly property real slideOffset: -panelHeight * offsetScale
	readonly property real revealHeight: visible
		? panelHeight + animationOverflow : 0
	readonly property real trackLength: player?.length ?? 0
	readonly property real trackPosition: player?.position ?? 0
	readonly property real progress: trackLength > 0 && trackLength < 2147483647
		? Math.max(0, Math.min(1, trackPosition / trackLength))
		: 0
	property real offsetScale: shouldOpen ? 0 : 1

	function artworkUrl(): string {
		if (!player)
			return ""
		if (player.trackArtUrl)
			return player.trackArtUrl

		const url = player.metadata["xesam:url"] ?? ""
		if (url.startsWith("https://www.youtube.com/watch")) {
			const id = url.match(/[?&]v=([\w-]{11})/)?.[1]
			return id ? `https://img.youtube.com/vi/${id}/hqdefault.jpg` : ""
		}
		return ""
	}

	visible: offsetScale < 1
	width: ShellConfig.bar.mediaPopupWidth
	height: visualTop + panelHeight + animationOverflow

	Behavior on offsetScale {
		Anim {}
	}

	Timer {
		running: root.visible && (root.player?.isPlaying ?? false)
		interval: ShellConfig.bar.mediaPopupProgressUpdateMs
		repeat: true
		triggeredOnStart: true
		onTriggered: root.player?.positionChanged()
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

			Item {
				id: content

				x: ShellConfig.bar.mediaPopupPadding
				y: ShellConfig.bar.mediaPopupContentTop - root.visualTop
				width: parent.width - ShellConfig.bar.mediaPopupPadding * 2
				height: ShellConfig.bar.mediaPopupArtworkSize

				StyledClippingRect {
					id: artworkFrame

					width: ShellConfig.bar.mediaPopupArtworkSize
					height: width
					radius: 0
					color: Theme.frameBorder

					StyledClippingRect {
						anchors.fill: parent
						anchors.margins: 1
						radius: 0
						color: Theme.panelRaised

						Text {
							anchors.centerIn: parent
							text: "no art"
							color: Theme.textMuted
							font {
								family: ShellConfig.typography.monoFamily
								pixelSize: ShellConfig.bar.mediaPopupArtistSize
								weight: Font.DemiBold
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

							Behavior on opacity {
								NumberAnimation { duration: ShellConfig.bar.mediaAnimationMs }
							}
						}
					}
				}

				Item {
					id: details

					x: artworkFrame.width + ShellConfig.bar.mediaPopupArtworkGap
					width: parent.width - x
					height: parent.height

					Text {
						id: title

						width: parent.width
						text: root.player?.trackTitle || root.player?.identity || "nothing playing"
						color: Theme.moduleValue
						elide: Text.ElideRight
						horizontalAlignment: Text.AlignHCenter
						font {
							family: ShellConfig.typography.monoFamily
							pixelSize: ShellConfig.bar.mediaPopupTitleSize
							weight: Font.DemiBold
						}
					}

					Text {
						id: artist

						y: title.height + 3
						width: parent.width
						text: root.player?.trackArtist || root.player?.identity || "play sum music"
						color: Theme.textMuted
						elide: Text.ElideRight
						horizontalAlignment: Text.AlignHCenter
						font {
							family: ShellConfig.typography.monoFamily
							pixelSize: ShellConfig.bar.mediaPopupArtistSize
						}
					}

					Rectangle {
						id: progressTrack

						y: artist.y + artist.height + 10
						width: parent.width
						height: ShellConfig.bar.mediaPopupProgressHeight
						radius: 0
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
					}

					Row {
						y: progressTrack.y + progressTrack.height + 11
						anchors.horizontalCenter: parent.horizontalCenter
						spacing: ShellConfig.bar.mediaPopupControlSpacing

						MediaControlButton {
							kind: "previous"
							available: root.player?.canGoPrevious ?? false
							onTriggered: root.player?.previous()
						}

						MediaControlButton {
							kind: "toggle"
							playing: root.player?.isPlaying ?? false
							available: (root.player?.canTogglePlaying ?? false)
								|| (root.player?.canPlay ?? false)
							onTriggered: root.player?.togglePlaying()
						}

						MediaControlButton {
							kind: "next"
							available: root.player?.canGoNext ?? false
							onTriggered: root.player?.next()
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
