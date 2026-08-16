import QtQuick
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property real cpuUsage: 0
    property real memoryUsage: 0
    property real diskUsage: 0
    property real downloadSpeed: 0
    property real uploadSpeed: 0
    property real previousCpuTotal: -1
    property real previousCpuIdle: -1
    property real previousRx: -1
    property real previousTx: -1
    property double previousNetTime: 0
    property int sampleCount: 0
    property var cpuHistory: []
    property var memoryHistory: []
    property var diskHistory: []
    property var downloadHistory: []
    property var uploadHistory: []
    property string memoryDetail: "waiting for a sample"
    property string diskDetail: "waiting for a sample"

    visible: false

    function bounded(value) {
        return Math.max(0, Math.min(1, value));
    }

    function append(history, value) {
        const next = history.slice(Math.max(0,
            history.length - ShellConfig.dashboard.historyLength + 1));
        next.push(value);
        return next;
    }

    function formatBytes(bytes) {
        if (!isFinite(bytes) || bytes < 0)
            return "0 b/s";
        if (bytes < 1024)
            return `${Math.round(bytes)} b/s`;
        if (bytes < 1048576)
            return `${(bytes / 1024).toFixed(bytes < 10240 ? 1 : 0)} kb/s`;
        if (bytes < 1073741824)
            return `${(bytes / 1048576).toFixed(bytes < 10485760 ? 1 : 0)} mb/s`;
        return `${(bytes / 1073741824).toFixed(1)} gb/s`;
    }

    function formatMemory(kibibytes) {
        const gibibytes = kibibytes / 1048576;
        return `${gibibytes.toFixed(1)} gb`;
    }

    function parseCpu(contents) {
        const line = contents.split("\n")[0]?.trim();
        if (!line || !line.startsWith("cpu "))
            return;

        const fields = line.split(/\s+/).slice(1, 9)
            .map(value => Number(value));
        if (fields.length < 5 || fields.some(value => !isFinite(value)))
            return;

        const total = fields.reduce((sum, value) => sum + value, 0);
        const idle = fields[3] + fields[4];
        if (previousCpuTotal >= 0 && total > previousCpuTotal) {
            const delta = total - previousCpuTotal;
            const busy = delta - (idle - previousCpuIdle);
            cpuUsage = bounded(busy / delta);
            cpuHistory = append(cpuHistory, cpuUsage);
        }
        previousCpuTotal = total;
        previousCpuIdle = idle;
    }

    function parseMemory(contents) {
        const totalMatch = /^MemTotal:\s+(\d+)/m.exec(contents);
        const availableMatch = /^MemAvailable:\s+(\d+)/m.exec(contents);
        if (!totalMatch || !availableMatch)
            return;

        const total = Number(totalMatch[1]);
        const available = Number(availableMatch[1]);
        if (total <= 0)
            return;

        const used = total - available;
        memoryUsage = bounded(used / total);
        memoryDetail = `${formatMemory(used)} of ${formatMemory(total)}`;
        memoryHistory = append(memoryHistory, memoryUsage);
    }

    function parseDisk(contents) {
        const lines = contents.trim().split("\n");
        if (lines.length < 2)
            return;
        const fields = lines[lines.length - 1].trim().split(/\s+/);
        if (fields.length < 6)
            return;

        const total = Number(fields[1]);
        const used = Number(fields[2]);
        if (!isFinite(total) || total <= 0 || !isFinite(used))
            return;

        diskUsage = bounded(used / total);
        diskDetail = `${formatMemory(used)} of ${formatMemory(total)}`;
        diskHistory = append(diskHistory, diskUsage);
    }

    function parseNetwork(contents) {
        let received = 0;
        let transmitted = 0;
        const lines = contents.split("\n").slice(2);
        for (const rawLine of lines) {
            const line = rawLine.trim();
            if (!line)
                continue;
            const fields = line.split(/\s+/);
            const interfaceName = fields[0].replace(":", "");
            if (interfaceName === "lo" || fields.length < 10)
                continue;
            received += Number(fields[1]) || 0;
            transmitted += Number(fields[9]) || 0;
        }

        const now = Date.now();
        if (previousRx >= 0 && previousTx >= 0 && previousNetTime > 0) {
            const seconds = Math.max(0.001, (now - previousNetTime) / 1000);
            downloadSpeed = Math.max(0, (received - previousRx) / seconds);
            uploadSpeed = Math.max(0, (transmitted - previousTx) / seconds);
            downloadHistory = append(downloadHistory, downloadSpeed);
            uploadHistory = append(uploadHistory, uploadSpeed);
        }
        previousRx = received;
        previousTx = transmitted;
        previousNetTime = now;
    }

    function sample() {
        cpuFile.reload();
        memoryFile.reload();
        networkFile.reload();
        if (sampleCount % ShellConfig.dashboard.diskSampleDivisor === 0
                && !diskProcess.running)
            diskProcess.running = true;
        sampleCount++;
    }

    onActiveChanged: {
        if (!active) {
            previousCpuTotal = -1;
            previousCpuIdle = -1;
            previousRx = -1;
            previousTx = -1;
            previousNetTime = 0;
        }
    }

    FileView {
        id: cpuFile

        path: "/proc/stat"
        printErrors: false
        onLoaded: root.parseCpu(text())
    }

    FileView {
        id: memoryFile

        path: "/proc/meminfo"
        printErrors: false
        onLoaded: root.parseMemory(text())
    }

    FileView {
        id: networkFile

        path: "/proc/net/dev"
        printErrors: false
        onLoaded: root.parseNetwork(text())
    }

    Process {
        id: diskProcess

        command: ["df", "-Pk", "/"]
        stdout: StdioCollector {
            onStreamFinished: root.parseDisk(text)
        }
    }

    Timer {
        interval: Math.max(1000, ShellConfig.dashboard.statsUpdateMs)
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.sample()
    }
}
