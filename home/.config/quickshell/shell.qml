/*
 * if you wanna change the shell
 * edit shellconfig qml first
 * this file is a mess
 */

import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick.Shapes
import qs.modules
import qs.components.misc
import qs.WallpaperCarousel as WallpaperCarousel
import "." as Local

ShellRoot {
	id: root

	property int brightnessPercentage: 0
	readonly property var audioSink: Pipewire.defaultAudioSink
	readonly property real volume: audioSink && audioSink.audio
		? audioSink.audio.volume
		: 0

	function readBrightness(output: string): void {
		const fields = output.trim().split(",")
		if (fields.length < 4)
			return

		const value = parseInt(fields[3])
		if (!isNaN(value))
			brightnessPercentage = value
	}

	function setBrightness(value: real): void {
		const percentage = Math.round(Math.max(0, Math.min(1, value)) * 100)
		if (percentage === brightnessPercentage)
			return

		brightnessPercentage = percentage
		Quickshell.execDetached(["brightnessctl", "-e4", "-n2", "set", `${percentage}%`])
	}

	function changeBrightness(delta: int): void {
		setBrightness((brightnessPercentage + delta) / 100)
	}

	function setVolume(value: real): void {
		if (!audioSink || !audioSink.audio)
			return

		audioSink.audio.muted = false
		audioSink.audio.volume = Math.max(0, Math.min(1, value))
	}

	Process {
		running: true
		command: ["brightnessctl", "-m"]
		stdout: StdioCollector {
			onStreamFinished: root.readBrightness(text)
		}
	}

	CustomShortcut {
		name: "barBrightnessUp"
		description: "Increase brightness and update the bar"
		onPressed: root.changeBrightness(5)
	}

	CustomShortcut {
		name: "barBrightnessDown"
		description: "Decrease brightness and update the bar"
		onPressed: root.changeBrightness(-5)
	}

	GSFLoader {}
	NotificationCenter { id: notificationCenter }
	CaelestiaMenus {
		id: menus
		onActiveChanged: {
			if (active)
				notificationCenter.closePanel()
		}
	}
	WallpaperCarousel.Standalone {}

	PanelWindow {
	id: bar

	anchors {
		top: true
		left: true
		right: true
	}

	implicitHeight: ShellConfig.bar.popupHostHeight
	exclusiveZone: ShellConfig.bar.exclusiveZone
	color: "transparent"
	mask: Region {
		width: bar.width
		height: ShellConfig.bar.surfaceHeight

		Region {
			x: mediaPopup.x
			y: mediaPopup.y + mediaPopup.visualTop
			width: mediaPopup.width
			height: mediaPopup.revealHeight
		}

		Region {
			x: networkPopup.x
			y: networkPopup.y + networkPopup.visualTop
			width: networkPopup.width
			height: networkPopup.revealHeight
		}

		Region {
			x: brightnessPopup.x
			y: brightnessPopup.y + brightnessPopup.visualTop
			width: brightnessPopup.width
			height: brightnessPopup.revealHeight
		}

		Region {
			x: volumePopup.x
			y: volumePopup.y + volumePopup.visualTop
			width: volumePopup.width
			height: volumePopup.revealHeight
		}

	}

	SystemClock {
		id: clock
		precision: SystemClock.Minutes
	}

	PwObjectTracker {
		objects: [root.audioSink]
	}

	Rectangle {
		id: barSurface
		anchors {
			left: parent.left
			right: parent.right
			top: parent.top
		}
		height: ShellConfig.bar.surfaceHeight
		color: Theme.panel

		Rectangle {
			anchors.fill: parent
			color: Theme.panelSheen
		}

		Rectangle {
			anchors {
				left: parent.left
				right: parent.right
				bottom: parent.bottom
				bottomMargin: ShellConfig.bar.engravedInset
			}
			height: ShellConfig.bar.hairlineThickness
			color: Theme.frameBorderFaint
		}

		Rectangle {
			anchors {
				left: parent.left
					leftMargin: 0
					right: parent.right
					rightMargin: 0
				bottom: parent.bottom
		}

			height: ShellConfig.frame.lineThickness
			color: Theme.frameBorder
			z: ShellConfig.frame.borderZ
		}

	}
	Item {
		id: notchSafeArea
		anchors {
			horizontalCenter: parent.horizontalCenter
			top: parent.top
			bottom: barSurface.bottom
		}
		width: ShellConfig.bar.notchWidth

		Item {
			anchors {
				horizontalCenter: parent.horizontalCenter
				bottom: parent.bottom
				bottomMargin: ShellConfig.bar.engravedInset - 2
			}
			width: ShellConfig.bar.centreOrnamentWidth
			height: ShellConfig.bar.centreOrnamentHeight

			Rectangle {
				anchors.centerIn: parent
				width: parent.width
				height: ShellConfig.bar.hairlineThickness
				color: Theme.frameBorderFaint
			}

		}
	}

	Item {
		anchors {
			left: parent.left
			right: notchSafeArea.left
			top: parent.top
			bottom: barSurface.bottom
		}
		clip: true

		Row {
			anchors {
				left: parent.left
				leftMargin: ShellConfig.bar.contentMargin
				verticalCenter: parent.verticalCenter
				verticalCenterOffset: -2
			}
      spacing: ShellConfig.bar.leftSpacing

			FedoraLauncherButton {
				anchors.verticalCenter: parent.verticalCenter
				onClicked: notificationCenter.togglePanel()
			}

			Text {
				anchors.verticalCenter: parent.verticalCenter
				text: Qt.formatDateTime(clock.date, "HH:mm")
				color: Theme.moduleValue
				font {
					family: ShellConfig.typography.monoFamily
					pixelSize: ShellConfig.bar.valueFontSize
					weight: Font.DemiBold
				}
			}

			ElegantSeparator {
				anchors.verticalCenter: parent.verticalCenter
			}

			Text {
				anchors.verticalCenter: parent.verticalCenter
				width: ShellConfig.bar.dateValueWidth
				text: Qt.formatDateTime(clock.date, "ddd, MMM d").toLowerCase()
				color: Theme.moduleValue
				font {
					family: ShellConfig.typography.monoFamily
					pixelSize: ShellConfig.bar.dateFontSize
				}
      }

      ElegantSeparator {
				anchors.verticalCenter: parent.verticalCenter
			}

      Text {
				anchors.verticalCenter: parent.verticalCenter
        text: "ws:"
				color: Theme.moduleLabel
				font {
					family: ShellConfig.typography.monoFamily
					styleName: ShellConfig.typography.fineStyle
					pixelSize: ShellConfig.bar.labelFontSize
					weight: ShellConfig.bar.labelFontWeight
					letterSpacing: ShellConfig.bar.labelLetterSpacing
				}
			}

			WorkspacesModule {
				anchors.verticalCenter: parent.verticalCenter
			}

      ElegantSeparator {
				anchors.verticalCenter: parent.verticalCenter
			}

      Text {
				anchors.verticalCenter: parent.verticalCenter
        text: "window:"
				color: Theme.moduleLabel
				font {
					family: ShellConfig.typography.monoFamily
					styleName: ShellConfig.typography.fineStyle
					pixelSize: ShellConfig.bar.labelFontSize
					weight: ShellConfig.bar.labelFontWeight
					letterSpacing: ShellConfig.bar.labelLetterSpacing
				}
			}
	    	WindowModule {
				width: ShellConfig.bar.windowTitleWidth
				maximumWidth: ShellConfig.bar.windowTitleWidth
				anchors.verticalCenter: parent.verticalCenter
			}
		}
	}

	Item {
		id: rightArea

		anchors {
			left: notchSafeArea.right
			right: parent.right
			top: parent.top
			bottom: barSurface.bottom
		}
		clip: true

		Row {
			id: rightModules

			anchors {
				right: parent.right
				rightMargin: ShellConfig.bar.contentMargin
				verticalCenter: parent.verticalCenter
				verticalCenterOffset: -2
			}
      spacing: ShellConfig.bar.rightSpacing

			MediaSummary {
				id: mediaSummary
				anchors.verticalCenter: parent.verticalCenter
			}

      ElegantSeparator {
				anchors.verticalCenter: parent.verticalCenter
			}

			Local.NetworkSummary {
				id: networkSummary
				anchors.verticalCenter: parent.verticalCenter
			}

      ElegantSeparator {
				anchors.verticalCenter: parent.verticalCenter
      }

			ControlSummary {
				id: brightnessSummary
				anchors.verticalCenter: parent.verticalCenter
				label: "brt"
				value: root.brightnessPercentage / 100
			}

      ElegantSeparator {
				anchors.verticalCenter: parent.verticalCenter
      }

			ControlSummary {
				id: volumeSummary
				anchors.verticalCenter: parent.verticalCenter
				label: "vol"
				value: root.volume
			}

      ElegantSeparator {
				anchors.verticalCenter: parent.verticalCenter
      }

			BatteryModule {
				anchors.verticalCenter: parent.verticalCenter
			}

			ElegantSeparator {
				anchors.verticalCenter: parent.verticalCenter
			}

			PowerMenuButton {
				anchors.verticalCenter: parent.verticalCenter
				onClicked: menus.toggleSession()
			}
		}
  }

	MediaPopup {
		id: mediaPopup

		player: mediaSummary.activePlayer
		triggerHovered: mediaSummary.hovered
		x: {
			const center = rightArea.x + rightModules.x
				+ mediaSummary.x + mediaSummary.width / 2
			return Math.max(0, Math.min(bar.width - width,
				center - width / 2))
		}
		y: ShellConfig.bar.surfaceHeight - ShellConfig.bar.mediaPopupHoverBridge
		z: ShellConfig.frame.borderZ + 1
	}

	Local.NetworkPopup {
		id: networkPopup

		connectedDevice: networkSummary.connectedDevice
		wifi: networkSummary.wifi
		activeNetwork: networkSummary.activeNetwork
		connectionName: networkSummary.connectionName
		triggerHovered: networkSummary.hovered
		x: {
			const center = rightArea.x + rightModules.x
				+ networkSummary.x + networkSummary.width / 2
			return Math.max(0, Math.min(bar.width - width,
				center - width / 2))
		}
		y: ShellConfig.bar.surfaceHeight - ShellConfig.bar.mediaPopupHoverBridge
		z: ShellConfig.frame.borderZ + 1
	}

	ControlPopup {
		id: brightnessPopup

		label: "Brightness"
		value: root.brightnessPercentage / 100
		triggerHovered: brightnessSummary.hovered
		x: {
			const center = rightArea.x + rightModules.x
				+ brightnessSummary.x + brightnessSummary.width / 2
			return Math.max(0, Math.min(bar.width - width,
				center - width / 2))
		}
		y: ShellConfig.bar.surfaceHeight - ShellConfig.bar.mediaPopupHoverBridge
		z: ShellConfig.frame.borderZ + 1

		onValueMoved: value => root.setBrightness(value)
	}

	ControlPopup {
		id: volumePopup

		label: "Volume"
		value: root.volume
		triggerHovered: volumeSummary.hovered
		x: {
			const center = rightArea.x + rightModules.x
				+ volumeSummary.x + volumeSummary.width / 2
			return Math.max(0, Math.min(bar.width - width,
				center - width / 2))
		}
		y: ShellConfig.bar.surfaceHeight - ShellConfig.bar.mediaPopupHoverBridge
		z: ShellConfig.frame.borderZ + 1

		onValueMoved: value => root.setVolume(value)
	}

	Shape {
		visible: false
		z: ShellConfig.frame.borderZ
		width: ShellConfig.frame.cornerSize
		height: ShellConfig.frame.cornerSize
		rotation: 180
		transformOrigin: Item.Center
		anchors {
			left: parent.left
			leftMargin: -1
			top: barSurface.bottom
			topMargin: 0
		}

		ShapePath {
			fillColor: Theme.panel
			strokeWidth: 0
			startX: 0
			startY: ShellConfig.frame.cornerSize

			PathLine { x: ShellConfig.frame.cornerSize; y: ShellConfig.frame.cornerSize }
			PathLine { x: ShellConfig.frame.cornerSize; y: 0 }
			PathCubic {
				x: 0
				y: ShellConfig.frame.curveEnd
				control1X: ShellConfig.frame.cornerSize
				control1Y: ShellConfig.frame.curveControl
				control2X: ShellConfig.frame.curveControl
				control2Y: ShellConfig.frame.curveEnd
			}
		}

		ShapePath {
			fillColor: "transparent"
			strokeColor: Theme.frameBorder
			strokeWidth: ShellConfig.frame.lineThickness
			capStyle: ShapePath.FlatCap
			startX: ShellConfig.frame.cornerSize
			startY: 0

			PathCubic {
				x: 0
				y: ShellConfig.frame.curveEnd
				control1X: ShellConfig.frame.cornerSize
				control1Y: ShellConfig.frame.curveControl
				control2X: ShellConfig.frame.curveControl
				control2Y: ShellConfig.frame.curveEnd
			}
		}
	}

	Shape {
		visible: false
		z: ShellConfig.frame.borderZ
		width: ShellConfig.frame.cornerSize
		height: ShellConfig.frame.cornerSize
		rotation: 180
		transformOrigin: Item.Center
		transform: Scale {
			origin.x: ShellConfig.frame.cornerSize / 2
			xScale: -1
		}
		anchors {
			right: parent.right
			rightMargin: -1
			top: barSurface.bottom
			topMargin: 0
		}

		ShapePath {
			fillColor: Theme.panel
			strokeWidth: 0
			startX: 0
			startY: ShellConfig.frame.cornerSize

			PathLine { x: ShellConfig.frame.cornerSize; y: ShellConfig.frame.cornerSize }
			PathLine { x: ShellConfig.frame.cornerSize; y: 0 }
			PathCubic {
				x: 0
				y: ShellConfig.frame.curveEnd
				control1X: ShellConfig.frame.cornerSize
				control1Y: ShellConfig.frame.curveControl
				control2X: ShellConfig.frame.curveControl
				control2Y: ShellConfig.frame.curveEnd
			}
		}

		ShapePath {
			fillColor: "transparent"
			strokeColor: Theme.frameBorder
			strokeWidth: ShellConfig.frame.lineThickness
			capStyle: ShapePath.FlatCap
			startX: ShellConfig.frame.cornerSize
			startY: 0

			PathCubic {
				x: 0
				y: ShellConfig.frame.curveEnd
				control1X: ShellConfig.frame.cornerSize
				control1Y: ShellConfig.frame.curveControl
				control2X: ShellConfig.frame.curveControl
				control2Y: ShellConfig.frame.curveEnd
			}
		}
	}
}
}
