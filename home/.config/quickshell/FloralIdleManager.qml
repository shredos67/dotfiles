import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Wayland
import Caelestia.Services
import qs.services

Scope {
    id: root

    readonly property bool mediaPlaying: Players.list.some(player => player.isPlaying)
    readonly property bool charging: UPower.displayDevice
        && UPower.displayDevice.isLaptopBattery
        && !UPower.onBattery
    readonly property bool baseEnabled: FloralSettings.idleEnabled
        && !IdleInhibitorService.enabled
        && !(FloralSettings.idleInhibitWhenCharging && charging)
    readonly property bool lockEnabled: baseEnabled
        && FloralSettings.idleLockTimeoutMinutes > 0
        && !(FloralSettings.idleInhibitLockWhenPlaying && mediaPlaying)
    readonly property bool dpmsEnabled: baseEnabled
        && FloralSettings.idleDpmsTimeoutMinutes > 0
        && !(FloralSettings.idleInhibitDpmsWhenPlaying && mediaPlaying)

    property bool dpmsOff: false

    function lockSession(): void {
        Quickshell.execDetached(["hyprlock"]);
    }

    function dispatchDpms(off: bool): void {
        Hyprland.dispatch(Hyprland.usingLua
            ? `hl.dsp.dpms({ action = "${off ? "disable" : "enable"}" })`
            : `dpms ${off ? "off" : "on"}`);
    }

    function turnDpmsOff(): void {
        if (dpmsOff)
            return;
        dpmsOff = true;
        dispatchDpms(true);
    }

    function turnDpmsOn(force: bool): void {
        if (!dpmsOff && !force)
            return;
        dpmsOff = false;
        dispatchDpms(false);
    }

    onDpmsEnabledChanged: {
        if (!dpmsEnabled && dpmsOff)
            turnDpmsOn(false);
    }

    Component.onDestruction: {
        if (dpmsOff)
            turnDpmsOn(false);
    }

    Connections {
        target: SessionManager

        function onAboutToSleep(): void {
            if (FloralSettings.idleEnabled
                    && FloralSettings.idleLockBeforeSleep)
                root.lockSession();
        }

        function onResumed(): void {
            root.turnDpmsOn(true);
        }

        function onLockRequested(): void {
            root.lockSession();
        }

        function onUnlockRequested(): void {
            root.turnDpmsOn(true);
        }
    }

    IdleMonitor {
        enabled: root.lockEnabled
        timeout: Math.max(1, FloralSettings.idleLockTimeoutMinutes * 60)
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                root.lockSession();
        }
    }

    IdleMonitor {
        enabled: root.dpmsEnabled
        timeout: Math.max(1, FloralSettings.idleDpmsTimeoutMinutes * 60)
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                root.turnDpmsOff();
            else if (root.dpmsOff)
                root.turnDpmsOn(false);
        }
    }
}
