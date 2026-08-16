import QtQuick
import Quickshell.Hyprland
import qs.components

Item {
	id: root

	required property bool triggerHovered
	property bool pinned: false
	property int preferredWidth: ShellConfig.scaled(382)
	property int preferredHeight: ShellConfig.scaled(143)
	property bool dismissed: false

	readonly property var client: Hyprland.activeToplevel
	readonly property bool hovered: popupHover.hovered
	readonly property bool shouldOpen: pinned
		|| (!dismissed && (triggerHovered || hovered))
	readonly property real visualTop: ShellConfig.bar.mediaPopupHoverBridge
		- ShellConfig.bar.mediaPopupBorderOverlap
	readonly property real panelHeight: preferredHeight
		+ ShellConfig.bar.mediaPopupBorderOverlap
	readonly property real animationOverflow:
		ShellConfig.bar.mediaPopupBounceBridge
	readonly property real slideOffset: -panelHeight * offsetScale
	readonly property real revealHeight: visible
		? panelHeight + animationOverflow : 0
	readonly property bool hasClient: client !== null
		&& client !== undefined
	readonly property bool floating: hasClient
		? (client.lastIpcObject?.floating ?? false) : false
	readonly property bool windowPinned: hasClient
		? (client.lastIpcObject?.pinned ?? false) : false
	readonly property int fullscreenState: hasClient
		? (client.lastIpcObject?.fullscreen ?? 0) : 0
	readonly property string appName: hasClient
		? String(client.lastIpcObject?.class
			|| client.lastIpcObject?.initialClass || "application")
		: "desktop"
	readonly property string windowTitle: hasClient
		? String(client.title || client.lastIpcObject?.title || appName)
		: "no active window"
	readonly property string workspaceName: hasClient
		? String(client.workspace?.name ?? client.workspace?.id ?? "—")
		: "—"
	property real offsetScale: shouldOpen ? 0 : 1

	function addressSelector(): string {
		if (!hasClient)
			return ""

		const rawAddress = String(client.address ?? "")
		if (!rawAddress)
			return ""
		return rawAddress.startsWith("0x")
			? `address:${rawAddress}`
			: `address:0x${rawAddress}`
	}

	function dispatch(luaRequest: string, standardRequest: string): void {
		if (!hasClient)
			return
		Hyprland.dispatch(Hyprland.usingLua ? luaRequest : standardRequest)
	}

	function focusClient(): void {
		const selector = addressSelector()
		dispatch(`hl.dsp.focus({ window = "${selector}" })`,
			`focuswindow ${selector}`)
	}

	function toggleFloating(): void {
		const selector = addressSelector()
		dispatch(`hl.dsp.window.float({ window = "${selector}" })`,
			`togglefloating ${selector}`)
	}

	function toggleMaximized(): void {
		const selector = addressSelector()
		dispatch(`hl.dsp.window.fullscreen({ window = "${selector}", mode = "maximized", action = "toggle" })`,
			"fullscreen 1")
	}

	function toggleWindowPin(): void {
		if (!floating)
			return
		const selector = addressSelector()
		dispatch(`hl.dsp.window.pin({ window = "${selector}" })`,
			`pin ${selector}`)
	}

	function closeClient(): void {
		const selector = addressSelector()
		dispatch(`hl.dsp.window.close({ window = "${selector}" })`,
			`closewindow ${selector}`)
	}

	function togglePinned(): void {
		dismissed = false
		pinned = !pinned
	}

	function close(): void {
		pinned = false
		dismissed = true
	}

	onPinnedChanged: {
		if (pinned)
			dismissed = false
	}

	onTriggerHoveredChanged: {
		if (triggerHovered)
			dismissed = false
		else if (!hovered)
			dismissed = false
	}

	onHoveredChanged: {
		if (!hovered && !triggerHovered)
			dismissed = false
	}

	visible: offsetScale < 1
	width: preferredWidth
	height: visualTop + panelHeight + animationOverflow

	Behavior on offsetScale {
		NumberAnimation {
			duration: FloralSettings.duration(ShellConfig.visuals.motionNormal)
			easing.type: Easing.OutCubic
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

			PopupChrome {
				anchors.fill: parent
			}

			Item {
				anchors.fill: parent
				clip: true

				Canvas {
					id: ornament

					x: -ShellConfig.scaled(20)
					y: -ShellConfig.scaled(30)
					width: ShellConfig.scaled(132)
					height: ShellConfig.scaled(108)
					antialiasing: true
					opacity: FloralSettings.ornaments ? 0.22 : 0
					property color lineColor: Theme.frameBorder

					onLineColorChanged: requestPaint()
					onWidthChanged: requestPaint()
					onHeightChanged: requestPaint()
					onPaint: {
						const context = getContext("2d")
						const w = width
						const h = height

						context.reset()
						context.strokeStyle = lineColor
						context.lineWidth = Math.max(1,
							ShellConfig.bar.hairlineThickness)
						context.lineCap = "round"
						context.lineJoin = "round"
						context.beginPath()
						context.moveTo(w * 0.02, h * 0.88)
						context.bezierCurveTo(w * 0.31, h * 0.76,
							w * 0.19, h * 0.30, w * 0.64, h * 0.12)
						context.moveTo(w * 0.25, h * 0.64)
						context.bezierCurveTo(w * 0.37, h * 0.45,
							w * 0.51, h * 0.49, w * 0.56, h * 0.59)
						context.moveTo(w * 0.43, h * 0.34)
						context.bezierCurveTo(w * 0.57, h * 0.24,
							w * 0.68, h * 0.32, w * 0.70, h * 0.43)
						context.stroke()

						for (let index = 0; index < 4; ++index) {
							const angle = index * Math.PI / 2
							context.save()
							context.translate(w * 0.66, h * 0.14)
							context.rotate(angle)
							context.beginPath()
							context.moveTo(0, 0)
							context.bezierCurveTo(w * 0.05, -h * 0.13,
								w * 0.14, -h * 0.10, w * 0.12, 0)
							context.bezierCurveTo(w * 0.08, h * 0.06,
								w * 0.03, h * 0.04, 0, 0)
							context.stroke()
							context.restore()
						}
					}

					Behavior on opacity {
						NumberAnimation {
							duration: FloralSettings.duration(
								ShellConfig.visuals.motionFast)
							easing.type: Easing.OutCubic
						}
					}
				}
			}

			Column {
				anchors {
					left: parent.left
					right: parent.right
					top: parent.top
					leftMargin: ShellConfig.scaled(17)
					rightMargin: ShellConfig.scaled(17)
					topMargin: ShellConfig.scaled(12)
				}
				spacing: ShellConfig.scaled(7)

				Item {
					width: parent.width
					height: ShellConfig.scaled(49)

					Column {
						anchors {
							left: parent.left
							right: stateColumn.left
							rightMargin: ShellConfig.scaled(14)
							verticalCenter: parent.verticalCenter
						}
						spacing: ShellConfig.scaled(1)

						Text {
							width: parent.width
							text: root.windowTitle.toLowerCase()
							color: Theme.moduleValue
							elide: Text.ElideRight
							renderType: Text.NativeRendering
							font {
								family: ShellConfig.typography.monoFamily
								styleName: ShellConfig.typography.fineStyle
								pixelSize: ShellConfig.scaled(14)
								weight: Font.DemiBold
							}
						}

						Text {
							width: parent.width
							text: root.appName.toLowerCase()
							color: Theme.moduleLabel
							elide: Text.ElideRight
							renderType: Text.NativeRendering
							font {
								family: ShellConfig.typography.monoFamily
								styleName: ShellConfig.typography.fineStyle
								pixelSize: ShellConfig.scaled(10)
								weight: Font.Medium
							}
						}
					}

					Column {
						id: stateColumn

						anchors {
							right: parent.right
							verticalCenter: parent.verticalCenter
						}
						spacing: ShellConfig.scaled(1)

						Text {
							anchors.right: parent.right
							text: `workspace ${root.workspaceName}`
							color: Theme.moduleLabel
							renderType: Text.NativeRendering
							font {
								family: ShellConfig.typography.monoFamily
								styleName: ShellConfig.typography.fineStyle
								pixelSize: ShellConfig.scaled(10)
								weight: Font.Medium
							}
						}

						Text {
							anchors.right: parent.right
							text: {
								const states = [root.floating ? "floating" : "tiled"]
								if (root.fullscreenState === 1)
									states.push("maximized")
								else if (root.fullscreenState > 1)
									states.push("fullscreen")
								if (root.windowPinned)
									states.push("pinned")
								return states.join("  ·  ")
							}
							color: Theme.textMuted
							renderType: Text.NativeRendering
							font {
								family: ShellConfig.typography.monoFamily
								styleName: ShellConfig.typography.fineStyle
								pixelSize: ShellConfig.scaled(9)
							}
						}
					}
				}

				Rectangle {
					width: parent.width
					height: ShellConfig.bar.hairlineThickness
					color: Theme.separator
					opacity: 0.72
				}

				Row {
					anchors.horizontalCenter: parent.horizontalCenter
					spacing: ShellConfig.scaled(7)

					FloralWindowAction {
						kind: "focus"
						label: "focus"
						enabled: root.hasClient
						onTriggered: root.focusClient()
					}

					FloralWindowAction {
						kind: "float"
						label: root.floating ? "tile" : "float"
						active: root.floating
						enabled: root.hasClient
						onTriggered: root.toggleFloating()
					}

					FloralWindowAction {
						kind: "maximize"
						label: root.fullscreenState === 1 ? "restore" : "max"
						active: root.fullscreenState === 1
						enabled: root.hasClient
						onTriggered: root.toggleMaximized()
					}

					FloralWindowAction {
						kind: "pin"
						label: root.windowPinned ? "unpin" : "pin"
						active: root.windowPinned
						enabled: root.hasClient && root.floating
						onTriggered: root.toggleWindowPin()
					}

					FloralWindowAction {
						kind: "close"
						label: "close"
						destructive: true
						enabled: root.hasClient
						onTriggered: root.closeClient()
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
