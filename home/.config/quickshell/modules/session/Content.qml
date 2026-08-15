pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.Services
import qs
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Column {
    id: root

    required property ScreenState screenState
    readonly property real menuScale: ShellConfig.uiScale
        * ShellConfig.bar.powerMenuScale
    readonly property real menuWidth: ShellConfig.bar.powerMenuWidth
    property bool sessionImageAvailable: false

    padding: ShellConfig.bar.powerMenuPadding
    rightPadding: CUtils.clamp(padding - Config.border.thickness, 0, padding)
    spacing: ShellConfig.bar.powerMenuSpacing

    Process {
        command: ["test", "-r", Quickshell.shellPath("session_img.png")]
        running: true
        onExited: code => root.sessionImageAvailable = code === 0
    }

    Item {
        width: root.menuWidth
        height: ShellConfig.bar.powerMenuHeaderHeight

        Text {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
            }
            text: "power"
            color: Theme.moduleValue
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                styleName: ShellConfig.typography.fineStyle
                pixelSize: ShellConfig.bar.powerMenuActionTitleSize + 5
                letterSpacing: ShellConfig.bar.labelLetterSpacing * 1.25
            }
        }

        Text {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: ShellConfig.bar.powerMenuActionTitleSize + 10
            }
            text: "choose an action"
            color: Theme.moduleLabel
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                styleName: ShellConfig.typography.fineStyle
                pixelSize: ShellConfig.bar.powerMenuActionDetailSize
                letterSpacing: ShellConfig.bar.labelLetterSpacing
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
                height: ShellConfig.bar.hairlineThickness
                color: Theme.frameBorderFaint
            }

            Rectangle {
                anchors.centerIn: parent
                width: ShellConfig.bar.separatorDiamondSize
                height: width
                rotation: 45
                color: Theme.panel
                border.width: ShellConfig.bar.hairlineThickness
                border.color: Theme.frameBorderSoft
            }
        }
    }

    SessionButton {
        id: logout

        icon: Config.session.icons.logout
        title: "sign out"
        detail: "end this session"
        accent: Theme.accentSecondary
        actionName: "logout"

        KeyNavigation.down: shutdown

        Component.onCompleted: forceActiveFocus()

        Connections {
            function onSessionChanged(): void {
                if (root.screenState.session)
                    Qt.callLater(() => logout.forceActiveFocus());
            }

            target: root.screenState
        }
    }

    SessionButton {
        id: shutdown

        icon: Config.session.icons.shutdown
        title: "power off"
        detail: "turn off this computer"
        accent: Theme.statusDanger
        actionName: "poweroff"

        KeyNavigation.up: logout
        KeyNavigation.down: hibernate
    }

    Item {
        width: root.menuWidth
        height: ShellConfig.bar.powerMenuImageHeight

        RectangularShadow {
            anchors.fill: imageFrame
            radius: imageFrame.radius
            blur: ShellConfig.scaled(14)
            spread: 0
            offset: Qt.vector2d(0, ShellConfig.scaled(3))
            color: Theme.shadowSoft
            cached: true
        }

        Rectangle {
            id: imageFrame

            anchors.fill: parent
            radius: ShellConfig.bar.powerImageCornerRadius
            color: Theme.panelRaised
            border.width: ShellConfig.bar.powerMenuButtonBorderWidth
            border.color: Theme.frameBorder

            StyledClippingRect {
                anchors {
                    fill: parent
                    margins: ShellConfig.scaled(4)
                }
                radius: Math.max(0, imageFrame.radius - ShellConfig.scaled(4))
                color: "transparent"

                Image {
                    id: sessionImage

                    anchors.fill: parent
                    sourceSize.width: width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)
                    sourceSize.height: height * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)
                    asynchronous: true
                    source: root.sessionImageAvailable
                        ? Quickshell.shellPath("session_img.png") : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    mipmap: true
                    visible: status === Image.Ready
                    scale: root.screenState.session ? 1.035 : 1.09

                    Behavior on scale {
                        Anim {
                            type: Anim.SlowSpatial
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    visible: sessionImage.status !== Image.Ready
                    color: Theme.panelHighlight

                    FloralCorner {
                        anchors {
                            left: parent.left
                            top: parent.top
                        }
                        width: parent.height * 0.84
                        height: width
                        location: FloralCorner.TopLeft
                        strength: 0.62
                    }

                    FloralCorner {
                        anchors {
                            right: parent.right
                            bottom: parent.bottom
                        }
                        width: parent.height * 0.84
                        height: width
                        location: FloralCorner.BottomRight
                        strength: 0.62
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width * 0.34
                        height: ShellConfig.bar.hairlineThickness
                        color: Theme.frameBorderSoft
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: ShellConfig.bar.separatorDiamondSize
                        height: width
                        rotation: 45
                        color: Theme.panelHighlight
                        border.width: ShellConfig.bar.hairlineThickness
                        border.color: Theme.moduleLabel
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: ShellConfig.scaled(7)
                radius: Math.max(0, parent.radius - ShellConfig.scaled(7))
                color: "transparent"
                border.width: ShellConfig.bar.hairlineThickness
                border.color: Theme.frameBorderFaint
            }
        }
    }

    SessionButton {
        id: hibernate

        icon: Config.session.icons.hibernate
        title: "hibernate"
        detail: "save session to disk"
        accent: Theme.accentTertiary
        actionName: "hibernate"

        KeyNavigation.up: shutdown
        KeyNavigation.down: reboot
    }

    SessionButton {
        id: reboot

        icon: Config.session.icons.reboot
        title: "restart"
        detail: "restart this computer"
        accent: Theme.statusWarning
        actionName: "reboot"

        KeyNavigation.up: hibernate
    }

    Item {
        width: root.menuWidth
        height: ShellConfig.bar.separatorDiamondSize + 2

        Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: ShellConfig.bar.hairlineThickness
            color: Theme.frameBorderFaint
        }

        Rectangle {
            anchors.centerIn: parent
            width: ShellConfig.bar.separatorDiamondSize
            height: width
            rotation: 45
            color: Theme.panel
            border.width: ShellConfig.bar.hairlineThickness
            border.color: Theme.frameBorderSoft
        }
    }

    Text {
        width: root.menuWidth
        text: "esc to close"
        color: Theme.textMuted
        horizontalAlignment: Text.AlignHCenter
        renderType: Text.NativeRendering
        font {
            family: ShellConfig.typography.monoFamily
            styleName: ShellConfig.typography.fineStyle
            pixelSize: ShellConfig.bar.powerMenuActionDetailSize
            letterSpacing: ShellConfig.bar.labelLetterSpacing
        }
    }

    component SessionButton: ButtonBase {
        id: button

        required property string actionName
        required property string icon
        required property string title
        required property string detail
        required property color accent

        function activate(): void {
            root.screenState.session = false;

            switch (actionName) {
            case "logout":
                SessionManager.logout();
                break;
            case "poweroff":
                SessionManager.poweroff();
                break;
            case "hibernate":
                SessionManager.hibernate();
                break;
            case "reboot":
                SessionManager.reboot();
                break;
            default:
                console.warn(`Unknown session action: ${actionName}`);
            }
        }

        width: root.menuWidth
        height: ShellConfig.bar.powerMenuActionHeight
        implicitWidth: root.menuWidth
        implicitHeight: ShellConfig.bar.powerMenuActionHeight

        inactiveColour: activeFocus || hovered
            ? Theme.panelHighlight : Theme.panelRaised
        inactiveOnColour: button.accent
        activeColour: Theme.panelHighlight
        activeOnColour: button.accent
        radius: pressed ? pressedRadius : defaultRadius
        defaultRadius: ShellConfig.bar.powerMenuActionRadius
        pressedRadius: Math.max(0, ShellConfig.bar.powerMenuActionRadius - 4)
        checkedRadius: ShellConfig.bar.powerMenuActionRadius
        border.width: ShellConfig.bar.powerMenuButtonBorderWidth
        border.color: activeFocus || hovered
            ? Theme.frameBorder
            : Theme.frameBorderFaint
        scale: pressed ? ShellConfig.visuals.pressedScale
            : hovered || activeFocus ? 1.012 : 1

        onClicked: activate()

        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: ShellConfig.scaled(4)
            radius: Math.max(0, button.radius - ShellConfig.scaled(4))
            color: "transparent"
            border.width: ShellConfig.bar.hairlineThickness
            border.color: button.hovered || button.activeFocus
                ? Theme.frameBorderSoft : Theme.frameBorderFaint
        }

        Rectangle {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: ShellConfig.scaled(4)
            }
            width: ShellConfig.frame.lineThickness
            height: button.hovered || button.activeFocus
                ? parent.height * 0.48 : parent.height * 0.22
            radius: width / 2
            color: button.accent

            Behavior on height {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        Row {
            anchors {
                fill: parent
                leftMargin: ShellConfig.bar.powerMenuPadding - 2
                rightMargin: ShellConfig.bar.powerMenuPadding
                    + ShellConfig.scaled(14)
            }
            spacing: ShellConfig.bar.powerMenuIconTextGap

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: ShellConfig.bar.powerMenuActionIconSize + 6
                height: width

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + ShellConfig.scaled(10)
                    height: width
                    radius: ShellConfig.visuals.controlRadius
                    color: button.hovered || button.activeFocus
                        ? Theme.accentWashStrong : Theme.accentWash
                    border.width: ShellConfig.bar.hairlineThickness
                    border.color: button.hovered || button.activeFocus
                        ? button.accent : Theme.frameBorderFaint
                    scale: button.pressed ? 0.9 : 1

                    Behavior on scale {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: button.icon
                    color: button.accent
                    fontStyle: Tokens.font.icon.builders.large
                        .scale(1.05 * root.menuScale).build()
                    fill: button.activeFocus || button.hovered ? 1 : 0
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: button.title
                    color: Theme.moduleValue
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        styleName: ShellConfig.typography.fineStyle
                        pixelSize: ShellConfig.bar.powerMenuActionTitleSize
                        letterSpacing: ShellConfig.bar.labelLetterSpacing * 0.5
                    }
                }

                Text {
                    text: button.detail
                    color: Theme.textMuted
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        pixelSize: ShellConfig.bar.powerMenuActionDetailSize
                    }
                }
            }
        }

        Item {
            anchors {
                right: parent.right
                rightMargin: button.hovered || button.activeFocus
                    ? ShellConfig.scaled(13) : ShellConfig.scaled(16)
                verticalCenter: parent.verticalCenter
            }
            width: ShellConfig.scaled(9)
            height: ShellConfig.scaled(14)
            opacity: button.hovered || button.activeFocus ? 1 : 0.35

            Rectangle {
                anchors {
                    right: parent.right
                    top: parent.top
                }
                width: ShellConfig.scaled(7)
                height: ShellConfig.bar.hairlineThickness
                rotation: 45
                transformOrigin: Item.Right
                color: button.accent
            }

            Rectangle {
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                }
                width: ShellConfig.scaled(7)
                height: ShellConfig.bar.hairlineThickness
                rotation: -45
                transformOrigin: Item.Right
                color: button.accent
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on anchors.rightMargin {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        Keys.onEnterPressed: activate()
        Keys.onReturnPressed: activate()
        Keys.onEscapePressed: root.screenState.session = false
        Keys.onPressed: event => {
            if (!Config.session.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if ((event.key === Qt.Key_J || event.key === Qt.Key_N) && KeyNavigation.down) {
                    KeyNavigation.down.focus = true;
                    event.accepted = true;
                } else if ((event.key === Qt.Key_K || event.key === Qt.Key_P) && KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab && KeyNavigation.down) {
                KeyNavigation.down.focus = true;
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab
                    || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                if (KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            }
        }
    }
}
