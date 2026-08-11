pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property alias running: props.running
    readonly property alias paused: props.paused
    readonly property alias elapsed: props.elapsed
    readonly property string controller:
        `${Quickshell.env("HOME")}/.local/bin/quickshell-obs-record`

    function applyStatus(contents: string): void {
        const line = contents.trim();
        if (!line.length)
            return;

        try {
            const status = JSON.parse(line);
            props.running = status.running === true;
            props.paused = props.running && status.paused === true;
        } catch (error) {
            console.warn("Failed to read OBS recorder status:", error);
        }
    }

    function runAction(action: string): void {
        if (controlProc.running)
            return;
        controlProc.command = [controller, action];
        controlProc.running = true;
    }

    function start(extraArgs = []): void {
        if (running)
            return;
        props.elapsed = 0;
        runAction("start");
    }

    function stop(): void {
        if (running)
            runAction("stop");
    }

    function toggle(): void {
        if (!running)
            props.elapsed = 0;
        runAction("toggle");
    }

    function togglePause(): void {
        if (running)
            runAction(paused ? "resume" : "pause");
    }

    PersistentProperties {
        id: props

        property bool running: false
        property bool paused: false
        property real elapsed: 0

        reloadableId: "recorder"
    }

    Process {
        id: statusProc

        running: true
        command: [root.controller, "status"]
        stdout: StdioCollector {
            onStreamFinished: root.applyStatus(text)
        }
    }

    Process {
        id: controlProc

        stdout: StdioCollector {
            onStreamFinished: root.applyStatus(text)
        }
        onExited: {
            if (!statusProc.running)
                statusProc.running = true;
        }
    }

    Timer {
        interval: 1000
        running: props.running
        repeat: true
        onTriggered: {
            if (!props.paused)
                props.elapsed++;
            if (!statusProc.running)
                statusProc.running = true;
        }
    }
}
