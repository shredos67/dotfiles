pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.services

Singleton {
    id: root

    property bool networkBusy: false
    property string networkMessage: ""
    property var pendingNetwork: null
    property bool passwordRequested: false
    property bool powerProfilesAvailable: false
    property bool bluezAvailable: false
    property bool serviceCheckComplete: false
    property var audioSinks: []
    property var audioSources: []
    property real brightness: 0
    property string osPrettyName: ""
    property string kernel: ""
    property string hostname: ""
    property string boardVendor: ""
    property string boardName: ""
    property string uptime: ""

    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property var audioSource: Pipewire.defaultAudioSource
    readonly property real outputVolume: audioSink?.audio?.volume ?? 0
    readonly property bool outputMuted: audioSink?.audio?.muted ?? false
    readonly property real inputVolume: audioSource?.audio?.volume ?? 0
    readonly property bool inputMuted: audioSource?.audio?.muted ?? false
    readonly property string user: Quickshell.env("USER")
    readonly property string session: Quickshell.env("XDG_CURRENT_DESKTOP")
        || Quickshell.env("XDG_SESSION_DESKTOP")
        || "wayland"
    readonly property string device: {
        if (!boardName)
            return boardVendor;
        if (!boardVendor
                || boardName.toLowerCase().startsWith(boardVendor.toLowerCase()))
            return boardName;
        return `${boardVendor} ${boardName}`;
    }
    readonly property bool wifiEnabled: Nmcli.wifiEnabled
    readonly property bool networkScanning: Nmcli.scanning
    readonly property bool networkConnected: Nmcli.isConnected
    readonly property var activeNetwork: Nmcli.active
    readonly property string activeConnection: Nmcli.activeConnection
    readonly property string activeInterface: Nmcli.activeInterface

    readonly property var networks: [...Nmcli.networks].sort((first, second) => {
        if (first.active !== second.active)
            return first.active ? -1 : 1;
        return second.strength - first.strength;
    })

    readonly property var bluetoothAdapter: bluezAvailable
        ? Bluetooth.defaultAdapter
        : null
    readonly property var bluetoothDevices: bluezAvailable
        ? [...Bluetooth.devices.values].sort((first, second) => {
            if (first.connected !== second.connected)
                return first.connected ? -1 : 1;
            if (first.paired !== second.paired)
                return first.paired ? -1 : 1;
            return root.deviceName(first).localeCompare(root.deviceName(second));
        })
        : []

    readonly property int connectedBluetoothDevices: bluetoothDevices.filter(device => device.connected).length

    function deviceName(device) {
        return device?.name || device?.deviceName || "unnamed device";
    }

    function savedNetwork(ssid) {
        const target = String(ssid || "").toLowerCase().trim();
        return Nmcli.savedConnectionSsids.some(saved =>
            String(saved || "").toLowerCase().trim() === target);
    }

    function networkSecure(network) {
        const security = String(network?.security || "").toLowerCase().trim();
        return security.length > 0
            && security !== "--"
            && security !== "none"
            && security !== "open";
    }

    function refresh() {
        Nmcli.refreshStatus(() => {});
        if (Nmcli.wifiEnabled)
            Nmcli.getNetworks(() => {});
        refreshAudioNodes();
        brightnessRead.running = false;
        brightnessRead.running = true;
        uptimeRead.reload();
    }

    function refreshAudioNodes() {
        const sinks = [];
        const sources = [];
        for (const node of Pipewire.nodes.values) {
            if (node.isStream)
                continue;
            if (node.isSink)
                sinks.push(node);
            else if (node.audio)
                sources.push(node);
        }
        audioSinks = sinks;
        audioSources = sources;
    }

    function setOutputVolume(value) {
        if (!audioSink?.ready || !audioSink.audio)
            return;
        audioSink.audio.muted = false;
        audioSink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function setInputVolume(value) {
        if (!audioSource?.ready || !audioSource.audio)
            return;
        audioSource.audio.muted = false;
        audioSource.audio.volume = Math.max(0, Math.min(1, value));
    }

    function setOutputMuted(value) {
        if (audioSink?.ready && audioSink.audio)
            audioSink.audio.muted = value;
    }

    function setInputMuted(value) {
        if (audioSource?.ready && audioSource.audio)
            audioSource.audio.muted = value;
    }

    function selectAudioSink(node) {
        if (node)
            Pipewire.preferredDefaultAudioSink = node;
    }

    function selectAudioSource(node) {
        if (node)
            Pipewire.preferredDefaultAudioSource = node;
    }

    function setBrightness(value) {
        const bounded = Math.max(0, Math.min(1, value));
        const percent = Math.round(bounded * 100);
        brightness = bounded;
        Quickshell.execDetached([
            "brightnessctl", "-e4", "-n2", "set", `${percent}%`
        ]);
    }

    function updateUptime(raw) {
        const seconds = parseInt(String(raw || "0").split(" ")[0], 10) || 0;
        const days = Math.floor(seconds / 86400);
        const hours = Math.floor((seconds % 86400) / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const parts = [];
        if (days > 0)
            parts.push(`${days} day${days === 1 ? "" : "s"}`);
        if (hours > 0)
            parts.push(`${hours} hour${hours === 1 ? "" : "s"}`);
        if (minutes > 0 || parts.length === 0)
            parts.push(`${minutes} minute${minutes === 1 ? "" : "s"}`);
        uptime = parts.slice(0, 2).join(", ");
    }

    function scanNetworks() {
        if (!Nmcli.wifiEnabled || Nmcli.scanning)
            return;
        networkMessage = "scanning";
        Nmcli.rescanWifi();
    }

    function setWifi(enabled) {
        if (networkBusy)
            return;
        networkBusy = true;
        networkMessage = enabled ? "turning wi-fi on" : "turning wi-fi off";
        Nmcli.enableWifi(enabled, result => {
            networkBusy = false;
            networkMessage = result?.success
                ? enabled ? "wi-fi is on" : "wi-fi is off"
                : "could not change wi-fi";
            if (enabled)
                Nmcli.getNetworks(() => {});
        });
    }

    function chooseNetwork(network) {
        if (!network || networkBusy)
            return;

        if (network.active) {
            networkMessage = `disconnecting from ${network.ssid}`;
            Nmcli.disconnectFromNetwork();
            return;
        }

        pendingNetwork = network;
        if (networkSecure(network) && !savedNetwork(network.ssid)) {
            passwordRequested = true;
            networkMessage = "password required";
            return;
        }

        networkBusy = true;
        networkMessage = `connecting to ${network.ssid}`;
        Nmcli.connectToNetworkWithPasswordCheck(
            network.ssid,
            networkSecure(network),
            result => root.finishNetwork(result),
            network.bssid
        );
    }

    function connectPending(password) {
        if (!pendingNetwork || networkBusy)
            return;

        const network = pendingNetwork;
        if (networkSecure(network) && String(password || "").length === 0) {
            networkMessage = "enter the network password";
            return;
        }

        passwordRequested = false;
        networkBusy = true;
        networkMessage = `connecting to ${network.ssid}`;
        Nmcli.connectToNetwork(
            network.ssid,
            String(password || ""),
            network.bssid,
            result => root.finishNetwork(result)
        );
    }

    function cancelPassword() {
        pendingNetwork = null;
        passwordRequested = false;
        networkMessage = "";
    }

    function finishNetwork(result) {
        networkBusy = false;
        if (result?.success) {
            networkMessage = pendingNetwork
                ? `connected to ${pendingNetwork.ssid}`
                : "connected";
            pendingNetwork = null;
            passwordRequested = false;
            Nmcli.refreshStatus(() => {});
            Nmcli.getNetworks(() => {});
            return;
        }

        if (result?.needsPassword) {
            passwordRequested = true;
            networkMessage = "password required";
            return;
        }

        const message = String(result?.error || "").toLowerCase();
        networkMessage = message.includes("password") || message.includes("secret")
            ? "incorrect password"
            : "connection failed";
        passwordRequested = networkSecure(pendingNetwork);
    }

    function toggleBluetoothDevice(device) {
        if (!device)
            return;
        if (device.paired || device.bonded || device.connected)
            device.connected = !device.connected;
        else
            device.pair();
    }

    function bluetoothDeviceBusy(device) {
        return !!device
            && (device.pairing || device.state === 2 || device.state === 3);
    }

    function lockSession() {
        Quickshell.execDetached(["hyprlock"]);
    }

    function suspendSession() {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function openPowerMenu() {
        Quickshell.execDetached(["qs", "ipc", "call", "powerMenu", "open"]);
    }

    Connections {
        target: Nmcli

        function onScanningChanged() {
            if (!Nmcli.scanning && root.networkMessage === "scanning")
                root.networkMessage = "scan complete";
        }

        function onActiveChanged() {
            if (!Nmcli.active && root.networkMessage.startsWith("disconnecting"))
                root.networkMessage = "disconnected";
        }
    }

    Connections {
        target: Pipewire.nodes

        function onValuesChanged() {
            root.refreshAudioNodes();
        }
    }

    PwObjectTracker {
        objects: [
            root.audioSink,
            root.audioSource,
            ...root.audioSinks,
            ...root.audioSources
        ].filter(node => node)
    }

    Process {
        id: brightnessRead

        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",");
                if (fields.length < 4)
                    return;
                const percent = parseInt(fields[3].replace("%", ""), 10);
                if (!isNaN(percent))
                    root.brightness = percent / 100;
            }
        }
    }

    FileView {
        path: "/etc/os-release"
        onLoaded: {
            const line = text().split("\n")
                .find(entry => entry.startsWith("PRETTY_NAME="));
            root.osPrettyName = line
                ? line.slice(12).replace(/^\"|\"$/g, "")
                : "linux";
        }
    }

    FileView {
        path: "/proc/sys/kernel/osrelease"
        onLoaded: root.kernel = text().trim()
    }

    FileView {
        path: "/proc/sys/kernel/hostname"
        onLoaded: root.hostname = text().trim()
    }

    FileView {
        path: "/sys/class/dmi/id/sys_vendor"
        printErrors: false
        onLoaded: root.boardVendor = text().trim()
    }

    FileView {
        path: "/sys/class/dmi/id/product_name"
        printErrors: false
        onLoaded: root.boardName = text().trim()
    }

    FileView {
        id: uptimeRead

        path: "/proc/uptime"
        onLoaded: root.updateUptime(text())
    }

    Timer {
        running: true
        repeat: true
        interval: 60000
        onTriggered: uptimeRead.reload()
    }

    Process {
        id: optionalServiceCheck

        command: ["busctl", "--system", "--no-pager", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.powerProfilesAvailable =
                    text.includes("org.freedesktop.UPower.PowerProfiles");
                root.bluezAvailable = text.includes("org.bluez");
                root.serviceCheckComplete = true;
            }
        }
    }

    Component.onCompleted: {
        refreshAudioNodes();
        brightnessRead.running = true;
        optionalServiceCheck.running = true;
    }
}
