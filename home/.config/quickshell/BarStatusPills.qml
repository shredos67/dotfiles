pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
	id: root

	readonly property bool recording: Recorder.running
	readonly property bool microphoneMuted:
		FloralSystemService.audioSource !== null
		&& FloralSystemService.inputMuted
	readonly property bool doNotDisturb: Notifs.dnd
	readonly property bool idleActive: IdleInhibitorService.enabled
	readonly property bool hasActiveStatus:
		recording || microphoneMuted || doNotDisturb || idleActive

	function elapsedLabel(seconds: real): string {
		const total = Math.max(0, Math.floor(seconds));
		const hours = Math.floor(total / 3600);
		const minutes = Math.floor((total % 3600) / 60);
		const secs = total % 60;
		if (hours > 0)
			return `${hours}:${minutes.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
		return `${minutes.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
	}

	visible: hasActiveStatus
	implicitWidth: statusRow.implicitWidth
	implicitHeight: ShellConfig.bar.mediaButtonSize

	Row {
		id: statusRow

		anchors.centerIn: parent
		spacing: ShellConfig.bar.mediaSpacing

		StatusPill {
			visible: root.recording
			kind: Recorder.paused ? "pause" : "record"
			label: Recorder.paused
				? `paused ${root.elapsedLabel(Recorder.elapsed)}`
				: `rec ${root.elapsedLabel(Recorder.elapsed)}`
			accent: Theme.statusDanger
			onPrimaryActivated: Recorder.stop()
			onSecondaryActivated: Recorder.togglePause()
		}

		StatusPill {
			visible: root.microphoneMuted
			kind: "mic"
			label: "mic"
			accent: Theme.statusWarning
			onPrimaryActivated: FloralSystemService.setInputMuted(false)
			onSecondaryActivated: FloralSystemService.setInputMuted(false)
		}

		StatusPill {
			visible: root.idleActive
			kind: "awake"
			label: "awake"
			accent: Theme.accentTertiary
			onPrimaryActivated: IdleInhibitorService.enabled = false
			onSecondaryActivated: IdleInhibitorService.enabled = false
		}

		StatusPill {
			visible: root.doNotDisturb
			kind: "dnd"
			label: "dnd"
			accent: Theme.accentSecondary
			onPrimaryActivated: Notifs.dnd = false
			onSecondaryActivated: Notifs.dnd = false
		}
	}

	component StatusPill: Rectangle {
		id: pill

		required property string kind
		required property string label
		required property color accent

		signal primaryActivated
		signal secondaryActivated

		implicitWidth: pillContent.implicitWidth
			+ ShellConfig.bar.mediaSummaryPadding * 2
		implicitHeight: ShellConfig.bar.mediaButtonSize
		radius: ShellConfig.visuals.controlRadius
		color: pointer.containsMouse
			? Theme.panelHighlight : Theme.panelRaised
		border.width: ShellConfig.bar.hairlineThickness
		border.color: pointer.containsMouse
			? pill.accent : Theme.frameBorderFaint
		scale: pointer.pressed ? 0.96 : pointer.containsMouse ? 1.025 : 1

		Behavior on color {
			ColorAnimation {
				duration: FloralSettings.duration(ShellConfig.visuals.motionFast)
				easing.type: Easing.OutCubic
			}
		}

		Behavior on border.color {
			ColorAnimation {
				duration: FloralSettings.duration(ShellConfig.visuals.motionFast)
				easing.type: Easing.OutCubic
			}
		}

		Behavior on scale {
			NumberAnimation {
				duration: FloralSettings.duration(ShellConfig.visuals.motionFast)
				easing.type: Easing.OutCubic
			}
		}

		Row {
			id: pillContent

			anchors.centerIn: parent
			spacing: ShellConfig.bar.mediaSpacing

			Canvas {
				anchors.verticalCenter: parent.verticalCenter
				width: ShellConfig.scaled(13)
				height: width
				antialiasing: true
				property string markKind: pill.kind
				property color markColor: pill.accent

				onMarkKindChanged: requestPaint()
				onMarkColorChanged: requestPaint()
				onWidthChanged: requestPaint()
				onHeightChanged: requestPaint()

				onPaint: {
					const context = getContext("2d")
					context.reset()
					context.scale(width / 20, height / 20)
					context.strokeStyle = markColor
					context.fillStyle = markColor
					context.lineWidth = 1.8
					context.lineCap = "round"
					context.lineJoin = "round"

					if (markKind === "record") {
						context.beginPath()
						context.arc(10, 10, 5.5, 0, Math.PI * 2)
						context.fill()
						return
					}

					if (markKind === "pause") {
						context.fillRect(5.5, 4.5, 3, 11)
						context.fillRect(11.5, 4.5, 3, 11)
						return
					}

					if (markKind === "mic") {
						context.beginPath()
						context.moveTo(10, 2.5)
						context.quadraticCurveTo(13, 2.5, 13, 5.5)
						context.lineTo(13, 8.5)
						context.quadraticCurveTo(13, 11.5, 10, 11.5)
						context.quadraticCurveTo(7, 11.5, 7, 8.5)
						context.lineTo(7, 5.5)
						context.quadraticCurveTo(7, 2.5, 10, 2.5)
						context.closePath()
						context.stroke()
						context.beginPath()
						context.moveTo(4.5, 9)
						context.quadraticCurveTo(4.5, 15, 10, 15)
						context.quadraticCurveTo(15.5, 15, 15.5, 9)
						context.moveTo(10, 15)
						context.lineTo(10, 18)
						context.moveTo(6.5, 18)
						context.lineTo(13.5, 18)
						context.moveTo(3, 3)
						context.lineTo(17, 17)
						context.stroke()
						return
					}

					if (markKind === "awake") {
						context.beginPath()
						context.moveTo(2.5, 10)
						context.quadraticCurveTo(10, 3.5, 17.5, 10)
						context.quadraticCurveTo(10, 16.5, 2.5, 10)
						context.stroke()
						context.beginPath()
						context.arc(10, 10, 2.4, 0, Math.PI * 2)
						context.fill()
						return
					}

					context.beginPath()
					context.moveTo(5.5, 13.5)
					context.lineTo(5.5, 9)
					context.quadraticCurveTo(5.5, 4.5, 10, 4.5)
					context.quadraticCurveTo(14.5, 4.5, 14.5, 9)
					context.lineTo(14.5, 13.5)
					context.lineTo(16, 15)
					context.lineTo(4, 15)
					context.closePath()
					context.stroke()
					context.beginPath()
					context.moveTo(3, 3)
					context.lineTo(17, 17)
					context.stroke()
				}
			}

			Text {
				anchors.verticalCenter: parent.verticalCenter
				text: pill.label
				color: Theme.moduleValue
				renderType: Text.NativeRendering
				font {
					family: ShellConfig.typography.monoFamily
					pixelSize: ShellConfig.bar.mediaFontSize
					weight: Font.DemiBold
				}
			}
		}

		MouseArea {
			id: pointer

			anchors.fill: parent
			hoverEnabled: true
			acceptedButtons: Qt.LeftButton | Qt.RightButton
			cursorShape: Qt.PointingHandCursor
			onClicked: event => {
				if (event.button === Qt.RightButton)
					pill.secondaryActivated();
				else
					pill.primaryActivated();
			}
		}
	}
}
