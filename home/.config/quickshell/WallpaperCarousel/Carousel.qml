/*
 * this file draws the wallpaper picker
 * wallpaper scripts do the real theme switch
 * keep both parts together
 */

import QtQuick
import QtQuick.Effects
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.components

Item {
    id: root

    property string defaultWallpaperFolder: ""
    property string currentWallpaperPath: ""
    property var extraDirectories: []
    property string wlrNamespace: "plugins:wallpaperCarousel"
    property var cfg: ({})
    property var getFocusedScreen: () => null
    property bool hasWallpaperConfigured: true
    property string shellSettingsHint: "Open your shell settings → Wallpaper to configure a wallpaper directory."

    signal wallpaperPicked(string fullPath, string screenName)

    readonly property var overlayScreen: overlay.screen

    readonly property string wallpaperFolder: {
        const ov = (cfg.wallpaperDirectory ?? "").trim();
        return ov || defaultWallpaperFolder;
    }

    readonly property string _carouselMode: cfg.carouselMode ?? "wrap"
    readonly property bool _isInfinite: _carouselMode === "infinite"
    readonly property bool _wrapsIndex: _carouselMode !== "standard"
    on_CarouselModeChanged: if (_initialSyncDone) Qt.callLater(_syncStableModel)

    readonly property var _currentView: _isInfinite ? pathView : listView
    readonly property string wallpaperFolderUrl: "file://" + wallpaperFolder
    readonly property string currentWallpaperFile:
        (currentWallpaperPath || "").split('/').pop()

    property var _folderCache: ({})
    property bool _initialSyncDone: false
    property int _currentCacheIndex: -1
    property var _cacheEntries: []

    readonly property var _nameFilters: [
        "*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif",
        "*.bmp", "*.jxl", "*.avif", "*.heif", "*.exr"
    ]

    onCurrentWallpaperPathChanged: {
        if (folderModel.status === FolderListModel.Ready && folderModel.count > 0) {
            root._currentCacheIndex = root._findCurrentIndex();
            root._rebuildCacheEntries();
        }
    }

    onWallpaperFolderUrlChanged: {
        modelSyncTimer.stop();
        const cached = _folderCache[wallpaperFolder];
        if (cached) {
            _populateStableModel(cached);
            carousel.tryFocus();
        } else {
            stableModel.clear();
        }
        root._initialSyncDone = false;
    }

    ListModel { id: stableModel }

    Timer {
        id: modelSyncTimer
        interval: 1500
        onTriggered: root._syncStableModel()
    }

    FolderListModel {
        id: folderModel
        folder: root.wallpaperFolderUrl
        nameFilters: root._nameFilters
        showDirs: false
        sortField: FolderListModel.Name

        onStatusChanged: {
            if (status === FolderListModel.Ready && !root._initialSyncDone) {
                root._syncStableModel();
                root._initialSyncDone = true;
            }
        }
        onCountChanged: {
            if (root._initialSyncDone)
                modelSyncTimer.restart();
        }
    }

    function _readFolderModel(model) {
        var entries = [];
        for (var i = 0; i < model.count; i++)
            entries.push({
                fileName: model.get(i, "fileName"),
                fileUrl:  model.get(i, "fileUrl").toString()
            });
        return entries;
    }

    function _findCurrentIndex() {
        const fileName = (root.currentWallpaperPath || "").split('/').pop();
        if (!fileName) return 0;
        for (let i = 0; i < folderModel.count; i++) {
            if (folderModel.get(i, "fileName") === fileName)
                return i;
        }
        return 0;
    }

    function _rebuildCacheEntries() {
        const count = folderModel.count;
        if (count === 0) { root._cacheEntries = []; return; }
        const center = root._currentCacheIndex >= 0 ? root._currentCacheIndex : root._findCurrentIndex();
        const radius = Math.floor(((root.cfg.cacheSize !== undefined) ? parseInt(root.cfg.cacheSize) : 200) / 2);
        const start = Math.max(0, center - radius);
        const end = Math.min(count - 1, center + radius);
        const entries = [];
        for (let i = start; i <= end; i++)
            entries.push(folderModel.get(i, "fileUrl").toString());
        root._cacheEntries = entries;
    }

    function _populateStableModel(entries) {
        const activeView = root._currentView;
        const savedIndex = activeView.currentIndex;
        const savedFile = (savedIndex >= 0 && savedIndex < stableModel.count)
            ? stableModel.get(savedIndex).fileName : "";

        stableModel.clear();
        for (let i = 0; i < entries.length; i++)
            stableModel.append(entries[i]);

        if (root._isInfinite && entries.length > 0) {
            const viewWidth = pathView.width > 0 ? pathView.width : 2560;
            const minCount = Math.ceil(viewWidth / carousel.itemWidth) + 6;
            const baseCount = entries.length;
            const targetCount = baseCount * Math.ceil(minCount / baseCount);
            while (stableModel.count < targetCount) {
                for (let i = 0; i < baseCount && stableModel.count < targetCount; i++)
                    stableModel.append(entries[i]);
            }
        }

        if (savedFile) {
            for (let i = 0; i < stableModel.count; i++) {
                if (stableModel.get(i).fileName === savedFile) {
                    activeView.currentIndex = i;
                    break;
                }
            }
        }
    }

    function _syncStableModel() {
        const entries = _readFolderModel(folderModel);
        root._folderCache[root.wallpaperFolder] = entries;
        _populateStableModel(entries);
        root._currentCacheIndex = root._findCurrentIndex();
        root._rebuildCacheEntries();
        carousel.tryFocus();
    }

    function toggle() {
        if (overlay.visible) close(); else open();
    }

    function open() {
        carousel.initialFocusSet = false;
        const focusedScreen = root.getFocusedScreen();
        if (focusedScreen)
            overlay.screen = focusedScreen;
        overlay.visible = true;
        carousel.tryFocus();
        Qt.callLater(() => root._currentView.forceActiveFocus());
    }

    function close() {
        overlay.visible = false;
    }

    function cycle(direction: int): string {
        const v = root._currentView;
        if (!overlay.visible) {
            open();
            return "opened:" + v.currentIndex;
        }
        if (direction > 0) v.incrementCurrentIndex();
        else v.decrementCurrentIndex();
        return "index:" + v.currentIndex;
    }

    IpcHandler {
        target: "wallpaperCarousel"
        function toggle(): string   { root.toggle(); return overlay.visible ? "opened" : "closed"; }
        function open(): string     { if (!overlay.visible) root.open(); return "opened"; }
        function close(): string    { if (overlay.visible) root.close(); return "closed"; }
        function cycleNext(): string     { return root.cycle(+1); }
        function cyclePrevious(): string { return root.cycle(-1); }
    }

    PanelWindow {
        id: overlay
        visible: false
        color: "transparent"

        WlrLayershell.namespace: root.wlrNamespace
        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        anchors { top: true; left: true; right: true; bottom: true }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.panel }
                GradientStop { position: 0.55; color: Theme.panelRaised }
                GradientStop { position: 1; color: Theme.panel }
            }
            opacity: overlay.visible
                ? Math.min(0.88, carousel.overlayOpacity / 100) : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: ShellConfig.visuals.motionNormal
                    easing.type: Easing.InOutCubic
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: overlay.visible && carousel.confirmingIndex < 0
            onClicked: root.close()
            z: 0
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
            }
            y: wallpaperPanel.y - height
            height: ShellConfig.scaled(26)
            z: 0.5
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.alpha(Theme.shadowColor, 0)
                }
                GradientStop {
                    position: 1
                    color: Theme.shadowColor
                }
            }
            opacity: FloralSettings.shadows ? 0.8 : 0
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
            }
            y: wallpaperPanel.y + wallpaperPanel.height
            height: ShellConfig.scaled(26)
            z: 0.5
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Theme.shadowColor
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(Theme.shadowColor, 0)
                }
            }
            opacity: FloralSettings.shadows ? 0.8 : 0
        }

        Rectangle {
            id: wallpaperPanel

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            height: Math.min(parent.height - ShellConfig.bar.surfaceHeight - 40,
                ShellConfig.wallpaperPicker.panelHeight)
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.panel }
                GradientStop { position: 0.5; color: Theme.panelRaised }
                GradientStop { position: 1; color: Theme.panel }
            }
            border.width: ShellConfig.notifications.borderWidth
            border.color: Theme.frameBorder
            clip: false
            z: 1

            MouseArea {
                anchors.fill: parent
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: ShellConfig.wallpaperPicker.panelInset
                color: "transparent"
                border.width: ShellConfig.notifications.borderWidth
                border.color: Theme.frameBorderSoft
                z: 40
            }

            FloralCorner {
                anchors {
                    left: parent.left
                    top: parent.top
                    margins: ShellConfig.notifications.borderWidth
                }
                width: ShellConfig.wallpaperPicker.ornamentSize
                height: width
                location: FloralCorner.TopLeft
                strength: 0.84
                z: 45
            }

            FloralCorner {
                anchors {
                    right: parent.right
                    top: parent.top
                    margins: ShellConfig.notifications.borderWidth
                }
                width: ShellConfig.wallpaperPicker.ornamentSize
                height: width
                location: FloralCorner.TopRight
                strength: 0.84
                z: 45
            }

            FloralCorner {
                anchors {
                    left: parent.left
                    bottom: parent.bottom
                    margins: ShellConfig.notifications.borderWidth
                }
                width: ShellConfig.wallpaperPicker.ornamentSize
                height: width
                location: FloralCorner.BottomLeft
                strength: 0.84
                z: 45
            }

            FloralCorner {
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    margins: ShellConfig.notifications.borderWidth
                }
                width: ShellConfig.wallpaperPicker.ornamentSize
                height: width
                location: FloralCorner.BottomRight
                strength: 0.84
                z: 45
            }

            Item {
                id: wallpaperHeader

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: ShellConfig.wallpaperPicker.horizontalPadding
                    rightMargin: ShellConfig.wallpaperPicker.horizontalPadding
                }
                height: ShellConfig.wallpaperPicker.headerHeight
                z: 42

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "wallpapers"
                        color: Theme.moduleValue
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: ShellConfig.wallpaperPicker.titleSize
                            letterSpacing: ShellConfig.bar.labelLetterSpacing * 1.2
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(implicitWidth,
                            wallpaperHeader.width - ShellConfig.wallpaperPicker.ornamentSize * 2)
                        text: `${folderModel.count} images  ·  ${root.wallpaperFolder}`
                        color: Theme.moduleLabel
                        elide: Text.ElideMiddle
                        horizontalAlignment: Text.AlignHCenter
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            pixelSize: ShellConfig.wallpaperPicker.detailSize
                        }
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
            }

            Item {
                id: wallpaperFooter

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: ShellConfig.wallpaperPicker.horizontalPadding
                    rightMargin: ShellConfig.wallpaperPicker.horizontalPadding
                }
                height: ShellConfig.wallpaperPicker.footerHeight
                z: 42

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

                Row {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        bottom: parent.bottom
                        topMargin: 10
                        bottomMargin: 7
                    }
                    spacing: ShellConfig.scaled(32)

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: ShellConfig.scaled(430)
                        spacing: 3

                        Text {
                            width: parent.width
                            text: root._currentView.currentItem
                                ? root._currentView.currentItem.fileName : ""
                            color: Theme.moduleValue
                            elide: Text.ElideMiddle
                            horizontalAlignment: Text.AlignRight
                            renderType: Text.NativeRendering
                            font {
                                family: ShellConfig.typography.monoFamily
                                styleName: ShellConfig.typography.fineStyle
                                pixelSize: ShellConfig.notifications.bodySize
                            }
                        }

                        Text {
                            width: parent.width
                            text: root._currentView.currentItem
                                ? `${root._currentView.currentIndex + 1} of ${stableModel.count}`
                                    + (root._currentView.currentItem.fileName
                                        === root.currentWallpaperFile ? "  ·  current" : "")
                                : ""
                            color: Theme.moduleLabel
                            horizontalAlignment: Text.AlignRight
                            renderType: Text.NativeRendering
                            font {
                                family: ShellConfig.typography.monoFamily
                                pixelSize: ShellConfig.wallpaperPicker.detailSize
                                letterSpacing: ShellConfig.bar.labelLetterSpacing * 0.25
                            }
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: ShellConfig.notifications.borderWidth
                        height: parent.height * 0.62
                        color: Theme.frameBorderFaint
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: ShellConfig.scaled(18)

                        FooterHint {
                            keyText: "←  →"
                            labelText: "browse"
                        }

                        FooterHint {
                            keyText: "enter"
                            labelText: "apply"
                        }

                        FooterHint {
                            keyText: "esc"
                            labelText: "close"
                        }
                    }
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: ShellConfig.wallpaperPicker.horizontalPadding
                    topMargin: ShellConfig.wallpaperPicker.headerHeight
                        + ShellConfig.notifications.cardSpacing
                    bottomMargin: ShellConfig.wallpaperPicker.footerHeight
                        + ShellConfig.notifications.cardSpacing
                }
                width: ShellConfig.wallpaperPicker.edgeFadeWidth
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.panel }
                    GradientStop { position: 1; color: Qt.alpha(Theme.panel, 0) }
                }
                z: 15
            }

            Rectangle {
                anchors {
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    rightMargin: ShellConfig.wallpaperPicker.horizontalPadding
                    topMargin: ShellConfig.wallpaperPicker.headerHeight
                        + ShellConfig.notifications.cardSpacing
                    bottomMargin: ShellConfig.wallpaperPicker.footerHeight
                        + ShellConfig.notifications.cardSpacing
                }
                width: ShellConfig.wallpaperPicker.edgeFadeWidth
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.alpha(Theme.panel, 0) }
                    GradientStop { position: 1; color: Theme.panel }
                }
                z: 15
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: ShellConfig.notifications.borderWidth
                border.color: Theme.frameBorder
                z: 50
            }
        }

        Item {
            id: carousel
            parent: wallpaperPanel
            anchors {
                fill: parent
                leftMargin: ShellConfig.wallpaperPicker.horizontalPadding
                rightMargin: ShellConfig.wallpaperPicker.horizontalPadding
                topMargin: ShellConfig.wallpaperPicker.headerHeight
                    + ShellConfig.notifications.cardSpacing
                bottomMargin: ShellConfig.wallpaperPicker.footerHeight
                    + ShellConfig.notifications.cardSpacing
            }
            opacity: overlay.visible ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: ShellConfig.visuals.motionNormal
                    easing.type: Easing.InOutCubic
                }
            }
            clip: true
            z: 3

            property bool initialFocusSet: false
            function tryFocus() {
                if (initialFocusSet) return;

                let targetIndex = 0;
                const currentFile = (root.currentWallpaperPath || "").split('/').pop();
                if (currentFile && stableModel.count > 0) {
                    for (let i = 0; i < stableModel.count; i++) {
                        if (stableModel.get(i).fileName === currentFile) {
                            targetIndex = i;
                            break;
                        }
                    }
                }

                const v = root._currentView;
                if (v.count > 0) {
                    const safeIndex = Math.min(targetIndex, v.count - 1);
                    v.currentIndex = safeIndex;
                    if (!root._isInfinite)
                        v.positionViewAtIndex(safeIndex, ListView.Center);
                    initialFocusSet = true;
                }

                carousel.heldIndex = -1;
                holdTimer.start();
            }

            readonly property int itemWidth:    parseInt(root.cfg.itemWidth)  || 300
            readonly property int itemHeight:   parseInt(root.cfg.itemHeight) || 420
            readonly property int borderWidth:  (root.cfg.borderWidth  !== undefined) ? parseInt(root.cfg.borderWidth)  : 3
            readonly property int spacing:      (root.cfg.spacing      !== undefined) ? parseInt(root.cfg.spacing)      : 10
            readonly property int overlayOpacity: (root.cfg.overlayOpacity !== undefined) ? parseInt(root.cfg.overlayOpacity) : 80
            readonly property int cornerRadius: ShellConfig.visuals.cardRadius
            readonly property bool enableRounding: true
            readonly property real skewFactor: 0
            readonly property int _baseWallpaperCount: folderModel.count

            readonly property real selectedScale: {
                let val = (root.cfg.selectedScale !== undefined) ? parseFloat(root.cfg.selectedScale) : 108;
                return val > 10 ? val / 100.0 : val;
            }
            readonly property real selectedWidth: itemWidth * 1.25
            readonly property real sideWidth: itemWidth * 0.58
            readonly property real availableCardHeight: Math.max(160,
                height - ShellConfig.visuals.shadowBleed * 1.15)
            readonly property real selectedHeight: Math.min(itemHeight,
                availableCardHeight)
            readonly property real sideHeight: Math.min(itemHeight * 0.88,
                Math.max(140, selectedHeight - ShellConfig.scaled(16)))
            readonly property real slotWidth: sideWidth + spacing
            readonly property int animationDuration: ShellConfig.visuals.motionNormal
            readonly property bool enableHoldExpand: !!(root.cfg.enableHoldExpand === true || root.cfg.enableHoldExpand === "true")
            readonly property real holdExpandRatio: ((root.cfg.holdExpandRatio !== undefined) ? parseFloat(root.cfg.holdExpandRatio) : 35.0) / 100.0
            readonly property int holdDelay: (root.cfg.holdDelay !== undefined) ? parseInt(root.cfg.holdDelay) : 1500

            property int heldIndex: -1

            Timer {
                id: holdTimer
                interval: carousel.holdDelay
                onTriggered: {
                    if (carousel.enableHoldExpand)
                        carousel.heldIndex = root._currentView.currentIndex;
                }
            }

            property int confirmingIndex: -1

            function confirmPick(idx, path) {
                confirmingIndex = idx;
                confirmTimer.start();
                if (path) {
                    const screenName = overlay.screen ? overlay.screen.name : "";
                    root.wallpaperPicked(path, screenName);
                }
            }

            Timer {
                id: confirmTimer
                interval: 360
                onTriggered: {
                    carousel.confirmingIndex = -1;
                    root.close();
                }
            }

            Component {
                id: carouselDelegate

                Item {
                    id: delegateRoot
                    readonly property real targetWidth: isCurrent ? carousel.selectedWidth : carousel.sideWidth
                    readonly property real targetHeight: isCurrent
                        ? carousel.selectedHeight : carousel.sideHeight

                    width: carousel.slotWidth
                    height: carousel.selectedHeight
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

                    required property int index
                    required property string fileName
                    required property string fileUrl

                    readonly property bool _effectivelyInfinite: root._isInfinite

                    readonly property bool isCurrent: _effectivelyInfinite ? PathView.isCurrentItem : ListView.isCurrentItem
                    readonly property bool isApplied:
                        fileName === root.currentWallpaperFile

                    readonly property int signedDistance: {
                        if (_effectivelyInfinite) {
                            let distance = index - pathView.currentIndex;
                            const half = stableModel.count / 2;
                            if (distance > half)
                                distance -= stableModel.count;
                            else if (distance < -half)
                                distance += stableModel.count;
                            return distance;
                        }
                        return index - listView.currentIndex;
                    }

                    readonly property real targetOffset: {
                        if (isCurrent || signedDistance === 0)
                            return 0;
                        const expansion = carousel.selectedWidth - carousel.sideWidth;
                        return signedDistance < 0 ? -(expansion / 2) : expansion / 2;
                    }

                    readonly property real _dupeFade: {
                        if (!_effectivelyInfinite) return 1.0;
                        const base = carousel._baseWallpaperCount;
                        if (base <= 0 || base >= stableModel.count) return 1.0;
                        const n = stableModel.count;
                        const cur = pathView.currentIndex;
                        const wpOffset = ((index % base) - (cur % base) + base) % base;
                        const leftCount  = Math.floor(base / 2);
                        const rightCount = Math.floor((base - 1) / 2);
                        let target;
                        if (wpOffset === 0)
                            target = cur;
                        else if (wpOffset <= rightCount)
                            target = (cur + wpOffset) % n;
                        else if (base - wpOffset <= leftCount)
                            target = (cur - (base - wpOffset) + n) % n;
                        else
                            return 0.0;
                        return index === target ? 1.0 : 0.0;
                    }

                    z: carousel.confirmingIndex === index ? 100 : isCurrent ? 10 : 1

                    function pickWallpaper() {
                        if (carousel.confirmingIndex >= 0) return;
                        carousel.confirmPick(index, root.wallpaperFolder + "/" + fileName);
                    }

                    Item {
                        id: visualCard
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.horizontalCenterOffset: delegateRoot.targetOffset

                        readonly property bool isConfirmed: carousel.confirmingIndex === delegateRoot.index
                        readonly property bool isHeld: carousel.heldIndex === delegateRoot.index
                        property real confirmationScale: 1.0
                        property real confirmationOpacity: 1.0

                        width: delegateRoot.targetWidth
                        height: delegateRoot.targetHeight
                        scale: confirmationScale
                            * (cardPointer.containsMouse ? 1.008 : 1)

                        Behavior on width {
                            NumberAnimation {
                                duration: carousel.animationDuration
                                easing.type: Easing.InOutCubic
                            }
                        }
                        Behavior on height {
                            NumberAnimation {
                                duration: carousel.animationDuration
                                easing.type: Easing.InOutCubic
                            }
                        }
                        Behavior on anchors.horizontalCenterOffset {
                            NumberAnimation {
                                duration: carousel.animationDuration
                                easing.type: Easing.InOutCubic
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: ShellConfig.visuals.motionFast
                                easing.type: Easing.OutCubic
                            }
                        }

                        readonly property bool isOtherConfirming: carousel.confirmingIndex >= 0 && !isConfirmed
                        opacity: (isOtherConfirming ? 0.0 : isCurrent ? 1.0 : 0.6) * delegateRoot._dupeFade

                        onIsConfirmedChanged: {
                            if (isConfirmed) {
                                confirmationScale = 1.0;
                                confirmationOpacity = 1.0;
                                confirmAnimation.restart();
                            } else {
                                confirmAnimation.stop();
                                confirmationScale = 1.0;
                                confirmationOpacity = 1.0;
                            }
                        }

                        SequentialAnimation {
                            id: confirmAnimation

                            NumberAnimation {
                                target: visualCard
                                property: "confirmationScale"
                                from: 1.0
                                to: 1.055
                                duration: 140
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                target: visualCard
                                property: "confirmationOpacity"
                                from: 1.0
                                to: 0.0
                                duration: 180
                                easing.type: Easing.InCubic
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: carousel.animationDuration
                                easing.type: Easing.InOutCubic
                            }
                        }

                        RectangularShadow {
                            anchors.fill: cardSurface
                            visible: delegateRoot.isCurrent
                            radius: cardSurface.radius
                            blur: ShellConfig.visuals.shadowBlur * 0.88
                            spread: delegateRoot.isCurrent
                                ? ShellConfig.visuals.shadowSpread : 0
                            offset: Qt.vector2d(0,
                                delegateRoot.isCurrent
                                    ? ShellConfig.visuals.shadowOffsetY
                                    : ShellConfig.scaled(2))
                            color: delegateRoot.isCurrent
                                ? Theme.shadowColor : Theme.shadowSoft
                            opacity: visualCard.confirmationOpacity
                                * (delegateRoot.isCurrent ? 1 : 0.42)
                        }

                        StyledClippingRect {
                            id: cardSurface

                            anchors.fill: parent
                            opacity: visualCard.confirmationOpacity
                            radius: carousel.cornerRadius
                            color: Theme.panelRaised
                            border.width: delegateRoot.isCurrent
                                ? carousel.borderWidth : ShellConfig.notifications.borderWidth
                            border.color: delegateRoot.isCurrent
                                ? Theme.frameBorder : Theme.frameBorderSoft
                            contentUnderBorder: true

                            Image {
                                id: wallpaperImage

                                anchors.fill: parent
                                anchors.margins: carousel.borderWidth + 2
                                source: delegateRoot.fileUrl
                                sourceSize: Qt.size(carousel.selectedWidth,
                                    carousel.selectedHeight)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                smooth: true
                                mipmap: true
                                opacity: delegateRoot.isCurrent ? 1 : 0.68

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: carousel.animationDuration
                                        easing.type: Easing.InOutCubic
                                    }
                                }
                            }

                            Rectangle {
                                anchors.fill: wallpaperImage
                                color: Theme.panel
                                opacity: delegateRoot.isCurrent ? 0 : 0.25

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: carousel.animationDuration
                                        easing.type: Easing.InOutCubic
                                    }
                                }
                            }

                            FloralCorner {
                                visible: delegateRoot.isCurrent
                                anchors {
                                    right: parent.right
                                    top: parent.top
                                    margins: carousel.borderWidth + 3
                                }
                                width: Math.min(parent.width, parent.height) * 0.34
                                height: width
                                location: FloralCorner.TopRight
                                strength: 0.44
                            }

                            FloralCorner {
                                visible: delegateRoot.isCurrent
                                anchors {
                                    left: parent.left
                                    bottom: parent.bottom
                                    margins: carousel.borderWidth + 3
                                }
                                width: Math.min(parent.width, parent.height) * 0.3
                                height: width
                                location: FloralCorner.BottomLeft
                                strength: 0.32
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: ShellConfig.wallpaperPicker.panelInset
                                radius: Math.max(0, parent.radius - anchors.margins)
                                color: "transparent"
                                border.width: ShellConfig.notifications.borderWidth
                                border.color: delegateRoot.isCurrent
                                    ? Theme.frameBorderSoft : Theme.frameBorderFaint
                            }

                            Rectangle {
                                visible: delegateRoot.isApplied
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    leftMargin: ShellConfig.notifications.cardPadding
                                    topMargin: ShellConfig.notifications.cardPadding
                                }
                                width: appliedLabel.implicitWidth
                                    + ShellConfig.scaled(18)
                                height: ShellConfig.scaled(25)
                                radius: ShellConfig.visuals.controlRadius
                                color: Theme.panelVeil
                                border.width: ShellConfig.notifications.borderWidth
                                border.color: Theme.moduleLabel

                                Text {
                                    id: appliedLabel

                                    anchors.centerIn: parent
                                    text: "current"
                                    color: Theme.moduleValue
                                    renderType: Text.NativeRendering
                                    font {
                                        family: ShellConfig.typography.monoFamily
                                        styleName: ShellConfig.typography.fineStyle
                                        pixelSize: ShellConfig.wallpaperPicker.detailSize
                                    }
                                }
                            }

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                    margins: carousel.borderWidth + 2
                                }
                                height: ShellConfig.notifications.actionHeight * 1.35
                                visible: delegateRoot.isCurrent
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0
                                        color: Qt.alpha(Theme.panel, 0)
                                    }
                                    GradientStop {
                                        position: 0.55
                                        color: Qt.alpha(Theme.panel, 0.78)
                                    }
                                    GradientStop {
                                        position: 1
                                        color: Theme.panel
                                    }
                                }
                            }

                            Text {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                    leftMargin: ShellConfig.notifications.cardPadding
                                    rightMargin: ShellConfig.notifications.cardPadding
                                    bottomMargin: Math.round(
                                        ShellConfig.notifications.actionHeight * 0.22)
                                }
                                visible: delegateRoot.isCurrent
                                text: delegateRoot.fileName
                                color: Theme.moduleValue
                                elide: Text.ElideMiddle
                                horizontalAlignment: Text.AlignHCenter
                                renderType: Text.NativeRendering
                                font {
                                    family: ShellConfig.typography.monoFamily
                                    styleName: ShellConfig.typography.fineStyle
                                    pixelSize: ShellConfig.wallpaperPicker.detailSize
                                }
                            }

                            MouseArea {
                                id: cardPointer

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: delegateRoot.pickWallpaper()
                                z: 20
                            }
                        }
                    }
                }
            }

            PathView {
                id: pathView
                anchors.fill: parent
                visible: root._isInfinite

                model: root._isInfinite ? stableModel : null
                delegate: carouselDelegate

                pathItemCount: Math.max(1, Math.min(stableModel.count, Math.ceil(width / carousel.slotWidth) + 4))
                cacheItemCount: 4

                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5
                highlightRangeMode: PathView.StrictlyEnforceRange

                highlightMoveDuration: carousel.initialFocusSet ? carousel.animationDuration : 0
                movementDirection: PathView.Shortest

                focus: root._isInfinite && overlay.visible

                Keys.onPressed: event => {
                    if (carousel.confirmingIndex >= 0) { event.accepted = true; return; }
                    if (event.key === Qt.Key_Escape) {
                        root.close(); event.accepted = true;
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                        decrementCurrentIndex(); event.accepted = true;
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                        incrementCurrentIndex(); event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (currentItem) currentItem.pickWallpaper();
                        event.accepted = true;
                    }
                }

                onCountChanged: carousel.tryFocus()
                onCurrentIndexChanged: {
                    carousel.heldIndex = -1;
                    holdTimer.restart();
                }

                readonly property real _pathLen: pathItemCount * carousel.slotWidth
                readonly property real _pathX0:  (width - _pathLen) / 2
                path: Path {
                    startX: pathView._pathX0
                    startY: pathView.height / 2 - carousel.selectedHeight / 2
                    PathLine {
                        x: pathView._pathX0 + pathView._pathLen
                        y: pathView.height / 2 - carousel.selectedHeight / 2
                    }
                }
            }

            ListView {
                id: listView
                anchors.fill: parent
                visible: !root._isInfinite

                model: root._isInfinite ? null : stableModel
                delegate: carouselDelegate

                spacing: 0
                orientation: ListView.Horizontal
                clip: false
                cacheBuffer: carousel.slotWidth * 6

                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: (width / 2) - (carousel.slotWidth / 2)
                preferredHighlightEnd:   (width / 2) + (carousel.slotWidth / 2)

                header: Item { width: Math.max(0, (listView.width / 2) - (carousel.slotWidth / 2)) }
                footer: Item { width: Math.max(0, (listView.width / 2) - (carousel.slotWidth / 2)) }

                highlightMoveDuration: carousel.initialFocusSet ? carousel.animationDuration : 0

                focus: !root._isInfinite && overlay.visible

                Keys.onPressed: event => {
                    if (carousel.confirmingIndex >= 0) { event.accepted = true; return; }
                    if (event.key === Qt.Key_Escape) {
                        root.close(); event.accepted = true;
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                        if (currentIndex > 0) decrementCurrentIndex();
                        else if (root._wrapsIndex) currentIndex = count - 1;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                        if (currentIndex < count - 1) incrementCurrentIndex();
                        else if (root._wrapsIndex) currentIndex = 0;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Home) {
                        currentIndex = 0; event.accepted = true;
                    } else if (event.key === Qt.Key_End) {
                        currentIndex = count - 1; event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (currentItem) currentItem.pickWallpaper();
                        event.accepted = true;
                    }
                }

                onCountChanged: carousel.tryFocus()
                onCurrentIndexChanged: {
                    carousel.heldIndex = -1;
                    holdTimer.restart();
                }
            }
        }

        Column {
            anchors.centerIn: wallpaperPanel
            spacing: 12
            z: 100
            visible: overlay.visible && (root.cfg.wallpaperDirectory ?? "").trim() && folderModel.status !== FolderListModel.Ready

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "directory not found"
                color: Theme.moduleLabel
                font {
                    family: ShellConfig.typography.monoFamily
                    pixelSize: ShellConfig.wallpaperPicker.titleSize
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "the configured directory '" + (root.cfg.wallpaperDirectory ?? "") + "' does not exist.\ncheck the wallpaper carousel path."
                color: Theme.textMuted
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.4
                font {
                    family: ShellConfig.typography.monoFamily
                    pixelSize: ShellConfig.wallpaperPicker.detailSize
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "press escape to close"
                color: Theme.textMuted
                font {
                    family: ShellConfig.typography.monoFamily
                    pixelSize: ShellConfig.wallpaperPicker.detailSize
                }
            }
        }

        Column {
            anchors.centerIn: wallpaperPanel
            spacing: 12
            z: 100
            visible: overlay.visible && folderModel.status === FolderListModel.Ready && folderModel.count === 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.hasWallpaperConfigured ? "no images found in wallpaper folder" : "no wallpaper configured"
                color: Theme.moduleLabel
                font {
                    family: ShellConfig.typography.monoFamily
                    pixelSize: ShellConfig.wallpaperPicker.titleSize
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.hasWallpaperConfigured
                    ? "the folder '" + root.wallpaperFolder + "' is empty.\nadd images or choose a different wallpaper directory."
                    : root.shellSettingsHint
                color: Theme.textMuted
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.4
                font {
                    family: ShellConfig.typography.monoFamily
                    pixelSize: ShellConfig.wallpaperPicker.detailSize
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "press escape to close"
                color: Theme.textMuted
                font {
                    family: ShellConfig.typography.monoFamily
                    pixelSize: ShellConfig.wallpaperPicker.detailSize
                }
            }
        }
    }

    PanelWindow {
        id: cacheWindow
        visible: true
        color: "transparent"
        implicitWidth: 1; implicitHeight: 1

        WlrLayershell.namespace: root.wlrNamespace + ":precache"
        WlrLayershell.layer: WlrLayershell.Background
        WlrLayershell.exclusiveZone: 0
        anchors { top: true; left: true }

        Item {
            width: 1; height: 1
            clip: true

            Repeater {
                model: root._cacheEntries
                Image {
                    width: carousel.selectedWidth; height: carousel.selectedHeight
                    asynchronous: true
                    source: modelData
                    sourceSize: Qt.size(
                        carousel.selectedWidth + (carousel.selectedHeight * Math.abs(carousel.skewFactor)) + 50,
                        carousel.selectedHeight)
                    fillMode: Image.PreserveAspectCrop
                }
            }

            Repeater {
                model: root.extraDirectories
                Item {
                    property string dir: modelData
                    FolderListModel {
                        id: extraFolderModel
                        folder: "file://" + dir
                        nameFilters: root._nameFilters
                        showDirs: false
                        sortField: FolderListModel.Name
                        onStatusChanged: {
                            if (status === FolderListModel.Ready)
                                root._folderCache[dir] = root._readFolderModel(extraFolderModel);
                        }
                        onCountChanged: {
                            if (status === FolderListModel.Ready)
                                root._folderCache[dir] = root._readFolderModel(extraFolderModel);
                        }
                    }
                    Repeater {
                        model: extraFolderModel
                        Image {
                            width: carousel.selectedWidth; height: carousel.selectedHeight
                            asynchronous: true
                            source: fileUrl
                            sourceSize: Qt.size(
                                carousel.selectedWidth + (carousel.selectedHeight * Math.abs(carousel.skewFactor)) + 50,
                                carousel.selectedHeight)
                            fillMode: Image.PreserveAspectCrop
                        }
                    }
                }
            }
        }
    }
}
