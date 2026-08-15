pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
	id: root

	readonly property int bandCount: 28
	readonly property var activePlayer: Mpris.players.values.find(player => player.isPlaying)
		?? Mpris.players.values[0]
		?? null
	readonly property bool playing: activePlayer
		? activePlayer.isPlaying : false
	property var levels: Array(bandCount).fill(0)
	property bool hasRealFrame: false
	property bool cavaFailed: false
	property real fallbackPhase: 0

	function emptyLevels(): var {
		return Array(root.bandCount).fill(0)
	}

	function parseFrame(data: string): void {
		const fields = data.trim().split(";")
		const incoming = []

		for (let index = 0; index < fields.length; index++) {
			if (!fields[index].length)
				continue

			const parsed = Number(fields[index])
			if (!isNaN(parsed))
				incoming.push(Math.max(0, Math.min(100, parsed)))
		}

		if (incoming.length < 4)
			return

		const previous = root.levels
		const next = []
		for (let index = 0; index < root.bandCount; index++) {
			const sourceIndex = Math.min(incoming.length - 1,
				Math.floor(index * incoming.length / root.bandCount))
			const rawLevel = Math.pow(incoming[sourceIndex] / 100, 0.72)
			const previousLevel = previous[index] ?? 0
			next.push(previousLevel * 0.28 + rawLevel * 0.72)
		}

		root.levels = next
		root.hasRealFrame = true
		root.cavaFailed = false
	}

	function levelFor(index: int, count: int): real {
		if (count <= 0 || root.levels.length === 0)
			return 0

		const first = Math.floor(index * root.levels.length / count)
		const last = Math.max(first + 1,
			Math.floor((index + 1) * root.levels.length / count))
		let total = 0
		let samples = 0

		for (let sourceIndex = first;
				sourceIndex < last && sourceIndex < root.levels.length;
				sourceIndex++) {
			total += root.levels[sourceIndex]
			samples++
		}

		return samples > 0 ? total / samples : 0
	}

	onPlayingChanged: {
		root.hasRealFrame = false
		root.cavaFailed = false
		if (!root.playing)
			root.levels = root.emptyLevels()
	}

	Process {
		id: cava

		running: root.playing && !root.cavaFailed
		command: ["cava", "-p", Quickshell.shellDir + "/assets/cava-media.ini"]
		stdout: SplitParser {
			splitMarker: "\n"
			onRead: data => root.parseFrame(data)
		}
		stderr: StdioCollector {}
		onExited: {
			if (root.playing) {
				root.hasRealFrame = false
				root.cavaFailed = true
			}
		}
	}

	Timer {
		interval: 84
		running: root.playing && !root.hasRealFrame
		repeat: true
		triggeredOnStart: true
		onTriggered: {
			root.fallbackPhase += 0.24
			const next = []
			for (let index = 0; index < root.bandCount; index++) {
				const envelope = 0.34 + 0.66 * Math.sin(Math.PI
					* (index + 0.5) / root.bandCount)
				const wave = 0.18 + 0.52
					* Math.abs(Math.sin(root.fallbackPhase + index * 0.47))
					* Math.abs(Math.sin(root.fallbackPhase * 0.39 + index * 0.23))
				const beat = 0.24 * Math.pow(Math.max(0,
					Math.sin(root.fallbackPhase * 0.72 - index * 0.08)), 4)
				next.push(Math.min(0.86, (wave + beat) * envelope))
			}
			root.levels = next
		}
	}
}
