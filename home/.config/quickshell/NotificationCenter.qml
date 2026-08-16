/*
 * this file holds notifications and the left drawer
 * most sizes are in shellconfig qml
 * change that first
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.services
import qs.services as Services

Scope {
    id: root

    property bool panelOpen
    property real panelOffsetScale: panelOpen ? 0 : 1
    property real cpuUsage
    property real memoryUsage
    property real diskUsage
    property real previousCpuTotal: -1
    property real previousCpuIdle: -1
    property bool showRecordings
    readonly property var activeCaptureFolder: showRecordings
        ? recordingFolder : screenshotFolder
    readonly property real actionWidth: (ShellConfig.notifications.panelWidth
        - ShellConfig.notifications.panelPadding * 2
        - ShellConfig.notifications.cardSpacing * 2) / 3

    onShowRecordingsChanged: Qt.callLater(() => screenshotList.positionViewAtBeginning())

    function togglePanel(): void {
        panelOpen = !panelOpen;
    }

    function openPanel(): void {
        panelOpen = true;
    }

    function closePanel(): void {
        panelOpen = false;
    }

    function clearAll(): void {
        for (const notification of Notifs.list.slice())
            notification.close();
    }

    function openWallpaperPicker(): void {
        closePanel();
        wallpaperDelay.restart();
    }

    function takeScreenshot(): void {
        closePanel();
        screenshotDelay.restart();
    }

    function openCapture(index: int): void {
        if (index < 0 || index >= activeCaptureFolder.count)
            return;

        const uri = activeCaptureFolder.get(index, "fileUrl").toString();
        const path = decodeURIComponent(uri.startsWith("file://")
            ? uri.slice(7) : uri);
        Quickshell.execDetached(showRecordings
            ? ["xdg-open", path]
            : ["imv", path]);
    }

    function parseCpu(contents: string): void {
        const line = contents.split("\n")[0]?.trim();
        if (!line || !line.startsWith("cpu "))
            return;

        const fields = line.split(/\s+/).slice(1, 9).map(value => Number(value));
        if (fields.length < 5 || fields.some(value => !isFinite(value)))
            return;

        const total = fields.reduce((sum, value) => sum + value, 0);
        const idle = fields[3] + fields[4];
        if (previousCpuTotal >= 0 && total > previousCpuTotal) {
            const busyDelta = (total - previousCpuTotal) - (idle - previousCpuIdle);
            cpuUsage = Math.max(0, Math.min(1, busyDelta / (total - previousCpuTotal)));
        }
        previousCpuTotal = total;
        previousCpuIdle = idle;
    }

    function parseMemory(contents: string): void {
        const totalMatch = /^MemTotal:\s+(\d+)/m.exec(contents);
        const availableMatch = /^MemAvailable:\s+(\d+)/m.exec(contents);
        if (!totalMatch || !availableMatch)
            return;

        const total = Number(totalMatch[1]);
        const available = Number(availableMatch[1]);
        if (total > 0)
            memoryUsage = Math.max(0, Math.min(1, (total - available) / total));
    }

    function parseDisk(contents: string): void {
        const lines = contents.trim().split("\n");
        if (lines.length < 2)
            return;

        const fields = lines[lines.length - 1].trim().split(/\s+/);
        if (fields.length < 5)
            return;

        const percentage = Number(fields[4].replace("%", ""));
        if (isFinite(percentage))
            diskUsage = Math.max(0, Math.min(1, percentage / 100));
    }

    onPanelOpenChanged: {
        Notifs.panelOpen = panelOpen;
        if (panelOpen) {
            for (const notification of Notifs.popups.slice())
                notification.popup = false;
            Qt.callLater(() => drawer.forceActiveFocus());
        }
    }

    Component.onCompleted: Notifs.panelOpen = panelOpen
    Component.onDestruction: Notifs.panelOpen = false

    Behavior on panelOffsetScale {
        NumberAnimation {
            duration: ShellConfig.notifications.animationMs
            easing.type: Easing.OutCubic
        }
    }

    IpcHandler {
        target: "notificationPanel"

        function toggle(): void { root.togglePanel(); }
        function open(): void { root.openPanel(); }
        function close(): void { root.closePanel(); }
        function clear(): void { root.clearAll(); }
        function isOpen(): bool { return root.panelOpen; }
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

    Process {
        id: diskProcess

        command: ["df", "-Pk", "/"]
        stdout: StdioCollector {
            onStreamFinished: root.parseDisk(text)
        }
    }

    Timer {
        interval: ShellConfig.notifications.statsUpdateMs
        running: root.panelOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuFile.reload();
            memoryFile.reload();
            if (!diskProcess.running)
                diskProcess.running = true;
        }
    }

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

    FolderListModel {
        id: screenshotFolder

        folder: `file://${Quickshell.env("HOME")}/Pictures/Screenshots`
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        showDirs: false
        showDotAndDotDot: false
        sortField: FolderListModel.Time
        sortReversed: false
    }

    FolderListModel {
        id: recordingFolder

        folder: `file://${Quickshell.env("HOME")}/Videos/Screenrecordings`
        nameFilters: ["*.mkv", "*.mp4", "*.mov", "*.webm"]
        showDirs: false
        showDotAndDotDot: false
        sortField: FolderListModel.Time
        sortReversed: false
    }

    Timer {
        id: wallpaperDelay

        interval: ShellConfig.notifications.animationMs + 40
        onTriggered: Quickshell.execDetached([
            "qs", "ipc", "call", "wallpaperCarousel", "toggle"
        ])
    }

    Timer {
        id: screenshotDelay

        interval: ShellConfig.notifications.animationMs + 40
        onTriggered: Quickshell.execDetached([
            `${Quickshell.env("HOME")}/.local/bin/quickshell-screenshot`
        ])
    }

    PanelWindow {
        id: panelWindow

        visible: root.panelOpen || root.panelOffsetScale < 1

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: root.panelOpen
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

        mask: Region {
            width: root.panelOpen ? panelWindow.width : 0
            height: panelWindow.height
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: ShellConfig.notifications.dimOpacity * Math.max(0,
                Math.min(1, 1 - root.panelOffsetScale))
            visible: root.panelOffsetScale < 1
            z: 0
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.panelOpen
            onClicked: root.closePanel()
            z: 1
        }

        Rectangle {
            id: drawer

            readonly property real configuredTopLeftRadius: Math.max(0,
                ShellConfig.notifications.topLeftBorderRadius(false))

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: (-width - 5) * root.panelOffsetScale
            }
            width: ShellConfig.notifications.panelWidth
            height: panelWindow.height
            color: "transparent"
            focus: root.panelOpen
            clip: false
            visible: root.panelOffsetScale < 1
            z: 2

            Keys.onEscapePressed: root.closePanel()

            MouseArea {
                anchors.fill: parent
                enabled: root.panelOpen
                z: -0.5
                onClicked: mouse.accepted = true
            }

            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: -ShellConfig.notifications.animationBleed
                }
                width: ShellConfig.notifications.animationBleed
                color: Theme.panel
                z: -1
            }

            Rectangle {
                x: parent.width - ShellConfig.notifications.borderWidth
                width: ShellConfig.visuals.shadowBleed
                height: parent.height
                z: -2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0
                        color: Theme.shadowColor
                    }
                    GradientStop {
                        position: 1
                        color: Qt.alpha(Theme.shadowColor, 0)
                    }
                }
                opacity: FloralSettings.shadows ? 0.72 : 0
            }

            StyledClippingRect {
                anchors.fill: parent
                radius: 0
                topLeftRadius: drawer.configuredTopLeftRadius
                topRightRadius: 0
                bottomLeftRadius: 0
                bottomRightRadius: 0
                color: Theme.panel
                contentUnderBorder: true
                z: -1

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0
                            color: Theme.panel
                        }
                        GradientStop {
                            position: 0.72
                            color: Theme.panel
                        }
                        GradientStop {
                            position: 1
                            color: Theme.panelQuiet
                        }
                    }
                    opacity: 0.76
                }

                FloralCorner {
                    anchors {
                        top: parent.top
                        right: parent.right
                        margins: ShellConfig.frame.lineThickness
                    }
                    width: ShellConfig.notifications.notificationOrnamentSize
                    height: width
                    location: FloralCorner.TopRight
                    strength: 0.82
                }

                FloralCorner {
                    anchors {
                        bottom: parent.bottom
                        right: parent.right
                        margins: ShellConfig.frame.lineThickness
                    }
                    width: ShellConfig.notifications.notificationOrnamentSize
                    height: width
                    location: FloralCorner.BottomRight
                    strength: 0.82
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: drawer.configuredTopLeftRadius > 0
                        ? drawer.configuredTopLeftRadius
                        : -ShellConfig.notifications.animationBleed
                }
                height: ShellConfig.notifications.borderWidth
                color: Theme.frameBorder
                z: ShellConfig.frame.borderZ
            }

            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: -ShellConfig.notifications.animationBleed
                    topMargin: drawer.configuredTopLeftRadius
                }
                width: ShellConfig.notifications.animationBleed
                    + ShellConfig.notifications.borderWidth
                color: Theme.frameBorder
                z: ShellConfig.frame.borderZ
            }

            Shape {
                anchors {
                    left: parent.left
                    top: parent.top
                }
                width: drawer.configuredTopLeftRadius
                    + ShellConfig.notifications.borderWidth
                height: width
                visible: drawer.configuredTopLeftRadius > 0
                z: ShellConfig.frame.borderZ

                ShapePath {
                    id: outerTopLeftPath

                    readonly property real halfStroke:
                        ShellConfig.notifications.borderWidth / 2

                    strokeWidth: ShellConfig.notifications.borderWidth
                    strokeColor: Theme.frameBorder
                    fillColor: "transparent"
                    capStyle: ShapePath.FlatCap
                    startX: drawer.configuredTopLeftRadius
                    startY: halfStroke

                    PathQuad {
                        x: outerTopLeftPath.halfStroke
                        y: drawer.configuredTopLeftRadius
                        controlX: outerTopLeftPath.halfStroke
                        controlY: outerTopLeftPath.halfStroke
                    }
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: -ShellConfig.notifications.animationBleed
                }
                height: ShellConfig.notifications.borderWidth
                color: Theme.frameBorder
                z: ShellConfig.frame.borderZ
            }

            Rectangle {
                anchors {
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                }
                width: ShellConfig.notifications.borderWidth
                color: Theme.frameBorder
                z: ShellConfig.frame.borderZ
            }

            Shape {
                id: innerFrame

                readonly property real frameRadius: 0
                readonly property real topLeftRadius:
                    ShellConfig.notifications.topLeftBorderRadius(true)

                anchors {
                    fill: parent
                    leftMargin: ShellConfig.notifications.panelInnerInset
                    rightMargin: ShellConfig.notifications.panelInnerInset
                    topMargin: ShellConfig.notifications.panelInnerInset
                    bottomMargin: ShellConfig.notifications.panelInnerInset
                }
                z: ShellConfig.frame.borderZ - 1

                ShapePath {
                    strokeWidth: ShellConfig.notifications.borderWidth
                    strokeColor: Theme.frameBorderSoft
                    fillColor: "transparent"
                    joinStyle: ShapePath.RoundJoin
                    startX: innerFrame.topLeftRadius
                    startY: 0

                    PathLine {
                        x: Math.max(0, innerFrame.width - innerFrame.frameRadius)
                        y: 0
                    }
                    PathQuad {
                        x: innerFrame.width
                        y: innerFrame.frameRadius
                        controlX: innerFrame.width
                        controlY: 0
                    }
                    PathLine {
                        x: innerFrame.width
                        y: Math.max(innerFrame.frameRadius,
                            innerFrame.height - innerFrame.frameRadius)
                    }
                    PathQuad {
                        x: Math.max(0, innerFrame.width - innerFrame.frameRadius)
                        y: innerFrame.height
                        controlX: innerFrame.width
                        controlY: innerFrame.height
                    }
                    PathLine {
                        x: 0
                        y: innerFrame.height
                    }
                    PathLine {
                        x: 0
                        y: innerFrame.topLeftRadius
                    }
                    PathQuad {
                        x: innerFrame.topLeftRadius
                        y: 0
                        controlX: 0
                        controlY: 0
                    }
                }
            }

            Item {
                id: header

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: ShellConfig.notifications.panelPadding
                    rightMargin: ShellConfig.notifications.panelPadding
                    topMargin: ShellConfig.notifications.panelInnerInset
                }
                height: ShellConfig.notifications.headerHeight

                Column {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        topMargin: ShellConfig.notifications.cardSpacing
                    }
                    spacing: 3

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "notifications"
                        color: Theme.moduleValue
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: ShellConfig.notifications.titleSize + 3
                            letterSpacing: ShellConfig.bar.labelLetterSpacing * 1.3
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Notifs.notClosed.length === 1
                            ? "1 notification"
                            : `${Notifs.notClosed.length} notifications`
                        color: Theme.moduleLabel
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            pixelSize: ShellConfig.notifications.metaSize
                        }
                    }
                }

                Row {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        bottomMargin: ShellConfig.notifications.cardSpacing + 4
                    }
                    spacing: ShellConfig.notifications.cardSpacing

                    HeaderAction {
                        icon: Notifs.dnd ? "notifications_off" : "do_not_disturb_on"
                        label: Notifs.dnd ? "dnd on" : "dnd"
                        active: Notifs.dnd
                        onTriggered: Notifs.dnd = !Notifs.dnd
                    }

                    HeaderAction {
                        icon: "delete_sweep"
                        label: "clear"
                        enabled: Notifs.notClosed.length > 0
                        onTriggered: root.clearAll()
                    }

                    HeaderAction {
                        icon: "close"
                        label: "close"
                        onTriggered: root.closePanel()
                    }
                }

                Item {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: ShellConfig.bar.separatorDiamondSize + 2

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - ShellConfig.notifications.cardPadding * 2
                        height: ShellConfig.notifications.borderWidth
                        color: Theme.frameBorderSoft
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: ShellConfig.bar.separatorDiamondSize
                        height: width
                        rotation: 45
                        color: Theme.panel
                        border.width: ShellConfig.notifications.borderWidth
                        border.color: Theme.frameBorderSoft
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            leftMargin: ShellConfig.notifications.cardPadding * 0.45
                            verticalCenter: parent.verticalCenter
                        }
                        width: ShellConfig.bar.separatorDiamondSize / 2
                        height: width
                        radius: width / 2
                        color: Theme.moduleLabel
                    }

                    Rectangle {
                        anchors {
                            right: parent.right
                            rightMargin: ShellConfig.notifications.cardPadding * 0.45
                            verticalCenter: parent.verticalCenter
                        }
                        width: ShellConfig.bar.separatorDiamondSize / 2
                        height: width
                        radius: width / 2
                        color: Theme.moduleLabel
                    }
                }
            }

            Row {
                id: quickActions

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: recentShots.top
                    leftMargin: ShellConfig.notifications.panelPadding
                    rightMargin: ShellConfig.notifications.panelPadding
                    bottomMargin: ShellConfig.notifications.cardSpacing
                }
                height: ShellConfig.notifications.actionHeight
                spacing: ShellConfig.notifications.cardSpacing

                HeaderAction {
                    icon: "wallpaper"
                    label: "wallpaper"
                    onTriggered: root.openWallpaperPicker()
                }

                HeaderAction {
                    icon: "photo_camera"
                    label: "screenshot"
                    onTriggered: root.takeScreenshot()
                }

                HeaderAction {
                    icon: Services.Recorder.running ? "stop_circle" : "screen_record"
                    label: Services.Recorder.running ? "stop" : "record"
                    active: Services.Recorder.running
                    onTriggered: {
                        root.showRecordings = true;
                        Services.Recorder.toggle();
                    }
                }
            }

            Item {
                id: screenshotsDivider

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: quickActions.top
                    leftMargin: ShellConfig.notifications.panelPadding
                    rightMargin: ShellConfig.notifications.panelPadding
                    bottomMargin: ShellConfig.notifications.cardSpacing
                }
                height: ShellConfig.bar.separatorDiamondSize + 2

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: ShellConfig.notifications.borderWidth
                    color: Theme.frameBorderSoft
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: ShellConfig.bar.separatorDiamondSize
                    height: width
                    rotation: 45
                    color: Theme.panel
                    border.width: ShellConfig.notifications.borderWidth
                    border.color: Theme.frameBorderSoft
                }
            }

            StyledClippingRect {
                id: recentShots

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: stats.top
                    leftMargin: ShellConfig.notifications.panelPadding
                    rightMargin: ShellConfig.notifications.panelPadding
                    bottomMargin: ShellConfig.notifications.cardSpacing
                }
                height: ShellConfig.notifications.screenshotAreaHeight
                radius: ShellConfig.notifications.cardRadius
                color: Theme.panelRaised
                border.width: ShellConfig.notifications.borderWidth
                border.color: Theme.frameBorderSoft
                contentUnderBorder: true
                layer.enabled: FloralSettings.shadows
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Theme.shadowColor
                    shadowOpacity: 0.38
                    shadowBlur: 0.72
                    shadowVerticalOffset: ShellConfig.scaled(2)
                    blurMax: ShellConfig.scaled(14)
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Theme.panelRaised }
                        GradientStop { position: 1; color: Theme.panelQuiet }
                    }
                    opacity: 0.64
                }

                FloralCorner {
                    anchors {
                        right: parent.right
                        bottom: parent.bottom
                    }
                    width: parent.height * 0.7
                    height: width
                    location: FloralCorner.BottomRight
                    strength: 0.16
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: ShellConfig.notifications.panelInnerInset - 2
                    radius: Math.max(0, recentShots.radius
                        - ShellConfig.notifications.panelInnerInset + 2)
                    color: "transparent"
                    border.width: ShellConfig.notifications.borderWidth
                    border.color: Theme.frameBorderFaint
                }

                Item {
                    id: recentHeader

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        leftMargin: ShellConfig.notifications.cardPadding
                        rightMargin: ShellConfig.notifications.cardPadding
                        topMargin: ShellConfig.notifications.cardPadding - 3
                    }
                    height: ShellConfig.notifications.titleSize + 2

                    Text {
                        anchors {
                            left: parent.left
                            right: captureCount.left
                            rightMargin: 9
                            verticalCenter: parent.verticalCenter
                        }
                        text: root.showRecordings
                            ? "~/Videos/Screenrecordings"
                            : "~/Pictures/Screenshots"
                        color: Theme.moduleLabel
                        elide: Text.ElideMiddle
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: ShellConfig.notifications.metaSize + 1
                            letterSpacing: ShellConfig.bar.labelLetterSpacing * 0.8
                        }
                    }

                    Text {
                        id: captureCount

                        anchors {
                            right: captureToggle.left
                            rightMargin: 9
                            verticalCenter: parent.verticalCenter
                        }
                        text: root.activeCaptureFolder.count
                            .toString().padStart(2, "0")
                        color: Theme.textMuted
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            pixelSize: ShellConfig.notifications.metaSize
                        }
                    }

                    Rectangle {
                        id: captureToggle

                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        width: recentHeader.height + 8
                        height: recentHeader.height + 5
                        radius: ShellConfig.visuals.controlRadius
                        color: captureTogglePointer.containsMouse
                            ? Theme.panelHighlight : Theme.panel
                        border.width: ShellConfig.bar.buttonBorderWidth
                        border.color: captureTogglePointer.containsMouse
                            ? Theme.frameBorder : Theme.frameBorderFaint
                        scale: captureTogglePointer.pressed ? 0.88
                            : captureTogglePointer.containsMouse ? 1.06 : 1

                        Behavior on scale {
                            NumberAnimation {
                                duration: ShellConfig.bar.menuAnimationMs
                                easing.type: Easing.OutCubic
                            }
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: root.showRecordings ? "movie" : "image"
                            color: captureTogglePointer.containsMouse
                                ? Theme.moduleLabel : Theme.moduleValue
                            fontStyle: Tokens.font.icon.small
                        }

                        MouseArea {
                            id: captureTogglePointer

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showRecordings = !root.showRecordings
                        }
                    }
                }

                ListView {
                    id: screenshotList

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: recentHeader.bottom
                        bottom: parent.bottom
                        leftMargin: ShellConfig.notifications.cardPadding - 3
                        rightMargin: ShellConfig.notifications.cardPadding - 3
                        topMargin: 4
                        bottomMargin: ShellConfig.notifications.cardPadding - 5
                    }
                    model: root.activeCaptureFolder.count
                    spacing: 2
                    interactive: contentHeight > height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 4500
                    maximumFlickVelocity: 1800
                    cacheBuffer: Math.max(0, height)

                    delegate: Rectangle {
                        id: shotRow

                        required property int index
                        readonly property string fileName:
                            root.activeCaptureFolder.get(index, "fileName") ?? "capture"

                        width: ListView.view.width
                        height: ShellConfig.notifications.screenshotRowHeight
                        radius: ShellConfig.visuals.controlRadius * 0.7
                        color: shotPointer.containsMouse
                            ? Theme.panelHighlight : "transparent"
                        border.width: shotPointer.containsMouse
                            ? ShellConfig.bar.buttonBorderWidth : 0
                        border.color: Theme.frameBorderFaint

                        Behavior on color {
                            ColorAnimation {
                                duration: ShellConfig.visuals.motionFast
                            }
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                                margins: ShellConfig.scaled(4)
                            }
                            width: ShellConfig.bar.hairlineThickness
                            radius: width / 2
                            color: Theme.moduleLabel
                            opacity: shotPointer.containsMouse ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: ShellConfig.visuals.motionFast
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        MaterialIcon {
                            anchors {
                                left: parent.left
                                leftMargin: 7
                                verticalCenter: parent.verticalCenter
                            }
                            text: root.showRecordings ? "movie" : "image"
                            color: shotPointer.containsMouse
                                ? Theme.moduleLabel : Theme.textMuted
                            fontStyle: Tokens.font.icon.small
                        }

                        Text {
                            anchors {
                                left: parent.left
                                right: openIcon.left
                                leftMargin: 30
                                rightMargin: 7
                                verticalCenter: parent.verticalCenter
                            }
                            text: shotRow.fileName.toLowerCase()
                            color: shotPointer.containsMouse
                                ? Theme.moduleValue : Theme.textMuted
                            elide: Text.ElideMiddle
                            renderType: Text.NativeRendering
                            font {
                                family: ShellConfig.typography.monoFamily
                                pixelSize: ShellConfig.notifications.metaSize
                            }
                        }

                        MaterialIcon {
                            id: openIcon

                            anchors {
                                right: parent.right
                                rightMargin: 7
                                verticalCenter: parent.verticalCenter
                            }
                            text: "open_in_new"
                            color: shotPointer.containsMouse
                                ? Theme.moduleLabel : Theme.textMuted
                            fontStyle: Tokens.font.icon.small
                        }

                        MouseArea {
                            id: shotPointer

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openCapture(shotRow.index)
                        }
                    }
                }

                Rectangle {
                    anchors.right: screenshotList.right
                    anchors.rightMargin: 1
                    y: screenshotList.y
                        + screenshotList.visibleArea.yPosition * screenshotList.height
                    z: 3
                    width: 2
                    height: Math.max(16, screenshotList.height
                        * screenshotList.visibleArea.heightRatio)
                    visible: screenshotList.contentHeight > screenshotList.height
                    radius: width / 2
                    color: Theme.frameBorder
                    opacity: screenshotList.moving ? 1 : 0.62

                    Behavior on opacity {
                        NumberAnimation {
                            duration: ShellConfig.bar.menuAnimationMs
                        }
                    }
                }

                Text {
                    anchors.centerIn: screenshotList
                    visible: root.activeCaptureFolder.count === 0
                    text: root.showRecordings
                        ? "no recordings yet" : "no screenshots yet"
                    color: Theme.textMuted
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        styleName: ShellConfig.typography.fineStyle
                        pixelSize: ShellConfig.notifications.metaSize
                    }
                }
            }

            Item {
                id: stats

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: ShellConfig.notifications.panelPadding
                    rightMargin: ShellConfig.notifications.panelPadding
                    bottomMargin: ShellConfig.notifications.panelInnerInset
                        + ShellConfig.notifications.cardSpacing
                }
                height: ShellConfig.notifications.statsHeight

                Item {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                    height: ShellConfig.bar.separatorDiamondSize + 2

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: ShellConfig.notifications.borderWidth
                        color: Theme.frameBorderSoft
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: ShellConfig.bar.separatorDiamondSize
                        height: width
                        rotation: 45
                        color: Theme.panel
                        border.width: ShellConfig.notifications.borderWidth
                        border.color: Theme.frameBorderSoft
                    }
                }

                StyledClippingRect {
                    id: statsFrame

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        topMargin: ShellConfig.notifications.cardSpacing + 8
                    }
                    radius: ShellConfig.notifications.cardRadius
                    color: Theme.panelRaised
                    border.width: ShellConfig.notifications.borderWidth
                    border.color: Theme.frameBorderSoft
                    contentUnderBorder: true
                    layer.enabled: FloralSettings.shadows
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Theme.shadowColor
                        shadowOpacity: 0.42
                        shadowBlur: 0.74
                        shadowVerticalOffset: ShellConfig.scaled(2)
                        blurMax: ShellConfig.scaled(14)
                    }

                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Theme.panelRaised }
                            GradientStop { position: 1; color: Theme.panelQuiet }
                        }
                        opacity: 0.6
                    }

                    FloralCorner {
                        anchors {
                            right: parent.right
                            bottom: parent.bottom
                        }
                        width: parent.height * 0.58
                        height: width
                        location: FloralCorner.BottomRight
                        strength: 0.14
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: ShellConfig.notifications.panelInnerInset - 2
                        radius: Math.max(0, statsFrame.radius
                            - ShellConfig.notifications.panelInnerInset + 2)
                        color: "transparent"
                        border.width: ShellConfig.notifications.borderWidth
                        border.color: Theme.frameBorderFaint
                    }

                    Column {
                        anchors {
                            fill: parent
                            margins: ShellConfig.notifications.cardPadding
                        }
                        spacing: Math.round(ShellConfig.notifications.cardSpacing * 0.65)

                        Item {
                            width: parent.width
                            height: ShellConfig.notifications.titleSize + 3

                            Text {
                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                }
                                text: "system usage"
                                color: Theme.moduleLabel
                                renderType: Text.NativeRendering
                                font {
                                    family: ShellConfig.typography.monoFamily
                                    styleName: ShellConfig.typography.fineStyle
                                    pixelSize: ShellConfig.notifications.titleSize
                                    letterSpacing: ShellConfig.bar.labelLetterSpacing
                                }
                            }

                            Text {
                                anchors {
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                }
                                text: Qt.formatDateTime(clock.date, "HH:mm:ss")
                                color: Theme.textMuted
                                renderType: Text.NativeRendering
                                font {
                                    family: ShellConfig.typography.monoFamily
                                    pixelSize: ShellConfig.notifications.metaSize + 1
                                }
                            }
                        }

                        StatRow {
                            label: "cpu"
                            value: root.cpuUsage
                            accent: Theme.accentPrimary
                        }

                        StatRow {
                            label: "ram"
                            value: root.memoryUsage
                            accent: Theme.accentTertiary
                        }

                        StatRow {
                            label: "disk"
                            value: root.diskUsage
                            accent: Theme.accentSecondary
                        }
                    }
                }
            }

            ListView {
                id: historyList

                anchors {
                    left: parent.left
                    right: parent.right
                    top: header.bottom
                    bottom: screenshotsDivider.top
                    margins: ShellConfig.notifications.panelPadding
                    topMargin: ShellConfig.notifications.cardSpacing
                    bottomMargin: ShellConfig.notifications.cardSpacing
                }
                clip: true
                spacing: ShellConfig.notifications.cardSpacing
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: Math.max(0, height)

                model: ScriptModel {
                    values: Notifs.list.filter(notification => !notification.closed)
                }

                delegate: NotificationCard {
                    required property var modelData

                    width: ListView.view.width
                    notification: modelData
                }

                displaced: Transition {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: ShellConfig.notifications.animationMs
                        }
                        NumberAnimation {
                            properties: "y"
                            duration: ShellConfig.notifications.animationMs
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                remove: Transition {
                    NumberAnimation {
                        properties: "x"
                        to: -ShellConfig.notifications.panelWidth
                        duration: ShellConfig.notifications.animationMs
                        easing.type: Easing.InCubic
                    }
                }
            }

            Item {
                anchors.fill: historyList
                visible: historyList.count === 0

                Column {
                    anchors.centerIn: parent
                    spacing: ShellConfig.notifications.cardSpacing + 3

                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: ShellConfig.notifications.emptyOrnamentSize
                        height: width

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.72
                            height: width
                            rotation: 45
                            color: Theme.panelRaised
                            border.width: ShellConfig.notifications.borderWidth
                            border.color: Theme.frameBorderSoft

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: ShellConfig.notifications.panelInnerInset
                                color: "transparent"
                                border.width: ShellConfig.notifications.borderWidth
                                border.color: Theme.frameBorderFaint
                            }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.48
                            height: width
                            radius: 0
                            color: Theme.panel
                            border.width: ShellConfig.notifications.borderWidth
                            border.color: Theme.frameBorder
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: Notifs.dnd ? "notifications_off" : "notifications"
                            color: Theme.moduleLabel
                            fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.25).build()
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: Theme.moduleValue
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: ShellConfig.notifications.titleSize + 13
                            letterSpacing: ShellConfig.bar.labelLetterSpacing
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "dddd  ·  MMMM d").toLowerCase()
                        color: Theme.moduleLabel
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: ShellConfig.notifications.metaSize
                            letterSpacing: ShellConfig.bar.labelLetterSpacing * 0.55
                        }
                    }

                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: ShellConfig.notifications.emptyOrnamentSize * 1.7
                        height: ShellConfig.bar.separatorDiamondSize + 2

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width
                            height: ShellConfig.notifications.borderWidth
                            color: Theme.frameBorderSoft
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: ShellConfig.bar.separatorDiamondSize
                            height: width
                            rotation: 45
                            color: Theme.panel
                            border.width: ShellConfig.notifications.borderWidth
                            border.color: Theme.frameBorder
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Notifs.dnd ? "do not disturb is active" : "all caught up"
                        color: Theme.textMuted
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: ShellConfig.notifications.bodySize + 1
                        }
                    }
                }
            }
        }
    }

    PanelWindow {
        id: toastHost

        readonly property int topInset: ShellConfig.bar.surfaceHeight
            + ShellConfig.notifications.toastEdgeMargin
        readonly property int listHeight: root.panelOpen ? 0 : Math.min(
            ShellConfig.notifications.toastMaximumHeight,
            toastList.contentHeight)

        visible: true
        anchors {
            top: true
            left: true
        }
        implicitWidth: ShellConfig.notifications.toastWidth
            + ShellConfig.notifications.toastEdgeMargin * 2
        implicitHeight: topInset + listHeight
            + ShellConfig.notifications.toastEdgeMargin
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        mask: Region {
            x: ShellConfig.notifications.toastEdgeMargin
            y: toastHost.topInset
            width: ShellConfig.notifications.toastWidth
            height: toastHost.listHeight
        }

        ListView {
            id: toastList

            x: ShellConfig.notifications.toastEdgeMargin
            y: toastHost.topInset
            width: ShellConfig.notifications.toastWidth
            height: toastHost.listHeight
            visible: !root.panelOpen
            spacing: ShellConfig.notifications.cardSpacing
            clip: false
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            model: ScriptModel {
                values: Notifs.popups.filter(notification => !notification.closed)
            }

            delegate: NotificationCard {
                required property var modelData

                width: ListView.view.width
                notification: modelData
                popupMode: true
            }

            displaced: Transition {
                SequentialAnimation {
                    PauseAnimation {
                        duration: ShellConfig.notifications.animationMs
                    }
                    NumberAnimation {
                        properties: "y"
                        duration: ShellConfig.notifications.animationMs
                        easing.type: Easing.OutCubic
                    }
                }
            }

            remove: Transition {
                NumberAnimation {
                    properties: "x"
                    to: -ShellConfig.notifications.panelWidth
                    duration: ShellConfig.notifications.animationMs
                    easing.type: Easing.InCubic
                }
            }
        }
    }

    component HeaderAction: Rectangle {
        id: action

        property string icon
        required property string label
        property bool active
        signal triggered

        width: root.actionWidth
        height: ShellConfig.notifications.actionHeight
        radius: ShellConfig.visuals.controlRadius
        color: active
            ? Theme.panelHighlight
            : actionPointer.containsMouse ? Theme.panelHighlight : Theme.panelRaised
        opacity: enabled ? 1 : 0.35
        border.width: ShellConfig.notifications.borderWidth
        border.color: active || actionPointer.containsMouse
            ? Theme.frameBorder
            : Theme.frameBorderSoft
        scale: actionPointer.pressed ? 0.93
            : actionPointer.containsMouse ? 1.015 : 1
        layer.enabled: FloralSettings.shadows && action.enabled
            && actionPointer.containsMouse
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadowSoft
            shadowOpacity: actionPointer.containsMouse ? 0.58 : 0.26
            shadowBlur: 0.66
            shadowVerticalOffset: ShellConfig.scaled(2)
            blurMax: ShellConfig.scaled(10)
        }

        Behavior on scale {
            NumberAnimation {
                duration: ShellConfig.bar.menuAnimationMs
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: ShellConfig.scaled(4)
            radius: Math.max(0, action.radius - ShellConfig.scaled(4))
            color: "transparent"
            border.width: ShellConfig.bar.hairlineThickness
            border.color: action.active || actionPointer.containsMouse
                ? Theme.frameBorderSoft : Theme.frameBorderFaint
        }

        Row {
            anchors.centerIn: parent
            spacing: Math.round(ShellConfig.notifications.cardSpacing * 0.45)

            MaterialIcon {
                visible: action.icon.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: action.icon
                color: action.active ? Theme.moduleLabel : Theme.moduleValue
                fontStyle: Tokens.font.icon.medium
            }

            Text {
                id: actionLabel

                anchors.verticalCenter: parent.verticalCenter
                text: action.label
                color: action.active ? Theme.moduleLabel : Theme.moduleValue
                renderType: Text.NativeRendering
                font {
                    family: ShellConfig.typography.monoFamily
                    styleName: ShellConfig.typography.fineStyle
                    pixelSize: ShellConfig.notifications.metaSize
                }
            }
        }

        MouseArea {
            id: actionPointer

            anchors.fill: parent
            enabled: action.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.triggered()
        }
    }

    component StatRow: Rectangle {
        id: statRow

        required property string label
        required property real value
        required property color accent
        readonly property real safeValue: Math.max(0, Math.min(1, value))

        width: parent?.width ?? 0
        height: ShellConfig.notifications.statRowHeight
        radius: ShellConfig.visuals.controlRadius
        color: Theme.panel
        border.width: ShellConfig.notifications.borderWidth
        border.color: Theme.frameBorderFaint

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                margins: ShellConfig.notifications.borderWidth
            }
            width: 3
            color: statRow.accent
        }

        Text {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: ShellConfig.notifications.cardPadding
                verticalCenterOffset: -Math.round(
                    (ShellConfig.notifications.statBarHeight + 7) / 2)
            }
            text: statRow.label
            color: statRow.accent
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                styleName: ShellConfig.typography.fineStyle
                pixelSize: ShellConfig.notifications.titleSize
                letterSpacing: ShellConfig.bar.labelLetterSpacing * 0.6
            }
        }

        Text {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: ShellConfig.notifications.cardPadding
                verticalCenterOffset: -Math.round(
                    (ShellConfig.notifications.statBarHeight + 7) / 2)
            }
            text: `${Math.round(statRow.safeValue * 100)}%`
            color: Theme.moduleValue
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                pixelSize: ShellConfig.notifications.titleSize
                weight: Font.DemiBold
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: ShellConfig.notifications.cardPadding
                rightMargin: ShellConfig.notifications.cardPadding
                bottomMargin: 7
            }
            height: ShellConfig.notifications.statBarHeight
            radius: ShellConfig.visuals.controlRadius * 0.45
            color: Theme.panelHighlight
            border.width: 1
            border.color: Theme.frameBorderFaint

            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    margins: 1
                }
                width: Math.max(0, (parent.width - 2) * statRow.safeValue)
                radius: Math.min(parent.radius, width / 2)
                color: statRow.accent

                Behavior on width {
                    NumberAnimation {
                        duration: ShellConfig.notifications.animationMs
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
