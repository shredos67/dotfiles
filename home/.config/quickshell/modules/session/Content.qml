pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
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

    padding: ShellConfig.bar.powerMenuPadding
    rightPadding: CUtils.clamp(padding - Config.border.thickness, 0, padding)
    spacing: ShellConfig.bar.powerMenuSpacing

    Item {
        width: root.menuWidth
        height: ShellConfig.bar.powerMenuHeaderHeight

        Text {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
            }
            text: "Power Menu"
            color: Theme.moduleLabel
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                styleName: ShellConfig.typography.fineStyle
                pixelSize: ShellConfig.bar.powerMenuActionTitleSize + 5
                letterSpacing: ShellConfig.bar.labelLetterSpacing * 1.5
            }
        }

        //Text {
        //    anchors {
        //        horizontalCenter: parent.horizontalCenter
        //        top: parent.top
        //        topMargin: ShellConfig.bar.powerMenuActionTitleSize + 9
        //    }
        //    text: "options"
        //    color: Theme.textMuted
        //    renderType: Text.NativeRendering
        //    font {
        //        family: ShellConfig.typography.monoFamily
        //        styleName: ShellConfig.typography.fineStyle
        //        pixelSize: ShellConfig.bar.powerMenuActionDetailSize
        //        letterSpacing: ShellConfig.bar.labelLetterSpacing
        //    }
        //}

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
        title: "Sign out"
        detail: "End this session"
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
        title: "Power off"
        detail: "Shutdown computer"
        accent: Theme.statusDanger
        actionName: "poweroff"

        KeyNavigation.up: logout
        KeyNavigation.down: hibernate
    }

    Item {
        width: root.menuWidth
        height: ShellConfig.bar.powerMenuImageHeight

        Rectangle {
            anchors.fill: parent
            radius: 0
            color: Theme.panelRaised
            border.width: ShellConfig.bar.hairlineThickness
            border.color: Theme.frameBorderSoft

            StyledClippingRect {
                anchors {
                    fill: parent
                    margins: 3
                }
                radius: 0
                color: "transparent"

                Image {
                    anchors.fill: parent
                    sourceSize.width: width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)
                    sourceSize.height: height * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)
                    asynchronous: true
                    source: Quickshell.shellPath("session_img.png")
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    mipmap: true
                }
            }
        }
    }

    SessionButton {
        id: hibernate

        icon: Config.session.icons.hibernate
        title: "Hibernate"
        detail: "Sleep computer"
        accent: Theme.accentTertiary
        actionName: "hibernate"

        KeyNavigation.up: shutdown
        KeyNavigation.down: reboot
    }

    SessionButton {
        id: reboot

        icon: Config.session.icons.reboot
        title: "Restart"
        detail: "Reboot computer"
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
        text: "esc  ·  close"
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

        inactiveColour: activeFocus ? Theme.panelHighlight : Theme.panelRaised
        inactiveOnColour: button.accent
        activeColour: Theme.panelHighlight
        activeOnColour: button.accent
        radius: 0
        defaultRadius: ShellConfig.bar.powerMenuActionRadius
        pressedRadius: Math.max(0, ShellConfig.bar.powerMenuActionRadius - 4)
        checkedRadius: ShellConfig.bar.powerMenuActionRadius
        border.width: ShellConfig.bar.powerMenuButtonBorderWidth
        border.color: activeFocus || hovered
            ? Theme.frameBorder
            : Theme.frameBorderFaint

        onClicked: activate()

        Row {
            anchors {
                fill: parent
                leftMargin: ShellConfig.bar.powerMenuPadding - 2
                rightMargin: ShellConfig.bar.powerMenuPadding - 2
            }
            spacing: ShellConfig.bar.powerMenuIconTextGap

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                width: ShellConfig.bar.powerMenuActionIconSize + 6
                text: button.icon
                color: button.accent
                fontStyle: Tokens.font.icon.builders.large
                    .scale(1.05 * root.menuScale).build()
                fill: button.activeFocus || button.hovered ? 1 : 0
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
