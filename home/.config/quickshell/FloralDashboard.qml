pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services

Scope {
    id: root

    property bool active: false
    property int tab: 0
    property date calendarDate: clock.date
    property string pendingRoute: ""
    readonly property int tabCount: 4
    readonly property var battery: UPower.displayDevice
    readonly property int batteryPercentage: battery.ready
        ? Math.round(battery.percentage * 100) : 0
    readonly property var activePlayer: Players.active

    signal closeConflictsRequested

    function open() {
        closeConflictsRequested();
        FloralSystemService.refresh();
        active = true;
        Qt.callLater(() => panel.forceActiveFocus());
    }

    function close() {
        active = false;
    }

    function toggle() {
        if (active)
            close();
        else
            open();
    }

    function openTab(index) {
        const requested = Number(index);
        if (isFinite(requested))
            tab = Math.max(0, Math.min(tabCount - 1, Math.round(requested)));
        open();
    }

    function route(routeName) {
        pendingRoute = routeName;
        close();
        routeDelay.restart();
    }

    function executeRoute() {
        const requested = pendingRoute;
        pendingRoute = "";
        if (requested === "wallpapers") {
            Quickshell.execDetached(["qs", "ipc", "call",
                "wallpaperCarousel", "toggle"]);
        } else if (requested === "settings") {
            Quickshell.execDetached(["qs", "ipc", "call",
                "settings", "open"]);
        } else if (requested === "notifications") {
            Quickshell.execDetached(["qs", "ipc", "call",
                "notificationPanel", "open"]);
        } else if (requested === "power") {
            Quickshell.execDetached(["qs", "ipc", "call",
                "powerMenu", "open"]);
        } else if (requested === "lock") {
            FloralSystemService.lockSession();
        } else if (requested === "suspend") {
            FloralSystemService.suspendSession();
        } else if (requested === "screenshot") {
            Quickshell.execDetached([
                `${Quickshell.env("HOME")}/.local/bin/quickshell-screenshot`
            ]);
        }
    }

    function shiftMonth(delta) {
        calendarDate = new Date(calendarDate.getFullYear(),
            calendarDate.getMonth() + delta, 1);
    }

    function resetCalendar() {
        calendarDate = clock.date;
    }

    function formatDuration(seconds) {
        if (!isFinite(seconds) || seconds <= 0)
            return "";
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        if (hours > 0)
            return `${hours}h ${minutes}m remaining`;
        return `${minutes}m remaining`;
    }

    component SectionLabel: Text {
        color: Theme.moduleLabel
        renderType: Text.NativeRendering
        font {
            family: ShellConfig.typography.monoFamily
            styleName: ShellConfig.typography.fineStyle
            pixelSize: 12
            weight: Font.DemiBold
            letterSpacing: 0.7
        }
    }

    component CalendarButton: Rectangle {
        id: calendarButton

        required property int direction
        signal clicked

        implicitWidth: 36
        implicitHeight: 36
        radius: Math.max(8, FloralSettings.popupRadius * 0.75)
        color: calendarPointer.containsMouse
            ? FloralSettings.elevatedColor
            : FloralSettings.withAlpha(Theme.panelRaised, 0.48)
        border.width: 1
        border.color: calendarPointer.containsMouse
            ? FloralSettings.accentColor : Theme.frameBorderFaint
        scale: calendarPointer.pressed ? 0.92 : 1

        Canvas {
            anchors.centerIn: parent
            width: 12
            height: 16
            antialiasing: true
            property color markColor: calendarPointer.containsMouse
                ? FloralSettings.accentColor : Theme.moduleValue
            onMarkColorChanged: requestPaint()
            onPaint: {
                const context = getContext("2d");
                context.reset();
                context.strokeStyle = markColor;
                context.lineWidth = 2;
                context.lineCap = "round";
                context.lineJoin = "round";
                context.beginPath();
                if (calendarButton.direction < 0) {
                    context.moveTo(width * 0.72, 2);
                    context.lineTo(width * 0.30, height / 2);
                    context.lineTo(width * 0.72, height - 2);
                } else {
                    context.moveTo(width * 0.28, 2);
                    context.lineTo(width * 0.70, height / 2);
                    context.lineTo(width * 0.28, height - 2);
                }
                context.stroke();
            }
        }

        MouseArea {
            id: calendarPointer

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: calendarButton.clicked()
        }

        Behavior on scale {
            NumberAnimation {
                duration: FloralSettings.duration(90)
                easing.type: Easing.OutCubic
            }
        }
    }

    component ControlSliderRow: Rectangle {
        id: controlRow

        required property string title
        required property string valueText
        required property real value
        signal moved(real value)

        implicitHeight: 76
        radius: Math.max(10, FloralSettings.popupRadius)
        color: FloralSettings.withAlpha(Theme.panelRaised, 0.50)
        border.width: 1
        border.color: Theme.frameBorderFaint

        Text {
            anchors {
                left: parent.left
                leftMargin: 16
                top: parent.top
                topMargin: 11
            }
            text: controlRow.title
            color: Theme.moduleValue
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                styleName: ShellConfig.typography.fineStyle
                pixelSize: 13
                weight: Font.DemiBold
            }
        }

        Text {
            anchors {
                right: parent.right
                rightMargin: 16
                top: parent.top
                topMargin: 11
            }
            text: controlRow.valueText
            color: FloralSettings.accentColor
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                styleName: ShellConfig.typography.fineStyle
                pixelSize: 12
                weight: Font.DemiBold
            }
        }

        FloralSlider {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 16
                rightMargin: 16
                bottomMargin: 4
            }
            from: 0
            to: 1
            stepSize: 0.01
            value: controlRow.value
            onMoved: value => controlRow.moved(value)
        }
    }

    IpcHandler {
        target: "dashboard"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function openTab(index: int): void { root.openTab(index); }
        function close(): void { root.close(); }
        function isOpen(): bool { return root.active; }
    }

    SystemClock {
        id: clock

        enabled: root.active
        precision: SystemClock.Seconds
    }

    FloralDashboardStats {
        id: stats

        active: root.active && root.tab === 1
    }

    Timer {
        id: routeDelay

        interval: FloralSettings.duration(
            ShellConfig.dashboard.animationMs + 35)
        onTriggered: root.executeRoute()
    }

    onTabChanged: {
        if (!root.active)
            return;
        pageLoader.opacity = 0;
        pageLoader.x = 12;
        pageEntrance.restart();
    }

    PanelWindow {
        id: overlay

        visible: root.active || panel.opacity > 0
        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: root.active
            ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        mask: Region {
            width: root.active ? overlay.width : 0
            height: root.active ? overlay.height : 0
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: root.active ? ShellConfig.dashboard.dimOpacity : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: FloralSettings.duration(
                        ShellConfig.dashboard.animationMs - 40)
                    easing.type: Easing.InOutCubic
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.active
            onClicked: root.close()
        }

        FloralSurface {
            id: panel

            anchors.horizontalCenter: parent.horizontalCenter
            y: root.active
                ? Math.min(ShellConfig.dashboard.topMargin,
                    Math.max(20, (overlay.height - height) / 2))
                : Math.min(ShellConfig.dashboard.topMargin,
                    Math.max(20, (overlay.height - height) / 2)) - 24
            width: Math.min(ShellConfig.dashboard.width,
                overlay.width - ShellConfig.dashboard.screenMargin * 2)
            height: Math.min(ShellConfig.dashboard.height,
                overlay.height - ShellConfig.dashboard.topMargin
                    - ShellConfig.dashboard.screenMargin)
            radius: Math.max(18, FloralSettings.popupRadius + 7)
            fillColor: Theme.panel
            borderColor: FloralSettings.accentColor
            innerBorderColor: Theme.frameBorderFaint
            borderWidth: 2
            innerInset: Math.max(6, ShellConfig.visuals.innerInset)
            elevated: FloralSettings.shadows
            ornamented: false
            opacity: root.active ? 1 : 0
            scale: root.active ? 1 : 0.975
            visible: opacity > 0
            focus: root.active

            Keys.onEscapePressed: root.close()

            MouseArea {
                anchors.fill: parent
                onClicked: event => event.accepted = true
                z: -0.5
            }

            ClippingRectangle {
                anchors.fill: parent
                radius: panel.radius
                color: "transparent"
                z: -0.25

                FloralCorner {
                    anchors {
                        left: parent.left
                        top: parent.top
                    }
                    width: ShellConfig.dashboard.ornamentSize
                    height: width
                    location: FloralCorner.TopLeft
                    strength: 0.10
                }

                FloralCorner {
                    anchors {
                        right: parent.right
                        bottom: parent.bottom
                    }
                    width: ShellConfig.dashboard.ornamentSize
                    height: width
                    location: FloralCorner.BottomRight
                    strength: 0.10
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 8
                    rightMargin: 8
                    topMargin: 8
                }
                height: ShellConfig.dashboard.headerHeight - 8
                radius: Math.max(12, panel.radius - 8)
                color: FloralSettings.withAlpha(Theme.panelHighlight, 0.24)
                border.width: 1
                border.color: Theme.frameBorderFaint

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 22
                        top: parent.top
                        topMargin: 11
                    }
                    text: "dashboard"
                    color: Theme.moduleValue
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        styleName: ShellConfig.typography.fineStyle
                        pixelSize: 23
                        weight: Font.DemiBold
                    }
                }

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 23
                        bottom: parent.bottom
                        bottomMargin: 9
                    }
                    text: Qt.formatDateTime(clock.date,
                        "dddd  ·  d MMMM yyyy").toLowerCase()
                    color: Theme.textMuted
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        styleName: ShellConfig.typography.fineStyle
                        pixelSize: 11
                    }
                }

                Rectangle {
                    anchors {
                        right: parent.right
                        rightMargin: 15
                        verticalCenter: parent.verticalCenter
                    }
                    width: 40
                    height: 40
                    radius: Math.max(10, FloralSettings.popupRadius)
                    color: closePointer.containsMouse
                        ? FloralSettings.withAlpha(Theme.statusDanger, 0.18)
                        : FloralSettings.withAlpha(Theme.panelRaised, 0.62)
                    border.width: 1
                    border.color: closePointer.containsMouse
                        ? Theme.statusDanger : Theme.frameBorderFaint

                    FloralGlyph {
                        anchors.centerIn: parent
                        width: 17
                        height: 17
                        kind: "close"
                        color: closePointer.containsMouse
                            ? Theme.statusDanger : Theme.moduleValue
                    }

                    MouseArea {
                        id: closePointer

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            Rectangle {
                id: navigation

                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: ShellConfig.dashboard.panelPadding
                    topMargin: ShellConfig.dashboard.headerHeight
                        + ShellConfig.dashboard.gap
                    bottomMargin: ShellConfig.dashboard.panelPadding
                }
                width: ShellConfig.dashboard.navigationWidth
                radius: Math.max(12, panel.radius - 7)
                color: FloralSettings.withAlpha(Theme.panelRaised, 0.34)
                border.width: 1
                border.color: Theme.frameBorderFaint

                Column {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 10
                    }
                    spacing: 7

                    Repeater {
                        model: [
                            { label: "overview", icon: "overview" },
                            { label: "performance", icon: "performance" },
                            { label: "media", icon: "media" },
                            { label: "controls", icon: "controls" }
                        ]

                        FloralDashboardAction {
                            required property int index
                            required property var modelData
                            width: parent.width
                            compact: true
                            title: modelData.label
                            glyphKind: modelData.icon
                            selected: root.tab === index
                            onClicked: root.tab = index
                        }
                    }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: identityBlock.top
                        leftMargin: 14
                        rightMargin: 14
                        bottomMargin: 13
                    }
                    height: 1
                    color: Theme.frameBorderFaint

                    Rectangle {
                        anchors.centerIn: parent
                        width: 5
                        height: 5
                        radius: 2.5
                        color: Theme.panel
                        border.width: 1
                        border.color: Theme.frameBorderSoft
                    }
                }

                Column {
                    id: identityBlock

                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: 16
                        rightMargin: 16
                        bottomMargin: 16
                    }
                    spacing: 4

                    Text {
                        width: parent.width
                        text: FloralSystemService.user.toLowerCase()
                        color: Theme.moduleValue
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: 13
                            weight: Font.DemiBold
                        }
                    }

                    Text {
                        width: parent.width
                        text: FloralSystemService.hostname.toLowerCase()
                        color: Theme.textMuted
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: 10
                        }
                    }
                }
            }

            Loader {
                id: pageLoader

                anchors {
                    left: navigation.right
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: ShellConfig.dashboard.gap
                    rightMargin: ShellConfig.dashboard.panelPadding
                    topMargin: ShellConfig.dashboard.headerHeight
                        + ShellConfig.dashboard.gap
                    bottomMargin: ShellConfig.dashboard.panelPadding
                }
                active: panel.visible
                sourceComponent: root.tab === 0
                    ? overviewPage : root.tab === 1
                        ? performancePage : root.tab === 2
                            ? mediaPage : controlsPage
                opacity: 1

                onLoaded: {
                    opacity = 0;
                    x = 12;
                    pageEntrance.restart();
                }
            }

            ParallelAnimation {
                id: pageEntrance

                NumberAnimation {
                    target: pageLoader
                    property: "opacity"
                    to: 1
                    duration: FloralSettings.duration(190)
                    easing.type: Easing.InOutCubic
                }
                NumberAnimation {
                    target: pageLoader
                    property: "x"
                    to: 0
                    duration: FloralSettings.duration(230)
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on y {
                NumberAnimation {
                    duration: FloralSettings.duration(
                        ShellConfig.dashboard.animationMs)
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: FloralSettings.duration(
                        ShellConfig.dashboard.animationMs - 25)
                    easing.type: Easing.InOutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: FloralSettings.duration(
                        ShellConfig.dashboard.animationMs)
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Component {
        id: overviewPage

        Item {
            id: overview

            readonly property real gap: ShellConfig.dashboard.gap
            readonly property real leftWidth: width * 0.255
            readonly property real rightWidth: width * 0.285

            Rectangle {
                id: profileCard

                anchors {
                    left: parent.left
                    top: parent.top
                }
                width: overview.leftWidth
                height: parent.height * 0.48
                radius: Math.max(13, FloralSettings.popupRadius + 2)
                color: FloralSettings.withAlpha(Theme.panelRaised, 0.50)
                border.width: 1
                border.color: Theme.frameBorderFaint
                clip: true

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                    height: 64
                    color: FloralSettings.withAlpha(
                        FloralSettings.accentColor, 0.10)
                }

                Rectangle {
                    id: faceFrame

                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        topMargin: 32
                    }
                    width: Math.min(116, parent.width * 0.48)
                    height: width
                    radius: Math.max(16, FloralSettings.popupRadius + 8)
                    color: Theme.panelHighlight
                    border.width: 2
                    border.color: FloralSettings.accentColor
                    clip: true

                    FloralDashboardGlyph {
                        anchors.centerIn: parent
                        width: parent.width * 0.42
                        height: width
                        kind: "user"
                        color: Theme.moduleLabel
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 4
                        source: `file://${Quickshell.env("HOME")}/.face`
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize: Qt.size(width, height)
                        opacity: status === Image.Ready ? 1 : 0
                    }
                }

                Text {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: faceFrame.bottom
                        topMargin: 14
                    }
                    width: parent.width - 28
                    text: FloralSystemService.user.toLowerCase()
                    color: Theme.moduleValue
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        styleName: ShellConfig.typography.fineStyle
                        pixelSize: 19
                        weight: Font.DemiBold
                    }
                }

                Text {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: 18
                    }
                    width: parent.width - 28
                    text: FloralSystemService.device.toLowerCase()
                        || FloralSystemService.hostname.toLowerCase()
                    color: Theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        styleName: ShellConfig.typography.fineStyle
                        pixelSize: 10
                    }
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: profileCard.right
                    top: profileCard.bottom
                    bottom: parent.bottom
                    topMargin: overview.gap
                }
                radius: Math.max(13, FloralSettings.popupRadius + 2)
                color: FloralSettings.withAlpha(Theme.panelRaised, 0.50)
                border.width: 1
                border.color: Theme.frameBorderFaint

                Text {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        topMargin: 24
                    }
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Theme.moduleValue
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        styleName: ShellConfig.typography.fineStyle
                        pixelSize: 44
                        weight: Font.DemiBold
                    }
                }

                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 22
                    width: parent.width - 30
                    text: Qt.formatDateTime(clock.date,
                        "dddd\nd MMMM").toLowerCase()
                    color: Theme.moduleLabel
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.22
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        styleName: ShellConfig.typography.fineStyle
                        pixelSize: 15
                        weight: Font.DemiBold
                    }
                }

                Text {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: 18
                    }
                    width: parent.width - 30
                    text: FloralSystemService.uptime.length
                        ? `${FloralSystemService.uptime} up` : ""
                    color: Theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        styleName: ShellConfig.typography.fineStyle
                        pixelSize: 10
                    }
                }
            }

            Rectangle {
                id: calendarCard

                anchors {
                    left: profileCard.right
                    right: quickColumn.left
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: overview.gap
                    rightMargin: overview.gap
                }
                radius: Math.max(13, FloralSettings.popupRadius + 2)
                color: FloralSettings.withAlpha(Theme.panelRaised, 0.50)
                border.width: 1
                border.color: Theme.frameBorderFaint

                Row {
                    id: calendarHeader

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        leftMargin: 17
                        rightMargin: 17
                        topMargin: 16
                    }
                    height: 40

                    CalendarButton {
                        direction: -1
                        onClicked: root.shiftMonth(-1)
                    }

                    Item {
                        width: calendarHeader.width - 72
                        height: 36

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 12
                            text: Qt.formatDate(root.calendarDate,
                                "MMMM yyyy").toLowerCase()
                            color: Theme.moduleLabel
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            renderType: Text.NativeRendering
                            font {
                                family: ShellConfig.typography.monoFamily
                                styleName: ShellConfig.typography.fineStyle
                                pixelSize: 14
                                weight: Font.DemiBold
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.resetCalendar()
                        }
                    }

                    CalendarButton {
                        direction: 1
                        onClicked: root.shiftMonth(1)
                    }
                }

                Rectangle {
                    id: calendarDivider

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: calendarHeader.bottom
                        leftMargin: 17
                        rightMargin: 17
                        topMargin: 7
                    }
                    height: 1
                    color: Theme.frameBorderFaint
                }

                Controls.DayOfWeekRow {
                    id: weekDays

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: calendarDivider.bottom
                        leftMargin: 13
                        rightMargin: 13
                        topMargin: 10
                    }
                    height: 26
                    locale: monthGrid.locale

                    delegate: Text {
                        required property var model
                        text: model.shortName.toLowerCase()
                        color: model.day === 0 || model.day === 6
                            ? Theme.accentSecondary : Theme.textMuted
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: 11
                            weight: Font.DemiBold
                        }
                    }
                }

                Controls.MonthGrid {
                    id: monthGrid

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: weekDays.bottom
                        bottom: parent.bottom
                        leftMargin: 13
                        rightMargin: 13
                        topMargin: 5
                        bottomMargin: 16
                    }
                    month: root.calendarDate.getMonth()
                    year: root.calendarDate.getFullYear()
                    locale: Qt.locale()
                    spacing: 2

                    delegate: Item {
                        id: dayCell

                        required property var model
                        implicitWidth: monthGrid.width / 7
                        implicitHeight: monthGrid.height / 6

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.min(parent.width - 6,
                                parent.height - 6)
                            height: width
                            radius: Math.max(7,
                                FloralSettings.popupRadius * 0.75)
                            color: dayCell.model.today
                                ? FloralSettings.withAlpha(
                                    FloralSettings.accentColor, 0.21)
                                : "transparent"
                            border.width: dayCell.model.today ? 1.5 : 0
                            border.color: FloralSettings.accentColor
                        }

                        Text {
                            anchors.centerIn: parent
                            text: dayCell.model.day
                            color: dayCell.model.today
                                ? Theme.moduleLabel
                                : dayCell.model.date.getDay() === 0
                                        || dayCell.model.date.getDay() === 6
                                    ? Theme.accentSecondary
                                    : Theme.moduleValue
                            opacity: dayCell.model.month === monthGrid.month
                                ? 1 : 0.28
                            renderType: Text.NativeRendering
                            font {
                                family: ShellConfig.typography.monoFamily
                                styleName: ShellConfig.typography.fineStyle
                                pixelSize: 12
                                weight: dayCell.model.today
                                    ? Font.DemiBold : Font.Normal
                            }
                        }
                    }
                }
            }

            Column {
                id: quickColumn

                anchors {
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                }
                width: overview.rightWidth
                spacing: overview.gap

                Rectangle {
                    id: nowPlayingCard

                    width: parent.width
                    height: Math.max(176, overview.height * 0.36)
                    radius: Math.max(13, FloralSettings.popupRadius + 2)
                    color: FloralSettings.withAlpha(Theme.panelRaised, 0.50)
                    border.width: 1
                    border.color: nowPlayingPointer.containsMouse
                        ? FloralSettings.accentColor : Theme.frameBorderFaint
                    clip: true

                    Rectangle {
                        id: compactArtwork

                        anchors {
                            left: parent.left
                            leftMargin: 13
                            verticalCenter: parent.verticalCenter
                        }
                        width: Math.min(96, parent.width * 0.38)
                        height: width
                        radius: Math.max(10, FloralSettings.popupRadius)
                        color: Theme.panelHighlight
                        border.width: 1
                        border.color: Theme.frameBorderFaint
                        clip: true

                        FloralDashboardGlyph {
                            anchors.centerIn: parent
                            width: parent.width * 0.38
                            height: width
                            kind: "media"
                            color: Theme.moduleLabel
                        }

                        Image {
                            anchors.fill: parent
                            source: Players.getArtUrl(root.activePlayer)
                            asynchronous: true
                            cache: true
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(width, height)
                            opacity: status === Image.Ready ? 1 : 0
                        }
                    }

                    Text {
                        anchors {
                            left: compactArtwork.right
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 13
                            rightMargin: 13
                            verticalCenterOffset: -19
                        }
                        text: root.activePlayer
                            ? (root.activePlayer.trackTitle || "nothing playing")
                            : "nothing playing"
                        color: Theme.moduleValue
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: 14
                            weight: Font.DemiBold
                        }
                    }

                    Text {
                        anchors {
                            left: compactArtwork.right
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 13
                            rightMargin: 13
                            verticalCenterOffset: 18
                        }
                        text: root.activePlayer
                            ? (root.activePlayer.trackArtist
                                || root.activePlayer.identity || "")
                            : "open the media page"
                        color: Theme.textMuted
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: 10
                        }
                    }

                    MouseArea {
                        id: nowPlayingPointer

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tab = 2
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 112
                    radius: Math.max(13, FloralSettings.popupRadius + 2)
                    color: FloralSettings.withAlpha(Theme.panelRaised, 0.50)
                    border.width: 1
                    border.color: Theme.frameBorderFaint

                    SectionLabel {
                        anchors {
                            left: parent.left
                            leftMargin: 16
                            top: parent.top
                            topMargin: 14
                        }
                        text: "battery"
                    }

                    Text {
                        anchors {
                            right: parent.right
                            rightMargin: 16
                            top: parent.top
                            topMargin: 10
                        }
                        text: root.battery.ready && root.battery.isPresent
                            ? `${root.batteryPercentage}%` : "not present"
                        color: Theme.moduleValue
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: 18
                            weight: Font.DemiBold
                        }
                    }

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 16
                            top: parent.top
                            topMargin: 43
                        }
                        width: parent.width - 32
                        text: root.formatDuration(root.battery.timeToFull > 0
                            ? root.battery.timeToFull
                            : root.battery.timeToEmpty)
                        color: Theme.textMuted
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: 9
                        }
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            leftMargin: 16
                            rightMargin: 20
                            bottomMargin: 19
                        }
                        height: 18
                        radius: 7
                        color: Theme.panelHighlight
                        border.width: 1.5
                        border.color: root.batteryPercentage < 10
                            ? Theme.statusDanger : FloralSettings.accentColor
                        clip: true

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                                margins: 3
                            }
                            width: Math.max(0, (parent.width - 6)
                                * root.batteryPercentage / 100)
                            radius: 4
                            color: root.batteryPercentage < 10
                                ? Theme.statusDanger
                                : FloralSettings.accentColor

                            Behavior on width {
                                NumberAnimation {
                                    duration: FloralSettings.duration(220)
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Rectangle {
                            anchors {
                                left: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            width: 4
                            height: 8
                            radius: 2
                            color: parent.border.color
                        }
                    }
                }

                Column {
                    width: parent.width
                    height: parent.height - nowPlayingCard.height - 112
                        - parent.spacing * 2
                    spacing: 8

                    FloralDashboardAction {
                        width: parent.width
                        height: (parent.height - parent.spacing * 3) / 4
                        title: "wallpapers"
                        detail: "choose another image"
                        glyphSource: 1
                        glyphKind: "wallpaper"
                        onClicked: root.route("wallpapers")
                    }

                    FloralDashboardAction {
                        width: parent.width
                        height: (parent.height - parent.spacing * 3) / 4
                        title: "settings"
                        detail: "shell and system"
                        glyphSource: 1
                        glyphKind: "settings"
                        onClicked: root.route("settings")
                    }

                    FloralDashboardAction {
                        width: parent.width
                        height: (parent.height - parent.spacing * 3) / 4
                        title: "notices"
                        detail: `${Notifs.notClosed.length} saved`
                        glyphKind: "notifications"
                        onClicked: root.route("notifications")
                    }

                    FloralDashboardAction {
                        width: parent.width
                        height: (parent.height - parent.spacing * 3) / 4
                        title: "lock"
                        detail: "secure this session"
                        glyphSource: 2
                        glyphKind: "lock"
                        onClicked: root.route("lock")
                    }
                }
            }
        }
    }

    Component {
        id: performancePage

        Item {
            id: performance

            readonly property real gap: ShellConfig.dashboard.gap
            readonly property real footerHeight: 68
            readonly property real metricHeight:
                (height - footerHeight - gap * 2) / 2

            FloralDashboardMetric {
                anchors {
                    left: parent.left
                    top: parent.top
                }
                width: (parent.width - performance.gap) / 2
                height: performance.metricHeight
                title: "processor"
                value: `${Math.round(stats.cpuUsage * 100)}%`
                detail: "live total usage"
                ratio: stats.cpuUsage
                history: stats.cpuHistory
                accent: Theme.accentPrimary
            }

            FloralDashboardMetric {
                anchors {
                    right: parent.right
                    top: parent.top
                }
                width: (parent.width - performance.gap) / 2
                height: performance.metricHeight
                title: "memory"
                value: `${Math.round(stats.memoryUsage * 100)}%`
                detail: stats.memoryDetail
                ratio: stats.memoryUsage
                history: stats.memoryHistory
                accent: Theme.accentSecondary
            }

            FloralDashboardMetric {
                anchors {
                    left: parent.left
                    bottom: footer.top
                    bottomMargin: performance.gap
                }
                width: (parent.width - performance.gap) / 2
                height: performance.metricHeight
                title: "storage"
                value: `${Math.round(stats.diskUsage * 100)}%`
                detail: stats.diskDetail
                ratio: stats.diskUsage
                history: stats.diskHistory
                accent: Theme.accentTertiary
            }

            FloralDashboardMetric {
                anchors {
                    right: parent.right
                    bottom: footer.top
                    bottomMargin: performance.gap
                }
                width: (parent.width - performance.gap) / 2
                height: performance.metricHeight
                title: "network"
                value: stats.formatBytes(stats.downloadSpeed)
                detail: `download ${stats.formatBytes(stats.downloadSpeed)}, upload ${stats.formatBytes(stats.uploadSpeed)}`
                ratio: Math.min(1,
                    (stats.downloadSpeed + stats.uploadSpeed) / 20971520)
                history: stats.downloadHistory
                secondHistory: stats.uploadHistory
                accent: Theme.accentPrimary
                secondAccent: Theme.accentSecondary
            }

            Rectangle {
                id: footer

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: performance.footerHeight
                radius: Math.max(11, FloralSettings.popupRadius + 1)
                color: FloralSettings.withAlpha(Theme.panelRaised, 0.50)
                border.width: 1
                border.color: Theme.frameBorderFaint

                Row {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 18
                        rightMargin: 18
                    }
                    height: 34

                    Repeater {
                        model: [
                            { label: "host", value: FloralSystemService.hostname },
                            { label: "kernel", value: FloralSystemService.kernel },
                            { label: "uptime", value: FloralSystemService.uptime }
                        ]

                        Item {
                            required property var modelData
                            width: parent.width / 3
                            height: parent.height

                            Text {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    leftMargin: 7
                                    rightMargin: 7
                                }
                                text: modelData.label
                                color: Theme.moduleLabel
                                horizontalAlignment: Text.AlignHCenter
                                renderType: Text.NativeRendering
                                font {
                                    family: ShellConfig.typography.monoFamily
                                    styleName: ShellConfig.typography.fineStyle
                                    pixelSize: 10
                                    weight: Font.DemiBold
                                }
                            }

                            Text {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                    leftMargin: 7
                                    rightMargin: 7
                                }
                                text: String(modelData.value || "").toLowerCase()
                                color: Theme.textMuted
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                renderType: Text.NativeRendering
                                font {
                                    family: ShellConfig.typography.monoFamily
                                    styleName: ShellConfig.typography.fineStyle
                                    pixelSize: 10
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: mediaPage

        FloralDashboardMedia {
            active: root.active && root.tab === 2
        }
    }

    Component {
        id: controlsPage

        Item {
            id: controls

            readonly property real gap: ShellConfig.dashboard.gap
            readonly property real leftWidth: width * 0.49

            Column {
                id: controlColumn

                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                width: controls.leftWidth
                spacing: 10

                SectionLabel { text: "quick controls" }

                Grid {
                    width: parent.width
                    columns: 2
                    columnSpacing: 9
                    rowSpacing: 9

                    FloralDashboardAction {
                        width: (controlColumn.width - 9) / 2
                        title: "do not disturb"
                        detail: Notifs.dnd ? "popups are paused" : "popups are allowed"
                        glyphKind: "notifications"
                        selected: Notifs.dnd
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }

                    FloralDashboardAction {
                        width: (controlColumn.width - 9) / 2
                        title: "microphone"
                        detail: FloralSystemService.inputMuted
                            ? "input is muted" : "input is live"
                        glyphSource: 2
                        glyphKind: "mic"
                        selected: FloralSystemService.inputMuted
                        available: !!FloralSystemService.audioSource
                        onClicked: FloralSystemService.setInputMuted(
                            !FloralSystemService.inputMuted)
                    }

                    FloralDashboardAction {
                        width: (controlColumn.width - 9) / 2
                        title: "stay awake"
                        detail: IdleInhibitorService.enabled
                            ? "idle lock is paused" : "idle lock is active"
                        glyphKind: "awake"
                        selected: IdleInhibitorService.enabled
                        onClicked: IdleInhibitorService.enabled = !IdleInhibitorService.enabled
                    }

                    FloralDashboardAction {
                        width: (controlColumn.width - 9) / 2
                        title: "wi-fi"
                        detail: FloralSystemService.networkConnected
                            ? FloralSystemService.activeConnection
                            : FloralSystemService.wifiEnabled
                                ? "not connected" : "radio is off"
                        glyphSource: 2
                        glyphKind: "network"
                        selected: FloralSystemService.wifiEnabled
                        available: !FloralSystemService.networkBusy
                        onClicked: FloralSystemService.setWifi(
                            !FloralSystemService.wifiEnabled)
                    }
                }

                SectionLabel {
                    text: "levels"
                    topPadding: 6
                }

                ControlSliderRow {
                    width: parent.width
                    title: FloralSystemService.outputMuted
                        ? "output muted" : "output volume"
                    value: FloralSystemService.outputVolume
                    valueText: `${Math.round(value * 100)}%`
                    onMoved: value => FloralSystemService.setOutputVolume(value)
                }

                ControlSliderRow {
                    width: parent.width
                    title: "display brightness"
                    value: FloralSystemService.brightness
                    valueText: `${Math.round(value * 100)}%`
                    onMoved: value => FloralSystemService.setBrightness(value)
                }
            }

            Column {
                anchors {
                    left: controlColumn.right
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: controls.gap
                }
                spacing: 10

                SectionLabel { text: "utilities" }

                Grid {
                    width: parent.width
                    columns: 2
                    columnSpacing: 9
                    rowSpacing: 9

                    FloralDashboardAction {
                        width: (parent.parent.width - 9) / 2
                        title: "screenshot"
                        detail: "select an area"
                        glyphKind: "screenshot"
                        onClicked: root.route("screenshot")
                    }

                    FloralDashboardAction {
                        width: (parent.parent.width - 9) / 2
                        title: Recorder.running ? "stop recording" : "screen record"
                        detail: Recorder.running
                            ? `${Math.floor(Recorder.elapsed / 60)}:${String(Math.floor(Recorder.elapsed % 60)).padStart(2, "0")}`
                            : "record with obs"
                        glyphKind: "record"
                        selected: Recorder.running
                        dangerous: Recorder.running
                        onClicked: Recorder.toggle()
                    }

                    FloralDashboardAction {
                        width: (parent.parent.width - 9) / 2
                        title: "wallpapers"
                        detail: "choose another image"
                        glyphSource: 1
                        glyphKind: "wallpaper"
                        onClicked: root.route("wallpapers")
                    }

                    FloralDashboardAction {
                        width: (parent.parent.width - 9) / 2
                        title: "notifications"
                        detail: `${Notifs.notClosed.length} saved`
                        glyphKind: "notifications"
                        onClicked: root.route("notifications")
                    }

                    FloralDashboardAction {
                        width: (parent.parent.width - 9) / 2
                        title: "settings"
                        detail: "shell and system"
                        glyphSource: 1
                        glyphKind: "settings"
                        onClicked: root.route("settings")
                    }

                    FloralDashboardAction {
                        width: (parent.parent.width - 9) / 2
                        title: "power menu"
                        detail: "session actions"
                        glyphSource: 2
                        glyphKind: "power"
                        onClicked: root.route("power")
                    }
                }

                SectionLabel {
                    text: "session"
                    topPadding: 6
                }

                Row {
                    width: parent.width
                    height: 66
                    spacing: 9

                    FloralDashboardAction {
                        width: (parent.width - 9) / 2
                        height: parent.height
                        title: "lock"
                        detail: "secure this session"
                        glyphSource: 2
                        glyphKind: "lock"
                        onClicked: root.route("lock")
                    }

                    FloralDashboardAction {
                        width: (parent.width - 9) / 2
                        height: parent.height
                        title: "suspend"
                        detail: "sleep this system"
                        glyphSource: 2
                        glyphKind: "suspend"
                        onClicked: root.route("suspend")
                    }
                }
            }
        }
    }
}
