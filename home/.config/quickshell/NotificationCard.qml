pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components

Rectangle {
    id: root

    required property var notification
    property bool popupMode
    property bool animateEntrance: true

    readonly property int cardPadding: ShellConfig.notifications.cardPadding
    readonly property bool hasBody: (notification.body ?? "").trim().length > 0
    readonly property bool hasActions: (notification.actions?.length ?? 0) > 0
    readonly property bool hasImage: (notification.image ?? "").length > 0
    readonly property bool hasAppIcon: (notification.appIcon ?? "").length > 0
    readonly property color accent: notification.urgency === 2
        ? Theme.statusDanger
        : notification.urgency === 0 ? Theme.accentTertiary : Theme.accentPrimary

    width: parent?.width ?? implicitWidth
    implicitWidth: ShellConfig.notifications.toastWidth
    implicitHeight: content.implicitHeight + cardPadding * 2 + 4
    radius: 0
    color: Theme.panelRaised
    border.width: ShellConfig.notifications.borderWidth
    border.color: notification.urgency === 2
        ? Theme.statusDanger
        : Theme.frameBorderSoft
    clip: true

    Component.onCompleted: {
        notification.lock(root);
        if (animateEntrance) {
            root.x = -Math.round(root.width * 0.16);
            root.scale = 0.965;
            root.opacity = 0;
            Qt.callLater(() => {
                root.x = 0;
                root.scale = 1;
                root.opacity = 1;
            });
        }
    }
    Component.onDestruction: notification.unlock(root)

    Behavior on x { Anim {} }

    Behavior on scale {
        NumberAnimation {
            duration: ShellConfig.notifications.animationMs
            easing.type: Easing.OutBack
            easing.overshoot: 0.7
        }
    }

    Behavior on opacity {
        Anim { type: Anim.DefaultEffects }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.panelHighlight }
            GradientStop { position: 0.36; color: Theme.panelRaised }
            GradientStop { position: 1; color: Theme.panel }
        }
        opacity: 0.72
    }

    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            margins: ShellConfig.notifications.borderWidth
        }
        width: 3
        color: root.accent
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: Math.max(4, ShellConfig.notifications.panelInnerInset - 2)
        color: "transparent"
        radius: 0
        border.width: ShellConfig.notifications.borderWidth
        border.color: Theme.frameBorderFaint
    }

    Column {
        id: content

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: root.cardPadding
            leftMargin: root.cardPadding + 5
        }
        spacing: ShellConfig.notifications.cardSpacing

        Row {
            width: parent.width
            height: Math.max(iconFrame.height, heading.implicitHeight, closeButton.height)
            spacing: ShellConfig.notifications.cardSpacing

            Rectangle {
                id: iconFrame

                width: ShellConfig.notifications.iconSize
                height: width
                anchors.verticalCenter: parent.verticalCenter
                radius: 0
                color: Theme.panel
                border.width: ShellConfig.notifications.borderWidth
                border.color: root.accent
                clip: true

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 0
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.frameBorderFaint
                }

                Image {
                    id: notificationImage

                    anchors.fill: parent
                    anchors.margins: root.hasImage ? 2 : Math.round(parent.width * 0.18)
                    source: root.hasImage
                        ? Qt.resolvedUrl(root.notification.image)
                        : root.hasAppIcon
                            ? Quickshell.iconPath(root.notification.appIcon, true)
                            : ""
                    fillMode: root.hasImage ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    mipmap: true
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: !root.hasImage
                        && (!root.hasAppIcon || notificationImage.status === Image.Error)
                    text: "notifications"
                    color: root.accent
                    fontStyle: Tokens.font.icon.builders.medium.scale(1.15).build()
                }
            }

            Column {
                id: heading

                width: parent.width - iconFrame.width - closeButton.width
                    - parent.spacing * 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    width: parent.width
                    text: (root.notification.summary || "notification").toLowerCase()
                    color: Theme.moduleValue
                    elide: Text.ElideRight
                    maximumLineCount: root.popupMode ? 1 : 2
                    wrapMode: Text.Wrap
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        styleName: ShellConfig.typography.fineStyle
                        pixelSize: ShellConfig.notifications.titleSize
                    }
                }

                Text {
                    width: parent.width
                    text: `${root.notification.appName || "system"}  ·  ${root.notification.timeStr || "now"}`.toLowerCase()
                    color: Theme.moduleLabel
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        pixelSize: ShellConfig.notifications.metaSize
                        letterSpacing: ShellConfig.bar.labelLetterSpacing * 0.35
                    }
                }
            }

            Item {
                id: closeButton

                width: ShellConfig.notifications.closeButtonSize
                height: width
                anchors.verticalCenter: parent.verticalCenter
                scale: closePointer.pressed ? 0.86
                    : closePointer.containsMouse ? 1.08 : 1

                Behavior on scale {
                    NumberAnimation {
                        duration: ShellConfig.bar.menuAnimationMs
                        easing.type: Easing.OutBack
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 0
                    color: closePointer.containsMouse ? Theme.panelHighlight : Theme.panel
                    border.width: ShellConfig.notifications.borderWidth
                    border.color: closePointer.containsMouse
                        ? root.accent : Theme.frameBorderFaint
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "close"
                    color: closePointer.containsMouse ? Theme.moduleValue : Theme.textMuted
                    fontStyle: Tokens.font.icon.medium
                }

                MouseArea {
                    id: closePointer

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.notification.close()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 2
            visible: root.hasBody
            color: Theme.frameBorderFaint
        }

        Text {
            width: parent.width
            visible: root.hasBody
            text: (root.notification.body ?? "").toLowerCase()
            color: Theme.textMuted
            textFormat: /[<>]/.test(text) ? Text.StyledText : Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: root.popupMode ? 3 : 7
            elide: Text.ElideRight
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                pixelSize: ShellConfig.notifications.bodySize
            }
        }

        Flow {
            width: parent.width
            visible: root.hasActions
            height: visible ? implicitHeight : 0
            spacing: Math.round(ShellConfig.notifications.cardSpacing * 0.65)

            Repeater {
                model: root.notification.actions ?? []

                delegate: Rectangle {
                    id: actionButton

                    required property var modelData

                    width: actionLabel.implicitWidth + ShellConfig.notifications.cardPadding * 1.5
                    height: ShellConfig.notifications.actionHeight
                    radius: 0
                    color: actionPointer.containsMouse ? Theme.panelHighlight : Theme.panel
                    border.width: ShellConfig.notifications.borderWidth
                    border.color: actionPointer.containsMouse
                        ? root.accent : Theme.frameBorderFaint
                    scale: actionPointer.pressed ? 0.94
                        : actionPointer.containsMouse ? 1.025 : 1

                    Behavior on scale {
                        NumberAnimation {
                            duration: ShellConfig.bar.menuAnimationMs
                            easing.type: Easing.OutBack
                        }
                    }

                    Text {
                        id: actionLabel

                        anchors.centerIn: parent
                        text: (actionButton.modelData.text || "open").toLowerCase()
                        color: Theme.moduleValue
                        renderType: Text.NativeRendering
                        font {
                            family: ShellConfig.typography.monoFamily
                            styleName: ShellConfig.typography.fineStyle
                            pixelSize: ShellConfig.notifications.metaSize
                        }
                    }

                    MouseArea {
                        id: actionPointer

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            actionButton.modelData.invoke();
                            root.notification.popup = false;
                        }
                    }
                }
            }
        }
    }

    HoverHandler {
        onHoveredChanged: {
            if (!root.popupMode)
                return;
            if (hovered)
                root.notification.timer.stop();
            else
                root.notification.timer.start();
        }
    }
}
