pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland

Scope {
    id: root

    property int page: 0
    readonly property bool active: FloralSettings.settingsOpen
    readonly property int pageCount: 8

    signal closeConflictsRequested

    onPageChanged: {
        pageScroll.contentY = 0;
        pageLoader.opacity = 0;
        pageLoader.x = 14;
        pageEntrance.restart();
        if (page === 4 || page === 6)
            FloralSystemService.refresh();
    }

    function openPage(index) {
        const requested = Number(index);
        page = isFinite(requested)
            ? Math.max(0, Math.min(pageCount - 1, Math.round(requested)))
            : page;
        closeConflictsRequested();
        FloralSystemService.refresh();
        FloralSettings.settingsOpen = true;
    }

    function open() {
        openPage(page);
    }

    function close() {
        FloralSettings.settingsOpen = false;
    }

    function toggle() {
        if (active)
            close();
        else
            openPage(page);
    }

    function editFile(path) {
        Quickshell.execDetached([
            "foot",
            "--app-id=shell-settings-editor",
            "nvim",
            path
        ]);
    }

    component ToggleRow: Rectangle {
        id: toggleRow

        required property string title
        required property string detail
        required property bool checked
        property bool available: true
        signal toggled(bool checked)

        implicitHeight: 72
        opacity: available ? 1 : 0.45
        color: togglePointer.containsMouse && available
            ? FloralSettings.elevatedColor
            : FloralSettings.withAlpha(Theme.panelRaised, 0.46)
        radius: 13
        border.width: 1
        border.color: togglePointer.containsMouse
            ? Theme.frameBorderFaint
            : FloralSettings.withAlpha(Theme.frameBorderFaint, 0.52)

        Column {
            anchors {
                left: parent.left
                right: control.left
                leftMargin: 17
                rightMargin: 18
                verticalCenter: parent.verticalCenter
            }
            spacing: 4

            Text {
                width: parent.width
                text: toggleRow.title
                color: Theme.moduleValue
                elide: Text.ElideRight
                renderType: Text.NativeRendering
                font {
                    family: ShellConfig.typography.monoFamily
                    styleName: ShellConfig.typography.fineStyle
                    pixelSize: 15
                    weight: Font.DemiBold
                }
            }

            Text {
                width: parent.width
                text: toggleRow.detail
                color: Theme.textMuted
                elide: Text.ElideRight
                renderType: Text.NativeRendering
                font {
                    family: ShellConfig.typography.monoFamily
                    styleName: ShellConfig.typography.fineStyle
                    pixelSize: 12
                }
            }
        }

        FloralSwitch {
            id: control

            anchors {
                right: parent.right
                rightMargin: 16
                verticalCenter: parent.verticalCenter
            }
            checked: toggleRow.checked
            enabled: toggleRow.available
            onToggled: value => toggleRow.toggled(value)
            z: 2
        }

        MouseArea {
            id: togglePointer

            anchors.fill: parent
            enabled: toggleRow.available
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: toggleRow.toggled(!toggleRow.checked)
            z: 1
        }

        Behavior on color {
            ColorAnimation {
                duration: FloralSettings.duration(120)
                easing.type: Easing.InOutCubic
            }
        }
    }

    component SliderRow: Rectangle {
        id: sliderRow

        required property string title
        required property string detail
        required property real value
        required property real from
        required property real to
        property real stepSize: 1
        property string valueText: String(value)
        signal moved(real value)

        implicitHeight: 90
        color: FloralSettings.withAlpha(Theme.panelRaised, 0.46)
        radius: 13
        border.width: 1
        border.color: FloralSettings.withAlpha(Theme.frameBorderFaint, 0.52)

        Text {
            anchors {
                left: parent.left
                top: parent.top
                leftMargin: 17
                topMargin: 12
            }
            text: sliderRow.title
            color: Theme.moduleValue
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
                right: parent.right
                top: parent.top
                rightMargin: 17
                topMargin: 13
            }
            text: sliderRow.valueText
            color: FloralSettings.accentColor
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
                left: parent.left
                bottom: parent.bottom
                leftMargin: 17
                bottomMargin: 14
            }
            width: Math.min(155, parent.width * 0.34)
            text: sliderRow.detail
            color: Theme.textMuted
            elide: Text.ElideRight
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                styleName: ShellConfig.typography.fineStyle
                pixelSize: 11
            }
        }

        FloralSlider {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: Math.min(174, parent.width * 0.38)
                rightMargin: 18
                bottomMargin: 8
            }
            from: sliderRow.from
            to: sliderRow.to
            value: sliderRow.value
            stepSize: sliderRow.stepSize
            onMoved: value => sliderRow.moved(value)
        }
    }

    component ActionButton: Rectangle {
        id: actionButton

        required property string title
        required property string iconKind
        signal clicked

        implicitHeight: 48
        radius: 12
        color: actionPointer.pressed
            ? FloralSettings.withAlpha(FloralSettings.accentColor, 0.25)
            : actionPointer.containsMouse
                ? FloralSettings.elevatedColor
                : FloralSettings.withAlpha(Theme.panelRaised, 0.5)
        border.width: 1
        border.color: actionPointer.containsMouse
            ? FloralSettings.accentColor
            : Theme.frameBorderFaint
        scale: actionPointer.pressed ? 0.98 : 1

        FloralGlyph {
            anchors {
                left: parent.left
                leftMargin: 15
                verticalCenter: parent.verticalCenter
            }
            width: 20
            height: 20
            kind: actionButton.iconKind
            color: actionPointer.containsMouse
                ? FloralSettings.accentColor
                : Theme.moduleValue
        }

        Text {
            anchors {
                left: parent.left
                leftMargin: 45
                right: parent.right
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            text: actionButton.title
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

        MouseArea {
            id: actionPointer

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: actionButton.clicked()
        }

        Behavior on color {
            ColorAnimation {
                duration: FloralSettings.duration(110)
                easing.type: Easing.InOutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: FloralSettings.duration(90)
                easing.type: Easing.OutCubic
            }
        }
    }

    component SectionLabel: Text {
        color: Theme.moduleLabel
        renderType: Text.NativeRendering
        font {
            family: ShellConfig.typography.monoFamily
            styleName: ShellConfig.typography.fineStyle
            pixelSize: 12
            weight: Font.DemiBold
            letterSpacing: 0.6
        }
    }

    component MiniButton: Rectangle {
        id: miniButton

        required property string title
        property string iconKind: ""
        property bool selected: false
        property bool available: true
        signal clicked

        implicitHeight: 44
        radius: 11
        opacity: available ? 1 : 0.4
        color: selected
            ? FloralSettings.withAlpha(FloralSettings.accentColor, 0.2)
            : miniPointer.containsMouse && available
                ? FloralSettings.elevatedColor
                : Theme.panelRaised
        border.width: selected || (miniPointer.containsMouse && available) ? 2 : 1
        border.color: selected || (miniPointer.containsMouse && available)
            ? FloralSettings.accentColor
            : Theme.frameBorderFaint
        scale: miniPointer.pressed ? 0.98 : 1

        FloralSystemGlyph {
            visible: miniButton.iconKind.length > 0
            anchors {
                left: parent.left
                leftMargin: 13
                verticalCenter: parent.verticalCenter
            }
            width: 18
            height: 18
            kind: miniButton.iconKind
            color: miniButton.selected || miniPointer.containsMouse
                ? FloralSettings.accentColor
                : Theme.textMuted
        }

        Text {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: miniButton.iconKind.length > 0 ? 39 : 12
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            text: miniButton.title
            color: miniButton.selected
                ? Theme.moduleValue
                : Theme.textMuted
            horizontalAlignment: miniButton.iconKind.length > 0
                ? Text.AlignLeft
                : Text.AlignHCenter
            elide: Text.ElideRight
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                styleName: ShellConfig.typography.fineStyle
                pixelSize: 13
                weight: Font.DemiBold
            }
        }

        MouseArea {
            id: miniPointer

            anchors.fill: parent
            enabled: miniButton.available
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: miniButton.clicked()
        }

        Behavior on color {
            ColorAnimation {
                duration: FloralSettings.duration(120)
                easing.type: Easing.InOutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: FloralSettings.duration(100)
                easing.type: Easing.OutCubic
            }
        }
    }

    component SelectionRow: Rectangle {
        id: selectionRow

        required property string title
        required property string detail
        property string trailing: ""
        property bool selected: false
        property bool available: true
        signal clicked

        implicitHeight: 62
        radius: 12
        opacity: available ? 1 : 0.45
        color: selected
            ? FloralSettings.withAlpha(FloralSettings.accentColor, 0.14)
            : selectionPointer.containsMouse && available
                ? FloralSettings.elevatedColor
                : FloralSettings.withAlpha(Theme.panelRaised, 0.48)
        border.width: selected ? 2 : 1
        border.color: selected
            ? FloralSettings.accentColor
            : Theme.frameBorderFaint

        Rectangle {
            anchors {
                left: parent.left
                leftMargin: 14
                verticalCenter: parent.verticalCenter
            }
            width: 9
            height: 9
            radius: 5
            color: selectionRow.selected
                ? FloralSettings.accentColor
                : Theme.frameBorderFaint
        }

        Column {
            anchors {
                left: parent.left
                right: trailingText.left
                leftMargin: 37
                rightMargin: 16
                verticalCenter: parent.verticalCenter
            }
            spacing: 3

            Text {
                width: parent.width
                text: selectionRow.title
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
                width: parent.width
                text: selectionRow.detail
                color: Theme.textMuted
                elide: Text.ElideRight
                renderType: Text.NativeRendering
                font {
                    family: ShellConfig.typography.monoFamily
                    styleName: ShellConfig.typography.fineStyle
                    pixelSize: 11
                }
            }
        }

        Text {
            id: trailingText

            anchors {
                right: parent.right
                rightMargin: 16
                verticalCenter: parent.verticalCenter
            }
            width: Math.min(132, implicitWidth)
            text: selectionRow.trailing
            color: selectionRow.selected
                ? FloralSettings.accentColor
                : Theme.textMuted
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                styleName: ShellConfig.typography.fineStyle
                pixelSize: 12
                weight: Font.DemiBold
            }
        }

        MouseArea {
            id: selectionPointer

            anchors.fill: parent
            enabled: selectionRow.available
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: selectionRow.clicked()
        }

        Behavior on color {
            ColorAnimation {
                duration: FloralSettings.duration(120)
                easing.type: Easing.InOutCubic
            }
        }
    }

    component InfoRow: Rectangle {
        id: infoRow

        required property string title
        required property string value

        implicitHeight: 45
        radius: 10
        color: FloralSettings.withAlpha(Theme.panelRaised, 0.46)
        border.width: 1
        border.color: Theme.frameBorderFaint

        Text {
            anchors {
                left: parent.left
                leftMargin: 15
                verticalCenter: parent.verticalCenter
            }
            text: infoRow.title
            color: Theme.textMuted
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                styleName: ShellConfig.typography.fineStyle
                pixelSize: 12
            }
        }

        Text {
            anchors {
                left: parent.horizontalCenter
                right: parent.right
                rightMargin: 15
                verticalCenter: parent.verticalCenter
            }
            text: infoRow.value
            color: Theme.moduleValue
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                styleName: ShellConfig.typography.fineStyle
                pixelSize: 12
                weight: Font.DemiBold
            }
        }
    }

    IpcHandler {
        target: "settings"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function openPage(index: int): void { root.openPage(index); }
        function close(): void { root.close(); }
        function isOpen(): bool { return root.active; }
    }

    PanelWindow {
        id: overlay

        visible: root.active || panel.visible

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
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

        mask: Region {
            width: root.active ? overlay.width : 0
            height: root.active ? overlay.height : 0
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: root.active ? 0.5 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: FloralSettings.duration(170)
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

            anchors.centerIn: parent
            width: Math.min(940, overlay.width - 70)
            height: Math.min(690, overlay.height - 86)
            radius: Math.max(16, FloralSettings.popupRadius + 7)
            fillColor: Theme.panel
            borderColor: FloralSettings.accentColor
            innerBorderColor: Theme.frameBorderFaint
            elevated: FloralSettings.shadows
            ornamented: FloralSettings.ornaments
            ornamentStrength: 0.14
            ornamentSize: 190
            opacity: root.active ? 1 : 0
            scale: root.active ? 1 : 0.94
            visible: opacity > 0
            focus: root.active

            Keys.onEscapePressed: root.close()

            MouseArea {
                anchors.fill: parent
                onClicked: event => event.accepted = true
                z: -0.5
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: 78
                radius: panel.radius
                color: FloralSettings.withAlpha(Theme.panelHighlight, 0.22)

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: parent.radius
                    color: parent.color
                }

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 29
                        top: parent.top
                        topMargin: 15
                    }
                    text: "settings"
                    color: Theme.moduleValue
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        styleName: ShellConfig.typography.fineStyle
                        pixelSize: 24
                        weight: Font.DemiBold
                    }
                }

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 31
                        bottom: parent.bottom
                        bottomMargin: 12
                    }
                    text: "shell and system preferences"
                    color: Theme.textMuted
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        styleName: ShellConfig.typography.fineStyle
                        pixelSize: 12
                    }
                }

                Rectangle {
                    anchors {
                        right: parent.right
                        rightMargin: 22
                        verticalCenter: parent.verticalCenter
                    }
                    width: 40
                    height: 40
                    radius: 13
                    color: closePointer.containsMouse
                        ? FloralSettings.withAlpha(Theme.statusDanger, 0.18)
                        : FloralSettings.withAlpha(Theme.panelRaised, 0.72)
                    border.width: 1
                    border.color: closePointer.containsMouse
                        ? Theme.statusDanger
                        : Theme.frameBorderFaint

                    FloralGlyph {
                        anchors.centerIn: parent
                        width: 17
                        height: 17
                        kind: "close"
                        color: closePointer.containsMouse
                            ? Theme.statusDanger
                            : Theme.moduleValue
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
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: 8
                    topMargin: 86
                    bottomMargin: 8
                }
                width: 210
                radius: Math.max(10, panel.radius - 8)
                color: FloralSettings.withAlpha(Theme.panel, 0.48)
                border.width: 1
                border.color: Theme.frameBorderFaint

                Column {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 11
                    }
                    spacing: 7

                    Repeater {
                        model: [
                            { label: "appearance", icon: "appearance" },
                            { label: "dock", icon: "dock" },
                            { label: "motion", icon: "motion" },
                            { label: "interface", icon: "interface" },
                            { label: "network", icon: "network" },
                            { label: "bluetooth", icon: "bluetooth" },
                            { label: "audio", icon: "audio" },
                            { label: "system", icon: "system" }
                        ]

                        Rectangle {
                            id: navigationItem

                            required property int index
                            required property var modelData
                            readonly property bool selected: root.page === index
                            width: parent.width
                            height: 52
                            radius: 12
                            color: selected
                                ? FloralSettings.withAlpha(
                                    FloralSettings.accentColor, 0.18)
                                : navigationPointer.containsMouse
                                    ? FloralSettings.withAlpha(
                                        Theme.panelHighlight, 0.52)
                                    : "transparent"
                            border.width: selected ? 1 : 0
                            border.color: FloralSettings.accentColor

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    leftMargin: 1
                                    verticalCenter: parent.verticalCenter
                                }
                                width: 3
                                height: navigationItem.selected ? 24 : 0
                                radius: 2
                                color: FloralSettings.accentColor

                                Behavior on height {
                                    NumberAnimation {
                                        duration: FloralSettings.duration(160)
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            FloralGlyph {
                                visible: navigationItem.index < 4
                                anchors {
                                    left: parent.left
                                    leftMargin: 17
                                    verticalCenter: parent.verticalCenter
                                }
                                width: 21
                                height: 21
                                kind: navigationItem.modelData.icon
                                color: navigationItem.selected
                                    ? FloralSettings.accentColor
                                    : Theme.textMuted
                            }

                            FloralSystemGlyph {
                                visible: navigationItem.index >= 4
                                anchors {
                                    left: parent.left
                                    leftMargin: 17
                                    verticalCenter: parent.verticalCenter
                                }
                                width: 21
                                height: 21
                                kind: navigationItem.modelData.icon
                                color: navigationItem.selected
                                    ? FloralSettings.accentColor
                                    : Theme.textMuted
                            }

                            Text {
                                anchors {
                                    left: parent.left
                                    leftMargin: 52
                                    verticalCenter: parent.verticalCenter
                                }
                                text: navigationItem.modelData.label
                                color: navigationItem.selected
                                    ? Theme.moduleValue
                                    : Theme.textMuted
                                renderType: Text.NativeRendering
                                font {
                                    family: ShellConfig.typography.monoFamily
                                    styleName: ShellConfig.typography.fineStyle
                                    pixelSize: 14
                                    weight: navigationItem.selected
                                        ? Font.DemiBold
                                        : Font.Normal
                                }
                            }

                            MouseArea {
                                id: navigationPointer

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.page = navigationItem.index
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: FloralSettings.duration(120)
                                    easing.type: Easing.InOutCubic
                                }
                            }
                        }
                    }
                }

                Column {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        margins: 20
                    }
                    spacing: 7

                    Text {
                        text: "current accent"
                        color: Theme.textMuted
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: 11
                        }
                    }

                    Row {
                        spacing: 7

                        Repeater {
                            model: [
                                Theme.frameBorder,
                                Theme.accentSecondary,
                                Theme.accentTertiary,
                                Theme.moduleLabel
                            ]

                            Rectangle {
                                required property color modelData
                                width: 22
                                height: 8
                                radius: 4
                                color: modelData
                            }
                        }
                    }
                }
            }

            Item {
                id: pageArea

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: 236
                    rightMargin: 22
                    topMargin: 96
                    bottomMargin: 20
                }
                clip: true

                Flickable {
                    id: pageScroll

                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: pageLoader.item
                        ? pageLoader.item.implicitHeight
                        : 0
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 3400
                    clip: true

                    Loader {
                        id: pageLoader

                        width: pageScroll.width - 10
                        sourceComponent: root.page === 0
                            ? appearancePage
                            : root.page === 1
                                ? dockPage
                                : root.page === 2
                                    ? motionPage
                                    : root.page === 3
                                        ? interfacePage
                                        : root.page === 4
                                            ? networkPage
                                            : root.page === 5
                                                ? bluetoothPage
                                                : root.page === 6
                                                    ? audioPage
                                                    : systemPage
                    }

                    ParallelAnimation {
                        id: pageEntrance

                        NumberAnimation {
                            target: pageLoader
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: FloralSettings.duration(170)
                            easing.type: Easing.OutCubic
                        }

                        NumberAnimation {
                            target: pageLoader
                            property: "x"
                            from: 14
                            to: 0
                            duration: FloralSettings.duration(210)
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    y: pageScroll.contentHeight <= pageScroll.height
                        ? 0
                        : pageScroll.visibleArea.yPosition * parent.height
                    width: 3
                    height: pageScroll.contentHeight <= pageScroll.height
                        ? 0
                        : Math.max(30,
                            pageScroll.visibleArea.heightRatio * parent.height)
                    radius: 2
                    color: FloralSettings.accentColor
                    opacity: pageScroll.moving ? 0.9 : 0.35

                    Behavior on opacity {
                        NumberAnimation {
                            duration: FloralSettings.duration(160)
                            easing.type: Easing.InOutCubic
                        }
                    }
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: FloralSettings.duration(180)
                    easing.type: Easing.InOutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: FloralSettings.duration(240)
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Component {
        id: appearancePage

        Column {
            spacing: 10

            SectionLabel { text: "surfaces" }

            ToggleRow {
                width: parent.width
                title: "soft surfaces"
                detail: "let a little wallpaper color through"
                checked: FloralSettings.translucent
                onToggled: value => FloralSettings.translucent = value
            }

            ToggleRow {
                width: parent.width
                title: "shadows"
                detail: "add depth beneath floating elements"
                checked: FloralSettings.shadows
                onToggled: value => FloralSettings.shadows = value
            }

            ToggleRow {
                width: parent.width
                title: "floral details"
                detail: "show the quiet corner artwork"
                checked: FloralSettings.ornaments
                onToggled: value => FloralSettings.ornaments = value
            }

            SectionLabel {
                text: "accent"
                topPadding: 5
            }

            Row {
                width: parent.width
                height: 48
                spacing: 8

                Repeater {
                    model: ["wallpaper", "rose", "quiet"]

                    Rectangle {
                        id: accentChoice

                        required property int index
                        required property string modelData
                        width: (parent.width - parent.spacing * 2) / 3
                        height: parent.height
                        radius: 12
                        color: FloralSettings.accentStyle === index
                            ? FloralSettings.withAlpha(
                                FloralSettings.accentColor, 0.18)
                            : FloralSettings.withAlpha(
                                Theme.panelRaised, 0.46)
                        border.width: 1
                        border.color: FloralSettings.accentStyle === index
                            ? FloralSettings.accentColor
                            : Theme.frameBorderFaint

                        Rectangle {
                            anchors {
                                left: parent.left
                                leftMargin: 13
                                verticalCenter: parent.verticalCenter
                            }
                            width: 12
                            height: 12
                            radius: 6
                            color: accentChoice.index === 0
                                ? Theme.frameBorder
                                : accentChoice.index === 1
                                    ? Theme.accentSecondary
                                    : Theme.moduleValue
                        }

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 34
                                verticalCenter: parent.verticalCenter
                            }
                            text: accentChoice.modelData
                            color: Theme.moduleValue
                            renderType: Text.NativeRendering
                            font {
                                family: ShellConfig.typography.monoFamily
                                styleName: ShellConfig.typography.fineStyle
                                pixelSize: 12
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: FloralSettings.accentStyle
                                = accentChoice.index
                        }
                    }
                }
            }

            SliderRow {
                width: parent.width
                title: "popup rounding"
                detail: "shared popup corners"
                from: 6
                to: 28
                stepSize: 1
                value: FloralSettings.popupRadius
                valueText: `${Math.round(value)} px`
                onMoved: value => FloralSettings.popupRadius = value
            }

            FloralSurface {
                width: parent.width
                height: 112
                radius: Math.max(12, FloralSettings.popupRadius)
                fillColor: FloralSettings.surfaceColor
                borderColor: FloralSettings.accentColor
                elevated: FloralSettings.shadows
                ornamented: FloralSettings.ornaments
                ornamentStrength: 0.12
                ornamentSize: 90

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 20
                        top: parent.top
                        topMargin: 17
                    }
                    text: "preview"
                    color: Theme.moduleLabel
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        styleName: ShellConfig.typography.fineStyle
                        pixelSize: 12
                    }
                }

                Row {
                    anchors {
                        left: parent.left
                        leftMargin: 20
                        bottom: parent.bottom
                        bottomMargin: 18
                    }
                    spacing: 10

                    Repeater {
                        model: 4

                        Rectangle {
                            required property int index
                            width: index === 3 ? 78 : 42
                            height: 27
                            radius: Math.max(7,
                                FloralSettings.popupRadius * 0.55)
                            color: index === 0
                                ? FloralSettings.withAlpha(
                                    FloralSettings.accentColor, 0.22)
                                : Theme.panelHighlight
                            border.width: 1
                            border.color: index === 0
                                ? FloralSettings.accentColor
                                : Theme.frameBorderFaint
                        }
                    }
                }
            }
        }
    }

    Component {
        id: dockPage

        Column {
            spacing: 10

            SectionLabel { text: "behavior" }

            ToggleRow {
                width: parent.width
                title: "show dock"
                detail: "keep the app taskbar available"
                checked: FloralSettings.dockEnabled
                onToggled: value => FloralSettings.dockEnabled = value
            }

            ToggleRow {
                width: parent.width
                title: "hide when idle"
                detail: "leave a small edge target at the bottom"
                checked: FloralSettings.dockAutoHide
                onToggled: value => FloralSettings.dockAutoHide = value
            }

            ToggleRow {
                width: parent.width
                title: "hover magnification"
                detail: "lift the app beneath the pointer"
                checked: FloralSettings.dockMagnification
                onToggled: value => FloralSettings.dockMagnification = value
            }

            ToggleRow {
                width: parent.width
                title: "system tray"
                detail: "keep background app indicators in the dock"
                checked: FloralSettings.dockTray
                onToggled: value => FloralSettings.dockTray = value
            }

            SectionLabel {
                text: "size"
                topPadding: 5
            }

            SliderRow {
                width: parent.width
                title: "app size"
                detail: "dock icon scale"
                from: 32
                to: 58
                stepSize: 1
                value: FloralSettings.iconSize
                valueText: `${Math.round(value)} px`
                onMoved: value => FloralSettings.iconSize = value
            }

            SliderRow {
                width: parent.width
                title: "screen margin"
                detail: "space beneath the dock"
                from: 6
                to: 30
                stepSize: 1
                value: FloralSettings.dockMargin
                valueText: `${Math.round(value)} px`
                onMoved: value => FloralSettings.dockMargin = value
            }

            Text {
                width: parent.width
                topPadding: 4
                text: "right click an app to pin or unpin it, middle click opens another window"
                color: Theme.textMuted
                wrapMode: Text.WordWrap
                renderType: Text.NativeRendering
                font {
                    family: ShellConfig.typography.monoFamily
                    styleName: ShellConfig.typography.fineStyle
                    pixelSize: 11
                }
            }
        }
    }

    Component {
        id: motionPage

        Column {
            spacing: 10

            SectionLabel { text: "movement" }

            ToggleRow {
                width: parent.width
                title: "motion"
                detail: "animate panels and rendered controls"
                checked: FloralSettings.motionEnabled
                onToggled: value => FloralSettings.motionEnabled = value
            }

            SliderRow {
                width: parent.width
                title: "animation pace"
                detail: "lower values feel quicker"
                from: 0.55
                to: 1.55
                stepSize: 0.05
                value: FloralSettings.animationScale
                valueText: `${Math.round(value * 100)}%`
                onMoved: value => FloralSettings.animationScale = value
            }

            FloralSurface {
                id: motionPreview

                width: parent.width
                height: 170
                radius: 15
                fillColor: FloralSettings.withAlpha(Theme.panelRaised, 0.52)
                borderColor: Theme.frameBorderFaint
                elevated: false

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 20
                        top: parent.top
                        topMargin: 17
                    }
                    text: "motion preview"
                    color: Theme.moduleLabel
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        styleName: ShellConfig.typography.fineStyle
                        pixelSize: 12
                    }
                }

                Rectangle {
                    id: previewLine

                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 26
                        rightMargin: 26
                    }
                    height: 2
                    radius: 1
                    color: Theme.frameBorderFaint
                }

                Repeater {
                    model: 3

                    Rectangle {
                        id: movingPetal

                        required property int index
                        property real progress: 0
                        x: 27 + progress * (motionPreview.width - 72)
                        anchors.verticalCenter: previewLine.verticalCenter
                        width: 20 + index * 4
                        height: width
                        radius: width / 2
                        color: index === 0
                            ? FloralSettings.accentColor
                            : index === 1
                                ? Theme.accentSecondary
                                : Theme.accentTertiary

                        SequentialAnimation on progress {
                            running: FloralSettings.motionEnabled
                                && root.page === 2
                                && root.active
                            loops: Animation.Infinite
                            PauseAnimation {
                                duration: movingPetal.index * 130
                            }
                            NumberAnimation {
                                from: 0
                                to: 1
                                duration: FloralSettings.duration(
                                    920 + movingPetal.index * 120)
                                easing.type: Easing.InOutCubic
                            }
                            NumberAnimation {
                                from: 1
                                to: 0
                                duration: FloralSettings.duration(
                                    920 + movingPetal.index * 120)
                                easing.type: Easing.InOutCubic
                            }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: "turning motion off keeps every control usable and removes decorative movement"
                color: Theme.textMuted
                wrapMode: Text.WordWrap
                renderType: Text.NativeRendering
                font {
                    family: ShellConfig.typography.monoFamily
                    styleName: ShellConfig.typography.fineStyle
                    pixelSize: 11
                }
            }
        }
    }

    Component {
        id: interfacePage

        Column {
            spacing: 10

            SectionLabel { text: "shell" }

            SliderRow {
                width: parent.width
                title: "interface scale"
                detail: "bar and popup content"
                from: 0.9
                to: 1.5
                stepSize: 0.05
                value: FloralSettings.interfaceScale
                valueText: `${Math.round(value * 100)}%`
                onMoved: value => FloralSettings.interfaceScale = value
            }

            SliderRow {
                width: parent.width
                title: "bar height"
                detail: "top bar and workspace reserve"
                from: 44
                to: 62
                stepSize: 1
                value: FloralSettings.barHeight
                valueText: `${Math.round(value)} px`
                onMoved: value => FloralSettings.barHeight = value
            }

            SliderRow {
                width: parent.width
                title: "drawer rounding"
                detail: "notification panel corner"
                from: 0
                to: 42
                stepSize: 1
                value: FloralSettings.drawerRadius
                valueText: `${Math.round(value)} px`
                onMoved: value => FloralSettings.drawerRadius = value
            }

            SectionLabel {
                text: "shortcuts"
                topPadding: 6
            }

            Row {
                width: parent.width
                height: 48
                spacing: 8

                ActionButton {
                    width: (parent.width - parent.spacing * 2) / 3
                    height: parent.height
                    title: "wallpapers"
                    iconKind: "wallpaper"
                    onClicked: {
                        root.close();
                        Quickshell.execDetached(["qs", "ipc", "call",
                            "wallpaperCarousel", "toggle"]);
                    }
                }

                ActionButton {
                    width: (parent.width - parent.spacing * 2) / 3
                    height: parent.height
                    title: "shell config"
                    iconKind: "edit"
                    onClicked: root.editFile(
                        `${Quickshell.env("HOME")}/.config/quickshell/ShellConfig.qml`)
                }

                ActionButton {
                    width: (parent.width - parent.spacing * 2) / 3
                    height: parent.height
                    title: "theme"
                    iconKind: "edit"
                    onClicked: root.editFile(
                        `${Quickshell.env("HOME")}/.config/quickshell/Theme.qml`)
                }
            }

            Text {
                width: parent.width
                topPadding: 5
                text: "changes here are saved automatically"
                color: Theme.textMuted
                renderType: Text.NativeRendering
                font {
                    family: ShellConfig.typography.monoFamily
                    styleName: ShellConfig.typography.fineStyle
                    pixelSize: 11
                }
            }
        }
    }

    Component {
        id: networkPage

        Column {
            id: networkColumn

            spacing: 10

            function submitPassword() {
                const password = networkPassword.text;
                networkPassword.text = "";
                FloralSystemService.connectPending(password);
            }

            SectionLabel { text: "connection" }

            Rectangle {
                width: parent.width
                height: 82
                radius: 13
                color: Theme.panelRaised
                border.width: 1
                border.color: FloralSystemService.activeNetwork
                    ? FloralSettings.accentColor
                    : Theme.frameBorderFaint

                FloralSystemGlyph {
                    anchors {
                        left: parent.left
                        leftMargin: 18
                        verticalCenter: parent.verticalCenter
                    }
                    width: 27
                    height: 27
                    kind: "network"
                    color: FloralSystemService.activeNetwork
                        ? FloralSettings.accentColor
                        : Theme.textMuted
                }

                Column {
                    anchors {
                        left: parent.left
                        right: wifiState.left
                        leftMargin: 58
                        rightMargin: 16
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 4

                    Text {
                        width: parent.width
                        text: FloralSystemService.activeNetwork?.ssid
                            || FloralSystemService.activeConnection
                            || "not connected"
                        color: Theme.moduleValue
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: 17
                            weight: Font.DemiBold
                        }
                    }

                    Text {
                        width: parent.width
                        text: FloralSystemService.networkMessage
                            || (FloralSystemService.activeInterface
                                ? `${FloralSystemService.activeInterface} · ${FloralSystemService.networkConnected ? "online" : "local"}`
                                : FloralSystemService.wifiEnabled
                                    ? "wi-fi ready"
                                    : "wi-fi is off")
                        color: Theme.textMuted
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: 12
                        }
                    }
                }

                FloralSwitch {
                    id: wifiState

                    anchors {
                        right: parent.right
                        rightMargin: 17
                        verticalCenter: parent.verticalCenter
                    }
                    checked: FloralSystemService.wifiEnabled
                    enabled: !FloralSystemService.networkBusy
                    onToggled: value => FloralSystemService.setWifi(value)
                }
            }

            Row {
                width: parent.width
                height: 44
                spacing: 8

                MiniButton {
                    width: 150
                    height: parent.height
                    title: FloralSystemService.networkScanning
                        ? "scanning"
                        : "scan again"
                    iconKind: "refresh"
                    available: FloralSystemService.wifiEnabled
                        && !FloralSystemService.networkScanning
                    onClicked: FloralSystemService.scanNetworks()
                }

                Text {
                    width: parent.width - 158
                    anchors.verticalCenter: parent.verticalCenter
                    text: FloralSystemService.wifiEnabled
                        ? `${FloralSystemService.networks.length} networks nearby`
                        : "turn on wi-fi to see networks"
                    color: Theme.textMuted
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        styleName: ShellConfig.typography.fineStyle
                        pixelSize: 12
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: visible ? 148 : 0
                visible: FloralSystemService.passwordRequested
                opacity: visible ? 1 : 0
                clip: true
                radius: 13
                color: Theme.panelRaised
                border.width: 2
                border.color: FloralSettings.accentColor

                onVisibleChanged: {
                    if (visible)
                        Qt.callLater(() => networkPassword.takeFocus());
                }

                Text {
                    anchors {
                        left: parent.left
                        top: parent.top
                        leftMargin: 16
                        topMargin: 12
                    }
                    text: `join ${FloralSystemService.pendingNetwork?.ssid || "network"}`
                    color: Theme.moduleValue
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        styleName: ShellConfig.typography.fineStyle
                        pixelSize: 14
                        weight: Font.DemiBold
                    }
                }

                FloralTextField {
                    id: networkPassword

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        leftMargin: 15
                        rightMargin: 15
                        topMargin: 39
                    }
                    password: true
                    placeholderText: "network password"
                    onAccepted: networkColumn.submitPassword()
                }

                Row {
                    anchors {
                        right: parent.right
                        bottom: parent.bottom
                        rightMargin: 15
                        bottomMargin: 10
                    }
                    spacing: 7

                    MiniButton {
                        width: 92
                        height: 38
                        title: "cancel"
                        onClicked: {
                            networkPassword.text = "";
                            FloralSystemService.cancelPassword();
                        }
                    }

                    MiniButton {
                        width: 106
                        height: 38
                        title: "connect"
                        selected: true
                        available: !FloralSystemService.networkBusy
                        onClicked: networkColumn.submitPassword()
                    }
                }

                Behavior on height {
                    NumberAnimation {
                        duration: FloralSettings.duration(180)
                        easing.type: Easing.OutCubic
                    }
                }
            }

            SectionLabel {
                text: "available networks"
                topPadding: 4
            }

            Repeater {
                model: FloralSystemService.networks.slice(0, 8)

                SelectionRow {
                    required property var modelData

                    width: networkColumn.width
                    title: modelData.ssid
                    detail: FloralSystemService.networkSecure(modelData)
                        ? FloralSystemService.savedNetwork(modelData.ssid)
                            ? `${modelData.security} · saved`
                            : modelData.security
                        : "open network"
                    trailing: modelData.active
                        ? "disconnect"
                        : `${modelData.strength}%`
                    selected: modelData.active
                    available: !FloralSystemService.networkBusy
                        || modelData.active
                    onClicked: FloralSystemService.chooseNetwork(modelData)
                }
            }

            Text {
                visible: FloralSystemService.wifiEnabled
                    && FloralSystemService.networks.length === 0
                width: parent.width
                topPadding: 22
                text: FloralSystemService.networkScanning
                    ? "looking for networks"
                    : "no networks found"
                color: Theme.textMuted
                horizontalAlignment: Text.AlignHCenter
                renderType: Text.NativeRendering
                font {
                    family: ShellConfig.typography.monoFamily
                    styleName: ShellConfig.typography.fineStyle
                    pixelSize: 13
                }
            }

            SectionLabel {
                visible: FloralSystemService.savedNetworks.length > 0
                text: "saved networks"
                topPadding: 6
            }

            Repeater {
                model: FloralSystemService.savedNetworks

                Rectangle {
                    id: savedProfile

                    required property var modelData
                    property bool forgetArmed: false

                    width: networkColumn.width
                    height: 68
                    radius: 12
                    color: modelData.active
                        ? FloralSettings.withAlpha(
                            FloralSettings.accentColor, 0.14)
                        : FloralSettings.withAlpha(Theme.panelRaised, 0.48)
                    border.width: modelData.active ? 2 : 1
                    border.color: modelData.active
                        ? FloralSettings.accentColor
                        : Theme.frameBorderFaint

                    Rectangle {
                        anchors {
                            left: parent.left
                            leftMargin: 14
                            verticalCenter: parent.verticalCenter
                        }
                        width: 9
                        height: 9
                        radius: 5
                        color: savedProfile.modelData.active
                            ? FloralSettings.accentColor
                            : Theme.frameBorderFaint
                    }

                    Column {
                        anchors {
                            left: parent.left
                            right: profileActions.left
                            leftMargin: 37
                            rightMargin: 14
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 3

                        Text {
                            width: parent.width
                            text: savedProfile.modelData.ssid
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
                            width: parent.width
                            text: `${savedProfile.modelData.security} · ${
                                savedProfile.modelData.active
                                    ? "connected"
                                    : savedProfile.modelData.available
                                        ? "nearby"
                                        : "not nearby"}`
                            color: savedProfile.modelData.active
                                ? FloralSettings.accentColor
                                : Theme.textMuted
                            elide: Text.ElideRight
                            renderType: Text.NativeRendering
                            font {
                                family: ShellConfig.typography.monoFamily
                                styleName: ShellConfig.typography.fineStyle
                                pixelSize: 11
                            }
                        }
                    }

                    Row {
                        id: profileActions

                        anchors {
                            right: parent.right
                            rightMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 6

                        MiniButton {
                            width: 82
                            height: 40
                            title: savedProfile.modelData.active
                                ? "active"
                                : "connect"
                            selected: savedProfile.modelData.active
                            available: FloralSystemService.wifiEnabled
                                && !FloralSystemService.networkBusy
                                && !savedProfile.modelData.active
                            onClicked: FloralSystemService.activateSavedNetwork(
                                savedProfile.modelData.ssid)
                        }

                        MiniButton {
                            width: savedProfile.forgetArmed ? 84 : 68
                            height: 40
                            title: savedProfile.forgetArmed
                                ? "confirm"
                                : "forget"
                            selected: savedProfile.forgetArmed
                            available: !FloralSystemService.networkBusy
                            onClicked: {
                                if (!savedProfile.forgetArmed) {
                                    savedProfile.forgetArmed = true;
                                    forgetTimer.restart();
                                    return;
                                }
                                forgetTimer.stop();
                                savedProfile.forgetArmed = false;
                                FloralSystemService.forgetSavedNetwork(
                                    savedProfile.modelData.ssid);
                            }

                            Behavior on width {
                                NumberAnimation {
                                    duration: FloralSettings.duration(130)
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }

                    Timer {
                        id: forgetTimer

                        interval: 3000
                        onTriggered: savedProfile.forgetArmed = false
                    }
                }
            }
        }
    }

    Component {
        id: bluetoothPage

        Column {
            id: bluetoothColumn

            spacing: 10

            readonly property var adapter: FloralSystemService.bluetoothAdapter

            SectionLabel { text: "bluetooth" }

            Rectangle {
                width: parent.width
                height: 76
                radius: 13
                color: Theme.panelRaised
                border.width: 1
                border.color: bluetoothColumn.adapter?.enabled
                    ? FloralSettings.accentColor
                    : Theme.frameBorderFaint

                FloralSystemGlyph {
                    anchors {
                        left: parent.left
                        leftMargin: 18
                        verticalCenter: parent.verticalCenter
                    }
                    width: 26
                    height: 26
                    kind: "bluetooth"
                    color: bluetoothColumn.adapter?.enabled
                        ? FloralSettings.accentColor
                        : Theme.textMuted
                }

                Column {
                    anchors {
                        left: parent.left
                        right: bluetoothPower.left
                        leftMargin: 58
                        rightMargin: 16
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 4

                    Text {
                        width: parent.width
                        text: !FloralSystemService.serviceCheckComplete
                            ? "checking bluetooth"
                            : bluetoothColumn.adapter?.name
                                || "bluetooth unavailable"
                        color: Theme.moduleValue
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: 16
                            weight: Font.DemiBold
                        }
                    }

                    Text {
                        width: parent.width
                        text: !FloralSystemService.serviceCheckComplete
                            ? "checking system services"
                            : bluetoothColumn.adapter === null
                                ? "bluetooth service is not available"
                            : FloralSystemService.connectedBluetoothDevices === 0
                                ? "no devices connected"
                            : FloralSystemService.connectedBluetoothDevices === 1
                                ? "1 device connected"
                                : `${FloralSystemService.connectedBluetoothDevices} devices connected`
                        color: Theme.textMuted
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: 12
                        }
                    }
                }

                FloralSwitch {
                    id: bluetoothPower

                    anchors {
                        right: parent.right
                        rightMargin: 17
                        verticalCenter: parent.verticalCenter
                    }
                    enabled: bluetoothColumn.adapter !== null
                    checked: bluetoothColumn.adapter?.enabled ?? false
                    onToggled: value => {
                        if (bluetoothColumn.adapter)
                            bluetoothColumn.adapter.enabled = value;
                    }
                }
            }

            ToggleRow {
                width: parent.width
                title: "discoverable"
                detail: "let nearby devices find this computer"
                available: bluetoothColumn.adapter?.enabled ?? false
                checked: bluetoothColumn.adapter?.discoverable ?? false
                onToggled: value => bluetoothColumn.adapter.discoverable = value
            }

            ToggleRow {
                width: parent.width
                title: bluetoothColumn.adapter?.discovering
                    ? "scanning"
                    : "find devices"
                detail: "show paired and nearby bluetooth devices"
                available: bluetoothColumn.adapter?.enabled ?? false
                checked: bluetoothColumn.adapter?.discovering ?? false
                onToggled: value => bluetoothColumn.adapter.discovering = value
            }

            SectionLabel {
                text: "devices"
                topPadding: 4
            }

            Repeater {
                model: FloralSystemService.bluetoothDevices.slice(0, 8)

                SelectionRow {
                    required property var modelData

                    readonly property bool loading:
                        FloralSystemService.bluetoothDeviceBusy(modelData)

                    width: bluetoothColumn.width
                    title: FloralSystemService.deviceName(modelData)
                    detail: loading
                        ? modelData.connected ? "disconnecting" : "connecting"
                        : modelData.connected
                            ? "connected"
                            : modelData.paired || modelData.bonded
                                ? "paired"
                                : "available"
                    trailing: modelData.batteryAvailable
                        ? `${Math.round(modelData.battery * 100)}%`
                        : modelData.connected
                            ? "disconnect"
                            : modelData.paired || modelData.bonded
                                ? "connect"
                                : "pair"
                    selected: modelData.connected
                    available: !loading
                    onClicked: FloralSystemService.toggleBluetoothDevice(modelData)
                }
            }

            Text {
                visible: FloralSystemService.bluetoothDevices.length === 0
                width: parent.width
                topPadding: 22
                text: !FloralSystemService.serviceCheckComplete
                    ? "checking bluetooth"
                    : bluetoothColumn.adapter === null
                        ? "bluetooth service is not available"
                    : bluetoothColumn.adapter.enabled
                        ? "no bluetooth devices found"
                        : "turn on bluetooth to see devices"
                color: Theme.textMuted
                horizontalAlignment: Text.AlignHCenter
                renderType: Text.NativeRendering
                font {
                    family: ShellConfig.typography.monoFamily
                    styleName: ShellConfig.typography.fineStyle
                    pixelSize: 13
                }
            }
        }
    }

    Component {
        id: audioPage

        Column {
            id: audioColumn

            spacing: 10

            SectionLabel { text: "output" }

            SliderRow {
                width: parent.width
                title: "volume"
                detail: FloralSystemService.audioSink?.description
                    || FloralSystemService.audioSink?.name
                    || "no output device"
                from: 0
                to: 1
                stepSize: 0.01
                value: FloralSystemService.outputVolume
                valueText: FloralSystemService.outputMuted
                    ? "muted"
                    : `${Math.round(value * 100)}%`
                onMoved: value => FloralSystemService.setOutputVolume(value)
            }

            ToggleRow {
                width: parent.width
                title: "mute output"
                detail: "silence the default output device"
                available: FloralSystemService.audioSink !== null
                checked: FloralSystemService.outputMuted
                onToggled: value => FloralSystemService.setOutputMuted(value)
            }

            Repeater {
                model: FloralSystemService.audioSinks

                SelectionRow {
                    required property var modelData

                    width: audioColumn.width
                    title: modelData.description || modelData.name || "audio output"
                    detail: "output device"
                    trailing: selected ? "selected" : "select"
                    selected: FloralSystemService.audioSink?.id === modelData.id
                    onClicked: FloralSystemService.selectAudioSink(modelData)
                }
            }

            SectionLabel {
                text: "input"
                topPadding: 6
            }

            SliderRow {
                width: parent.width
                title: "microphone"
                detail: FloralSystemService.audioSource?.description
                    || FloralSystemService.audioSource?.name
                    || "no input device"
                from: 0
                to: 1
                stepSize: 0.01
                value: FloralSystemService.inputVolume
                valueText: FloralSystemService.inputMuted
                    ? "muted"
                    : `${Math.round(value * 100)}%`
                onMoved: value => FloralSystemService.setInputVolume(value)
            }

            ToggleRow {
                width: parent.width
                title: "mute input"
                detail: "silence the default microphone"
                available: FloralSystemService.audioSource !== null
                checked: FloralSystemService.inputMuted
                onToggled: value => FloralSystemService.setInputMuted(value)
            }

            Repeater {
                model: FloralSystemService.audioSources

                SelectionRow {
                    required property var modelData

                    width: audioColumn.width
                    title: modelData.description || modelData.name || "audio input"
                    detail: "input device"
                    trailing: selected ? "selected" : "select"
                    selected: FloralSystemService.audioSource?.id === modelData.id
                    onClicked: FloralSystemService.selectAudioSource(modelData)
                }
            }

            SectionLabel {
                visible: FloralSystemService.audioStreams.length > 0
                text: "application streams"
                topPadding: 6
            }

            Repeater {
                model: FloralSystemService.audioStreams

                SliderRow {
                    required property var modelData

                    width: audioColumn.width
                    title: FloralSystemService.audioStreamName(modelData)
                    detail: `${FloralSystemService.audioStreamDetail(modelData)}${
                        modelData?.audio?.muted ? " · muted" : ""}`
                    from: 0
                    to: 1
                    stepSize: 0.01
                    value: modelData?.audio?.volume ?? 0
                    valueText: modelData?.audio?.muted
                        ? "muted"
                        : `${Math.round(value * 100)}%`
                    onMoved: value => FloralSystemService.setAudioStreamVolume(
                        modelData, value)
                }
            }
        }
    }

    Component {
        id: systemPage

        Column {
            id: systemColumn

            spacing: 10

            SectionLabel { text: "display" }

            SliderRow {
                width: parent.width
                title: "brightness"
                detail: "built-in display"
                from: 0
                to: 1
                stepSize: 0.01
                value: FloralSystemService.brightness
                valueText: `${Math.round(value * 100)}%`
                onMoved: value => FloralSystemService.setBrightness(value)
            }

            SectionLabel {
                text: FloralSystemService.powerProfilesAvailable
                    ? "power profile"
                    : "power profile · unavailable"
                topPadding: 5
            }

            Row {
                width: parent.width
                height: 44
                spacing: 8

                MiniButton {
                    width: (parent.width - parent.spacing * 2) / 3
                    height: parent.height
                    title: "power saver"
                    selected: FloralSystemService.powerProfilesAvailable
                        && PowerProfiles.profile === PowerProfile.PowerSaver
                    available: FloralSystemService.powerProfilesAvailable
                    onClicked: PowerProfiles.profile = PowerProfile.PowerSaver
                }

                MiniButton {
                    width: (parent.width - parent.spacing * 2) / 3
                    height: parent.height
                    title: "balanced"
                    selected: FloralSystemService.powerProfilesAvailable
                        && PowerProfiles.profile === PowerProfile.Balanced
                    available: FloralSystemService.powerProfilesAvailable
                    onClicked: PowerProfiles.profile = PowerProfile.Balanced
                }

                MiniButton {
                    width: (parent.width - parent.spacing * 2) / 3
                    height: parent.height
                    title: "performance"
                    selected: FloralSystemService.powerProfilesAvailable
                        && PowerProfiles.profile === PowerProfile.Performance
                    available: FloralSystemService.powerProfilesAvailable
                        && PowerProfiles.hasPerformanceProfile
                    onClicked: PowerProfiles.profile = PowerProfile.Performance
                }
            }

            SectionLabel {
                text: "idle and lock"
                topPadding: 6
            }

            ToggleRow {
                width: parent.width
                title: "automatic idle"
                detail: "lock and turn off the display after inactivity"
                checked: FloralSettings.idleEnabled
                onToggled: value => FloralSettings.idleEnabled = value
            }

            SliderRow {
                width: parent.width
                visible: FloralSettings.idleEnabled
                title: "lock after"
                detail: "session inactivity"
                from: 1
                to: 60
                stepSize: 1
                value: FloralSettings.idleLockTimeoutMinutes
                valueText: `${Math.round(value)} min`
                onMoved: value => FloralSettings.idleLockTimeoutMinutes
                    = Math.round(value)
            }

            SliderRow {
                width: parent.width
                visible: FloralSettings.idleEnabled
                title: "display off after"
                detail: "session inactivity"
                from: 2
                to: 120
                stepSize: 1
                value: FloralSettings.idleDpmsTimeoutMinutes
                valueText: `${Math.round(value)} min`
                onMoved: value => FloralSettings.idleDpmsTimeoutMinutes
                    = Math.round(value)
            }

            ToggleRow {
                width: parent.width
                visible: FloralSettings.idleEnabled
                title: "media keeps display on"
                detail: "playing audio delays display power saving"
                checked: FloralSettings.idleInhibitDpmsWhenPlaying
                onToggled: value =>
                    FloralSettings.idleInhibitDpmsWhenPlaying = value
            }

            ToggleRow {
                width: parent.width
                visible: FloralSettings.idleEnabled
                title: "media delays lock"
                detail: "playing audio also delays session locking"
                checked: FloralSettings.idleInhibitLockWhenPlaying
                onToggled: value =>
                    FloralSettings.idleInhibitLockWhenPlaying = value
            }

            ToggleRow {
                width: parent.width
                visible: FloralSettings.idleEnabled
                title: "stay awake while charging"
                detail: "ignore automatic idle while connected to power"
                checked: FloralSettings.idleInhibitWhenCharging
                onToggled: value =>
                    FloralSettings.idleInhibitWhenCharging = value
            }

            ToggleRow {
                width: parent.width
                title: "lock before sleep"
                detail: "secure the session whenever the system suspends"
                checked: FloralSettings.idleLockBeforeSleep
                onToggled: value => FloralSettings.idleLockBeforeSleep = value
            }

            SectionLabel {
                text: "session"
                topPadding: 6
            }

            Row {
                width: parent.width
                height: 48
                spacing: 8

                MiniButton {
                    width: (parent.width - parent.spacing * 2) / 3
                    height: parent.height
                    title: "lock"
                    iconKind: "lock"
                    onClicked: {
                        root.close();
                        FloralSystemService.lockSession();
                    }
                }

                MiniButton {
                    width: (parent.width - parent.spacing * 2) / 3
                    height: parent.height
                    title: "suspend"
                    iconKind: "suspend"
                    onClicked: {
                        root.close();
                        FloralSystemService.suspendSession();
                    }
                }

                MiniButton {
                    width: (parent.width - parent.spacing * 2) / 3
                    height: parent.height
                    title: "power menu"
                    iconKind: "power"
                    onClicked: {
                        root.close();
                        FloralSystemService.openPowerMenu();
                    }
                }
            }

            SectionLabel {
                text: "about"
                topPadding: 6
            }

            InfoRow {
                width: parent.width
                title: "system"
                value: FloralSystemService.osPrettyName || "linux"
            }

            InfoRow {
                width: parent.width
                title: "device"
                value: FloralSystemService.device
                    || FloralSystemService.hostname
            }

            InfoRow {
                width: parent.width
                title: "kernel"
                value: FloralSystemService.kernel
            }

            InfoRow {
                width: parent.width
                title: "session"
                value: FloralSystemService.session
            }

            InfoRow {
                width: parent.width
                title: "user"
                value: `${FloralSystemService.user}@${FloralSystemService.hostname}`
            }

            InfoRow {
                width: parent.width
                title: "uptime"
                value: FloralSystemService.uptime
            }
        }
    }
}
