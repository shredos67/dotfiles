/*
 * this file turns pywal colors into shell colors
 * it keeps old colors while pywal writes the new file
 * change the template if colors keep getting replaced
 */

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
	id: root

	readonly property string pywalThemePath: (Quickshell.env("XDG_CACHE_HOME") || `${Quickshell.env("HOME")}/.cache`) + "/wal/quickshell.json"
	readonly property bool ready: paletteReady
	property bool paletteReady: false

	property var colours: ({
		"ui": {
			"panel": "#111827",
			"panelRaised": "#172033",
			"panelHighlight": "#24314A",
			"panelTranslucent": "#F2111827",
			"frameBorder": "#60A5FA",
			"moduleLabel": "#FBBF24",
			"moduleValue": "#F3F4F6",
			"textMuted": "#94A3B8",
			"separator": "#7360A5FA"
		},
		"accents": {
			"primary": "#60A5FA",
			"secondary": "#C084FC",
			"tertiary": "#2DD4BF"
		},
		"status": {
			"danger": "#F87171",
			"warning": "#FBBF24",
			"success": "#4ADE80"
		},
		"terminal": {
			"background": "#111827",
			"foreground": "#F3F4F6",
			"color0": "#111827",
			"color1": "#F87171",
			"color2": "#4ADE80",
			"color3": "#FBBF24",
			"color4": "#60A5FA",
			"color5": "#C084FC",
			"color6": "#2DD4BF",
			"color7": "#D1D5DB",
			"color8": "#64748B",
			"color9": "#FCA5A5",
			"color10": "#86EFAC",
			"color11": "#FDE68A",
			"color12": "#93C5FD",
			"color13": "#D8B4FE",
			"color14": "#5EEAD4",
			"color15": "#FFFFFF"
		}
	})

	readonly property color panel: colours.ui.panel
	readonly property color panelRaised: colours.ui.panelRaised
	readonly property color panelHighlight: colours.ui.panelHighlight
	readonly property color panelTranslucent: colours.ui.panelTranslucent
	readonly property color frameBorder: colours.ui.frameBorder
	readonly property color moduleLabel: colours.ui.moduleLabel
	readonly property color moduleValue: colours.ui.moduleValue
	readonly property color textMuted: colours.ui.textMuted
	readonly property color separator: colours.ui.separator
	readonly property color frameBorderSoft: Qt.rgba(frameBorder.r,
		frameBorder.g, frameBorder.b, 0.54)
	readonly property color frameBorderFaint: Qt.rgba(frameBorder.r,
		frameBorder.g, frameBorder.b, 0.22)
	readonly property color panelSheen: Qt.rgba(moduleValue.r,
		moduleValue.g, moduleValue.b, 0.035)

	readonly property color accentPrimary: colours.accents.primary
	readonly property color accentSecondary: colours.accents.secondary
	readonly property color accentTertiary: colours.accents.tertiary

	readonly property color statusDanger: colours.status.danger
	readonly property color statusWarning: colours.status.warning
	readonly property color statusSuccess: colours.status.success

	readonly property color termBackground: colours.terminal.background
	readonly property color termForeground: colours.terminal.foreground
	readonly property color term0: colours.terminal.color0
	readonly property color term1: colours.terminal.color1
	readonly property color term2: colours.terminal.color2
	readonly property color term3: colours.terminal.color3
	readonly property color term4: colours.terminal.color4
	readonly property color term5: colours.terminal.color5
	readonly property color term6: colours.terminal.color6
	readonly property color term7: colours.terminal.color7
	readonly property color term8: colours.terminal.color8
	readonly property color term9: colours.terminal.color9
	readonly property color term10: colours.terminal.color10
	readonly property color term11: colours.terminal.color11
	readonly property color term12: colours.terminal.color12
	readonly property color term13: colours.terminal.color13
	readonly property color term14: colours.terminal.color14
	readonly property color term15: colours.terminal.color15

	function loadPywalTheme(data) {
		try {
			const next = JSON.parse(data)
			if (!next.ui?.panel
					|| !next.ui?.frameBorder
					|| !next.ui?.moduleLabel
					|| !next.ui?.moduleValue
					|| !next.accents?.primary
					|| !next.status?.danger
					|| !next.terminal?.color15)
				return

			root.colours = next
			fallbackReady.stop()

			Qt.callLater(() => root.paletteReady = true)
		} catch (error) {
		}
	}

	Timer {
		id: fallbackReady

		interval: 500
		running: true
		repeat: false
		onTriggered: root.paletteReady = true
	}

	FileView {
		path: root.pywalThemePath
		watchChanges: true
		printErrors: false
		onFileChanged: reload()
		onLoaded: root.loadPywalTheme(text())
	}
}
