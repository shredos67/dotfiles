import QtQuick

Item {
    id: root

    required property real volume
    required property bool muted
    required property real brightness

    property bool armed: false
    property bool open: false
    property string displayKind: "volume"
    property real displayValue: 0
    property bool displayMuted: false

    readonly property color accent: displayKind === "volume" && displayMuted
        ? Theme.statusDanger
        : displayKind === "brightness"
            ? Theme.accentSecondary
            : Theme.accentPrimary
    readonly property real progressValue: displayKind === "volume" && displayMuted
        ? 0
        : Math.max(0, Math.min(1, displayValue))

    implicitWidth: ShellConfig.scaled(218)
    implicitHeight: Math.min(
        ShellConfig.bar.surfaceHeight - ShellConfig.scaled(10),
        ShellConfig.scaled(38))
    opacity: open ? 1 : 0
    scale: open ? 1 : 0.96
    visible: open || opacity > 0
    transformOrigin: Item.Center

    function show(kind: string, value: real, isMuted: bool): void {
        displayKind = kind;
        displayValue = Math.max(0, Math.min(1, value));
        displayMuted = isMuted;
        open = true;
        hideTimer.restart();
    }

    function showVolume(): void {
        show("volume", volume, muted);
    }

    function showBrightness(): void {
        show("brightness", brightness, false);
    }

    onVolumeChanged: {
        if (armed)
            showVolume();
    }

    onMutedChanged: {
        if (armed)
            showVolume();
    }

    onBrightnessChanged: {
        if (armed)
            showBrightness();
    }

    Behavior on opacity {
        NumberAnimation {
            duration: FloralSettings.duration(150)
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: FloralSettings.duration(180)
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        interval: 450
        running: true
        onTriggered: {
            root.displayValue = root.volume;
            root.displayMuted = root.muted;
            root.armed = true;
        }
    }

    Timer {
        id: hideTimer

        interval: 1100
        onTriggered: root.open = false
    }

    Rectangle {
        anchors.fill: parent
        radius: ShellConfig.visuals.controlRadius
        color: Theme.panelRaised
        border.width: ShellConfig.bar.hairlineThickness
        border.color: root.accent

        Rectangle {
            anchors.fill: parent
            anchors.margins: ShellConfig.scaled(3)
            radius: Math.max(0, parent.radius - ShellConfig.scaled(3))
            color: "transparent"
            border.width: ShellConfig.bar.hairlineThickness
            border.color: Theme.frameBorderFaint
        }

        Row {
            id: content

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: ShellConfig.scaled(9)
                rightMargin: ShellConfig.scaled(9)
            }
            spacing: ShellConfig.scaled(6)

            Canvas {
                id: glyph

                property string kind: root.displayKind
                property bool muted: root.displayMuted
                property color glyphColor: root.accent

                anchors.verticalCenter: parent.verticalCenter
                width: ShellConfig.scaled(18)
                height: width
                antialiasing: true

                onKindChanged: requestPaint()
                onMutedChanged: requestPaint()
                onGlyphColorChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                onPaint: {
                    const context = getContext("2d");
                    const scaleX = width / 24;
                    const scaleY = height / 24;

                    context.reset();
                    context.scale(scaleX, scaleY);
                    context.strokeStyle = glyphColor;
                    context.fillStyle = glyphColor;
                    context.lineWidth = 1.9;
                    context.lineCap = "round";
                    context.lineJoin = "round";

                    if (kind === "brightness") {
                        context.beginPath();
                        context.arc(12, 12, 3.6, 0, Math.PI * 2);
                        context.stroke();

                        for (let index = 0; index < 8; ++index) {
                            const angle = index * Math.PI / 4;
                            context.beginPath();
                            context.moveTo(
                                12 + Math.cos(angle) * 6.4,
                                12 + Math.sin(angle) * 6.4);
                            context.lineTo(
                                12 + Math.cos(angle) * 9,
                                12 + Math.sin(angle) * 9);
                            context.stroke();
                        }
                        return;
                    }

                    context.beginPath();
                    context.moveTo(3.5, 9);
                    context.lineTo(8, 9);
                    context.lineTo(13, 5.2);
                    context.lineTo(13, 18.8);
                    context.lineTo(8, 15);
                    context.lineTo(3.5, 15);
                    context.closePath();
                    context.stroke();

                    if (muted) {
                        context.beginPath();
                        context.moveTo(16, 8);
                        context.lineTo(21, 16);
                        context.moveTo(21, 8);
                        context.lineTo(16, 16);
                        context.stroke();
                    } else {
                        context.beginPath();
                        context.arc(13, 12, 5, -0.78, 0.78);
                        context.stroke();
                        context.beginPath();
                        context.arc(13, 12, 8, -0.68, 0.68);
                        context.stroke();
                    }
                }
            }

            Text {
                id: label

                anchors.verticalCenter: parent.verticalCenter
                width: ShellConfig.scaled(27)
                text: root.displayKind === "brightness" ? "brt" : "vol"
                color: Theme.moduleLabel
                renderType: Text.NativeRendering
                font {
                    family: ShellConfig.typography.monoFamily
                    styleName: ShellConfig.typography.fineStyle
                    pixelSize: ShellConfig.scaled(11)
                    weight: Font.DemiBold
                }
            }

            Item {
                id: track

                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(ShellConfig.scaled(48),
                    content.width - glyph.width - label.width - value.width
                        - content.spacing * 3)
                height: ShellConfig.scaled(7)

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Theme.separator
                    opacity: 0.58
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: parent.width * root.progressValue
                    radius: height / 2
                    color: root.accent

                    Behavior on width {
                        NumberAnimation {
                            duration: FloralSettings.duration(120)
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            Text {
                id: value

                anchors.verticalCenter: parent.verticalCenter
                width: ShellConfig.scaled(42)
                text: root.displayKind === "volume" && root.displayMuted
                    ? "muted"
                    : `${Math.round(root.displayValue * 100)}%`
                color: root.displayKind === "volume" && root.displayMuted
                    ? Theme.statusDanger
                    : Theme.moduleValue
                horizontalAlignment: Text.AlignRight
                renderType: Text.NativeRendering
                font {
                    family: ShellConfig.typography.monoFamily
                    pixelSize: ShellConfig.scaled(11)
                    weight: Font.DemiBold
                }
            }
        }
    }
}
