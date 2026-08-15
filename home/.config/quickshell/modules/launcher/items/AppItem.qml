import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs
import qs.components
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    required property DesktopEntry modelData
    required property ScreenState screenState

    readonly property string appName: String(modelData?.name ?? "app")
    readonly property string appId: String(modelData?.id
        ?? modelData?.name ?? "app")
    readonly property string iconName: String(modelData?.icon ?? "").trim()
    readonly property bool hasSpecificIcon: iconName.length > 0
        && !isGenericIcon(iconName)
    readonly property bool realIconReady: hasSpecificIcon
        && appIcon.status === Image.Ready
        && !isGenericIcon(String(appIcon.source))

    function isGenericIcon(icon) {
        const key = String(icon || "").toLowerCase();
        const generic = [
            "image-missing",
            "missing-image",
            "application-x-executable",
            "application-x-zerosize",
            "application-default-icon",
            "unknown-icon"
        ];
        return generic.some(name => key.includes(name));
    }

    function appColour(key) {
        const palette = [
            Theme.accentPrimary,
            Theme.accentSecondary,
            Theme.accentTertiary,
            Theme.moduleLabel
        ];
        const text = String(key || "app");
        let hash = 0;
        for (let index = 0; index < text.length; ++index)
            hash = (hash * 31 + text.charCodeAt(index)) >>> 0;
        return palette[hash % palette.length];
    }

    function monogram(name) {
        const words = String(name || "app").trim().split(/\s+/)
            .filter(word => word.length > 0);
        if (words.length > 1)
            return (words[0][0] + words[1][0]).toUpperCase();
        if (!words.length)
            return "·";

        const key = words[0].toLowerCase();
        const familiar = {
            firefox: "FX",
            foot: "FT",
            files: "FL",
            nautilus: "FL",
            legcord: "LC"
        };
        return familiar[key] || words[0].slice(0, 2).toUpperCase();
    }

    implicitHeight: ShellConfig.bar.launcherItemHeight
    scale: hitLayer.pressed ? 0.985 : hitLayer.containsMouse ? 1.006 : 1
    transformOrigin: Item.Center

    anchors.left: parent?.left
    anchors.right: parent?.right

    Behavior on scale {
        NumberAnimation {
            duration: FloralSettings.duration(130)
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: ShellConfig.bar.launcherItemRadius
        color: Theme.panelQuiet
        opacity: hitLayer.containsMouse ? 0.7 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: FloralSettings.duration(120)
                easing.type: Easing.OutCubic
            }
        }
    }

    StateLayer {
        id: hitLayer

        radius: ShellConfig.bar.launcherItemRadius
        onClicked: {
            Apps.launch(root.modelData);
            root.screenState.launcher = false;
        }
    }

    Item {
        anchors {
            fill: parent
            leftMargin: Tokens.padding.medium
            rightMargin: Tokens.padding.medium
            topMargin: Tokens.padding.small / 2
            bottomMargin: Tokens.padding.small / 2
        }

        RectangularShadow {
            anchors.fill: iconFrame
            visible: opacity > 0
            radius: iconFrame.radius
            blur: ShellConfig.scaled(12)
            spread: 0
            offset: Qt.vector2d(0, ShellConfig.scaled(2))
            color: Theme.frameGlow
            opacity: hitLayer.containsMouse ? 1 : 0
            cached: true

            Behavior on opacity {
                NumberAnimation {
                    duration: FloralSettings.duration(130)
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            id: iconFrame

            anchors.verticalCenter: parent.verticalCenter
            width: ShellConfig.bar.launcherIconFrameSize
            height: width
            radius: ShellConfig.visuals.controlRadius
            color: hitLayer.containsMouse
                ? Theme.panelHighlight : Theme.panelRaised
            border.width: ShellConfig.bar.buttonBorderWidth
            border.color: hitLayer.containsMouse
                ? Theme.frameBorder : Theme.frameBorderFaint
            scale: hitLayer.pressed ? 0.92 : hitLayer.containsMouse ? 1.06 : 1

            Rectangle {
                anchors.fill: parent
                anchors.margins: ShellConfig.scaled(3)
                radius: Math.max(0, parent.radius - ShellConfig.scaled(3))
                color: "transparent"
                border.width: ShellConfig.bar.hairlineThickness
                border.color: Theme.frameBorderFaint
            }

            Rectangle {
                id: fallbackTile

                anchors.fill: parent
                anchors.margins: ShellConfig.scaled(5)
                radius: Math.max(4, iconFrame.radius
                    - ShellConfig.scaled(5))
                color: FloralSettings.withAlpha(
                    root.appColour(root.appId), 0.18)
                border.width: ShellConfig.bar.hairlineThickness
                border.color: FloralSettings.withAlpha(
                    root.appColour(root.appId), 0.72)
                opacity: root.realIconReady ? 0 : 1
                scale: root.realIconReady ? 0.9 : 1

                FloralGlyph {
                    anchors.centerIn: parent
                    width: parent.width * 0.78
                    height: width
                    kind: "launcher"
                    color: root.appColour(root.appId)
                    opacity: 0.12
                }

                Text {
                    anchors.centerIn: parent
                    text: root.monogram(root.appName)
                    color: Theme.moduleValue
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        styleName: ShellConfig.typography.fineStyle
                        pixelSize: Math.max(ShellConfig.scaled(11),
                            parent.width * 0.36)
                        weight: Font.DemiBold
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: FloralSettings.duration(130)
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: FloralSettings.duration(150)
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: ShellConfig.visuals.motionFast
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: FloralSettings.duration(150)
                    easing.type: Easing.OutCubic
                }
            }
        }

        IconImage {
            id: appIcon

            anchors {
                left: parent.left
                leftMargin: (ShellConfig.bar.launcherIconFrameSize
                    - ShellConfig.bar.launcherAppIconSize) / 2
                verticalCenter: parent.verticalCenter
            }
            asynchronous: true
            source: root.hasSpecificIcon
                ? Quickshell.iconPath(root.iconName, "")
                : ""
            implicitSize: ShellConfig.bar.launcherAppIconSize
            z: 1
            opacity: root.realIconReady ? 1 : 0
            visible: opacity > 0
            scale: hitLayer.pressed ? 0.92 : hitLayer.containsMouse ? 1.04 : 1

            Behavior on opacity {
                NumberAnimation {
                    duration: FloralSettings.duration(130)
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: FloralSettings.duration(150)
                    easing.type: Easing.OutCubic
                }
            }
        }

        Item {
            anchors {
                left: iconFrame.right
                    right: trailingDetail.left
                leftMargin: Tokens.spacing.medium
                rightMargin: Tokens.spacing.small
                verticalCenter: iconFrame.verticalCenter
            }
            height: name.implicitHeight + comment.implicitHeight + 1

            Text {
                id: name

                width: parent.width
                text: root.modelData?.name ?? ""
                color: Theme.moduleValue
                elide: Text.ElideRight
                renderType: Text.NativeRendering
                font {
                    family: ShellConfig.typography.monoFamily
                    styleName: ShellConfig.typography.fineStyle
                    pixelSize: ShellConfig.bar.launcherNameSize
                    letterSpacing: ShellConfig.bar.labelLetterSpacing * 0.35
                }
            }

            Text {
                id: comment

                anchors.top: name.bottom
                width: parent.width
                text: (root.modelData?.comment || root.modelData?.genericName
                    || root.modelData?.name) ?? ""
                color: Theme.textMuted
                elide: Text.ElideRight
                renderType: Text.NativeRendering
                font {
                    family: ShellConfig.typography.monoFamily
                    pixelSize: ShellConfig.bar.launcherDetailSize
                }
            }
        }

        Item {
            id: trailingDetail

            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
            }
            width: ShellConfig.scaled(36)
            height: width

            FloralPinButton {
                anchors.centerIn: parent
                pinned: root.modelData
                    && FloralSettings.isPinned(root.modelData.id)
                z: 5
                onClicked: {
                    if (root.modelData)
                        FloralSettings.togglePin(root.modelData.id);
                }
            }
        }
    }
}
