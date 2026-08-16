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
	property bool calendarOpen: false
	readonly property var audioSink: Pipewire.defaultAudioSink
	readonly property real volume: audioSink && audioSink.audio
		? audioSink.audio.volume
		: 0
	readonly property bool muted: audioSink && audioSink.audio
		? audioSink.audio.muted
		: false

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

	function setCalendarOpen(open: bool): void {
		if (open) {
			notificationCenter.closePanel()
			menus.close()
			settingsPanel.close()
			dashboard.close()
			wallpaperPicker.close()
			trayPopup.close()
			windowPopup.close()
		}
		calendarOpen = open
	}

	function openSettingsPage(page: int): void {
		calendarOpen = false
		trayPopup.close()
		settingsPanel.openPage(page)
	}

	function closePanelByName(name: string): void {
		switch (name) {
		case "notifications":
			notificationCenter.closePanel()
			break
		case "settings":
			settingsPanel.close()
			break
		case "menus":
			menus.close()
			break
		case "wallpaper":
			wallpaperPicker.close()
			break
		case "dashboard":
			dashboard.close()
			break
		}
	}

	Connections {
		target: FloralShellState

		function onPanelClaimed(name: string): void {
			root.calendarOpen = false
			trayPopup.close()
			windowPopup.close()

			if (name !== "notifications")
				notificationCenter.closePanel()
			if (name !== "settings")
				settingsPanel.close()
			if (name !== "menus")
				menus.close()
			if (name !== "wallpaper")
				wallpaperPicker.close()
			if (name !== "dashboard")
				dashboard.close()
		}

		function onPanelCloseRequested(name: string): void {
			root.closePanelByName(name)
		}
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
	NotificationCenter {
		id: notificationCenter
		onPanelOpenChanged: {
			if (panelOpen) {
				FloralShellState.claimPanel("notifications")
				root.calendarOpen = false
				trayPopup.close()
				settingsPanel.close()
				menus.close()
			} else {
				FloralShellState.releasePanel("notifications")
			}
		}
	}
	FloralDock {}
	FloralIdleManager {}
	FloralSettingsPanel {
		id: settingsPanel
		onActiveChanged: {
			if (active)
				FloralShellState.claimPanel("settings")
			else
				FloralShellState.releasePanel("settings")
		}
		onCloseConflictsRequested: {
			root.calendarOpen = false
			trayPopup.close()
			notificationCenter.closePanel()
			menus.close()
		}
	}
	FloralDashboard {
		id: dashboard

		onCloseConflictsRequested:
			FloralShellState.claimPanel("dashboard")
		onActiveChanged: {
			if (active && FloralShellState.activePanel !== "dashboard")
				FloralShellState.claimPanel("dashboard")
			else if (!active)
				FloralShellState.releasePanel("dashboard")
		}
	}
	CaelestiaMenus {
		id: menus
		onActiveChanged: {
			if (active) {
				FloralShellState.claimPanel("menus")
				root.calendarOpen = false
				trayPopup.close()
				settingsPanel.close()
				notificationCenter.closePanel()
			} else if (!FloralSettings.dockLauncherOpen) {
				FloralShellState.releasePanel("menus")
			}
		}
	}
	WallpaperCarousel.Standalone {
		id: wallpaperPicker
		onActiveChanged: {
			if (active)
				FloralShellState.claimPanel("wallpaper")
			else
				FloralShellState.releasePanel("wallpaper")
		}
	}

	Connections {
		target: FloralSettings

		function onDockLauncherOpenChanged(): void {
			if (FloralSettings.dockLauncherOpen)
				FloralShellState.claimPanel("menus")
			else if (!menus.active)
				FloralShellState.releasePanel("menus")
		}
	}

	IpcHandler {
		target: "calendar"

		function toggle(): void {
			root.setCalendarOpen(!root.calendarOpen)
		}
		function open(): void { root.setCalendarOpen(true) }
		function close(): void { root.setCalendarOpen(false) }
		function isOpen(): bool { return root.calendarOpen }
	}

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

		Region {
			x: calendarPopup.x
			y: calendarPopup.y + calendarPopup.visualTop
			width: calendarPopup.width
			height: calendarPopup.revealHeight
		}

		Region {
			x: trayPopup.x
			y: trayPopup.y + trayPopup.visualTop
			width: trayPopup.width
			height: trayPopup.revealHeight
		}

		Region {
			x: windowPopup.x
			y: windowPopup.y + windowPopup.visualTop
			width: windowPopup.width
			height: windowPopup.revealHeight
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
		anchors {
			left: barSurface.left
			right: barSurface.right
			top: barSurface.bottom
		}
		height: ShellConfig.scaled(10)
		visible: FloralSettings.shadows
		gradient: Gradient {
			orientation: Gradient.Vertical
			GradientStop { position: 0; color: Theme.shadowSoft }
			GradientStop { position: 1; color: "transparent" }
		}
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
		id: leftArea

		anchors {
			left: parent.left
			right: notchSafeArea.left
			top: parent.top
			bottom: barSurface.bottom
		}
		clip: true

		FloralOsd {
			anchors {
				right: parent.right
				rightMargin: ShellConfig.bar.contentMargin
				verticalCenter: parent.verticalCenter
				verticalCenterOffset: -2
			}
			width: Math.min(implicitWidth,
				parent.width - ShellConfig.scaled(24))
			height: implicitHeight
			volume: root.volume
			muted: root.muted
			brightness: root.brightnessPercentage / 100
			z: 4
		}

		Row {
			id: leftModules

			anchors {
				left: parent.left
				leftMargin: ShellConfig.bar.contentMargin
				verticalCenter: parent.verticalCenter
				verticalCenterOffset: -2
			}
      spacing: ShellConfig.bar.leftSpacing

			FedoraLauncherButton {
				anchors.verticalCenter: parent.verticalCenter
				onClicked: {
					root.calendarOpen = false
					trayPopup.close()
					settingsPanel.close()
					menus.close()
					notificationCenter.togglePanel()
				}
			}

			ClockSummary {
				id: clockSummary

				anchors.verticalCenter: parent.verticalCenter
				visible: !FloralSettings.dockEnabled
				currentDate: clock.date
				active: root.calendarOpen || dashboard.active
				onClicked: {
					dashboard.toggle()
				}
				onSecondaryClicked:
					root.setCalendarOpen(!root.calendarOpen)
			}

	      ElegantSeparator {
				anchors.verticalCenter: parent.verticalCenter
				visible: !FloralSettings.dockEnabled
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

			BarStatusPills {
				id: statusPills
				anchors.verticalCenter: parent.verticalCenter
			}

      Text {
				anchors.verticalCenter: parent.verticalCenter
				visible: !statusPills.hasActiveStatus
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
				id: windowSummary
				width: ShellConfig.bar.windowTitleWidth
				maximumWidth: ShellConfig.bar.windowTitleWidth
				anchors.verticalCenter: parent.verticalCenter
				visible: !statusPills.hasActiveStatus
				onClicked: windowPopup.togglePinned()
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
				onClicked: root.openSettingsPage(4)
			}

	      ElegantSeparator {
				anchors.verticalCenter: parent.verticalCenter
	      }

			ControlSummary {
				id: brightnessSummary
				anchors.verticalCenter: parent.verticalCenter
				label: "brt"
				value: root.brightnessPercentage / 100
				onClicked: root.openSettingsPage(7)
			}

	      ElegantSeparator {
				anchors.verticalCenter: parent.verticalCenter
	      }

			ControlSummary {
				id: volumeSummary
				anchors.verticalCenter: parent.verticalCenter
				label: "vol"
				value: root.volume
				onClicked: root.openSettingsPage(6)
			}

	      ElegantSeparator {
				anchors.verticalCenter: parent.verticalCenter
				visible: !FloralSettings.dockEnabled
	      }

			BarTraySummary {
				id: traySummary
				anchors.verticalCenter: parent.verticalCenter
				onClicked: {
					root.calendarOpen = false
					trayPopup.togglePinned()
				}
			}

			ElegantSeparator {
				anchors.verticalCenter: parent.verticalCenter
				visible: traySummary.visible
			}

			BatteryModule {
				id: barBattery
				anchors.verticalCenter: parent.verticalCenter
				visible: !FloralSettings.dockEnabled
				onClicked: root.openSettingsPage(7)
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

	CalendarPopup {
		id: calendarPopup

		open: root.calendarOpen
		currentDate: clock.date
		x: {
			const center = leftModules.x + clockSummary.x
				+ clockSummary.width / 2
			return Math.max(0, Math.min(bar.width - width,
				center - width / 2))
		}
		y: ShellConfig.bar.surfaceHeight
			- ShellConfig.bar.mediaPopupHoverBridge
		z: ShellConfig.frame.borderZ + 1
		onCloseRequested: root.setCalendarOpen(false)
	}

	BarTray {
		id: trayPopup

		triggerHovered: traySummary.hovered
		x: {
			const center = rightArea.x + rightModules.x
				+ traySummary.x + traySummary.width / 2
			return Math.max(0, Math.min(bar.width - width,
				center - width / 2))
		}
		y: ShellConfig.bar.surfaceHeight
			- ShellConfig.bar.mediaPopupHoverBridge
		z: ShellConfig.frame.borderZ + 1
	}

	FloralWindowPopup {
		id: windowPopup

		triggerHovered: windowSummary.hovered
		x: {
			const center = leftModules.x + windowSummary.x
				+ windowSummary.width / 2
			return Math.max(0, Math.min(bar.width - width,
				center - width / 2))
		}
		y: ShellConfig.bar.surfaceHeight
			- ShellConfig.bar.mediaPopupHoverBridge
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
