pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Caelestia.Config
import qs.components

StyledClippingRect {
    id: root

    required property var notification
    property bool popupMode
    property bool animateEntrance: true
    property bool expanded

    readonly property int cardPadding: ShellConfig.notifications.cardPadding
    readonly property bool hasBody: (notification?.body ?? "").trim().length > 0
    readonly property bool hasActions: (notification?.actions?.length ?? 0) > 0
    readonly property bool hasImage: (notification?.image ?? "").length > 0
    readonly property bool hasAppIcon: (notification?.appIcon ?? "").length > 0
    readonly property bool bodyExpandable: !popupMode && hasBody
        && (expanded || bodyText.truncated)
    readonly property color accent: notification?.urgency === 2
        ? Theme.statusDanger
        : notification?.urgency === 0 ? Theme.accentTertiary : Theme.accentPrimary

    width: parent?.width ?? implicitWidth
    implicitWidth: ShellConfig.notifications.toastWidth
    implicitHeight: content.implicitHeight + cardPadding * 2 + 4
    radius: ShellConfig.notifications.cardRadius
    color: Theme.panelRaised
    border.width: ShellConfig.notifications.borderWidth
    border.color: notification?.urgency === 2
        ? Theme.statusDanger
        : Theme.frameBorderSoft
    contentUnderBorder: true
    layer.enabled: root.popupMode && FloralSettings.shadows
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Theme.shadowColor
        shadowOpacity: ShellConfig.visuals.shadowOpacity
        shadowBlur: 0.82
        shadowVerticalOffset: ShellConfig.visuals.shadowOffsetY
        blurMax: ShellConfig.visuals.shadowBlur
    }

    Component.onCompleted: {
        if (!notification)
            return;
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
    Component.onDestruction: {
        if (notification)
            notification.unlock(root);
    }

    Behavior on x { Anim {} }

    Behavior on scale {
        NumberAnimation {
            duration: ShellConfig.notifications.animationMs
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        Anim { type: Anim.DefaultEffects }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: ShellConfig.visuals.motionNormal
            easing.type: Easing.OutCubic
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
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

    FloralCorner {
        anchors {
            right: parent.right
            top: parent.top
        }
        width: Math.min(root.width * 0.32,
            ShellConfig.notifications.notificationOrnamentSize * 0.72)
        height: width
        location: FloralCorner.TopRight
        strength: root.popupMode ? 0.28 : 0.2
    }

    FloralCorner {
        anchors {
            left: parent.left
            bottom: parent.bottom
        }
        width: Math.min(root.width * 0.26,
            ShellConfig.notifications.notificationOrnamentSize * 0.58)
        height: width
        location: FloralCorner.BottomLeft
        strength: root.popupMode ? 0.18 : 0.12
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
        radius: Math.max(0, root.radius
            - Math.max(4, ShellConfig.notifications.panelInnerInset - 2))
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

            StyledClippingRect {
                id: iconFrame

                width: ShellConfig.notifications.iconSize
                height: width
                anchors.verticalCenter: parent.verticalCenter
                radius: ShellConfig.visuals.controlRadius
                color: Theme.panel
                border.width: ShellConfig.notifications.borderWidth
                border.color: root.accent
                contentUnderBorder: true

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: Math.max(0, iconFrame.radius - 4)
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.frameBorderFaint
                }

                Image {
                    id: notificationImage

                    anchors.fill: parent
                    anchors.margins: root.hasImage ? 2 : Math.round(parent.width * 0.18)
                    source: root.hasImage
                        ? Qt.resolvedUrl(root.notification?.image ?? "")
                        : root.hasAppIcon
                            ? Quickshell.iconPath(root.notification?.appIcon ?? "", true)
                            : ""
                    fillMode: root.hasImage ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    mipmap: true
                }

                CardGlyph {
                    anchors.centerIn: parent
                    width: Math.round(iconFrame.width * 0.48)
                    height: width
                    visible: !root.hasImage
                        && (!root.hasAppIcon || notificationImage.status === Image.Error)
                    kind: "notification"
                    glyphColor: root.accent
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
                    text: (root.notification?.summary || "notification").toLowerCase()
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
                    text: `${root.notification?.appName || "system"}  ·  ${root.notification?.timeStr || "now"}`.toLowerCase()
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
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: ShellConfig.visuals.controlRadius
                    color: closePointer.containsMouse ? Theme.panelHighlight : Theme.panel
                    border.width: ShellConfig.notifications.borderWidth
                    border.color: closePointer.containsMouse
                        ? root.accent : Theme.frameBorderFaint
                }

                CardGlyph {
                    anchors.centerIn: parent
                    width: Math.round(closeButton.width * 0.39)
                    height: width
                    kind: "close"
                    glyphColor: closePointer.containsMouse
                        ? Theme.moduleValue : Theme.textMuted
                }

                MouseArea {
                    id: closePointer

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.notification)
                            root.notification.close();
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: ShellConfig.bar.separatorDiamondSize + 2
            visible: root.hasBody

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: ShellConfig.notifications.borderWidth
                color: Theme.frameBorderFaint
            }

            Rectangle {
                anchors.centerIn: parent
                width: ShellConfig.bar.separatorDiamondSize
                height: width
                rotation: 45
                color: Theme.panelRaised
                border.width: ShellConfig.bar.hairlineThickness
                border.color: root.accent
            }
        }

        Text {
            id: bodyText

            width: parent.width
            visible: root.hasBody
            text: (root.notification?.body ?? "").toLowerCase()
            color: Theme.textMuted
            textFormat: /[<>]/.test(text) ? Text.StyledText : Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: root.popupMode ? 3 : root.expanded ? 1000 : 7
            elide: root.expanded ? Text.ElideNone : Text.ElideRight
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                pixelSize: ShellConfig.notifications.bodySize
            }
        }

        Row {
            width: parent.width
            height: visible ? ShellConfig.notifications.actionHeight : 0
            visible: !root.popupMode && root.hasBody
            spacing: Math.round(ShellConfig.notifications.cardSpacing * 0.65)
            layoutDirection: Qt.RightToLeft

            CardToolButton {
                label: "copy"
                icon: "copy"
                onTriggered: Quickshell.clipboardText
                    = root.notification?.body ?? ""
            }

            CardToolButton {
                visible: root.bodyExpandable
                label: root.expanded ? "less" : "more"
                icon: "expand"
                iconRotation: root.expanded ? 180 : 0
                onTriggered: root.expanded = !root.expanded
            }
        }

        Flow {
            width: parent.width
            visible: root.hasActions
            height: visible ? implicitHeight : 0
            spacing: Math.round(ShellConfig.notifications.cardSpacing * 0.65)

            Repeater {
                model: root.notification?.actions ?? []

                delegate: Rectangle {
                    id: actionButton

                    required property var modelData

                    width: actionLabel.implicitWidth + ShellConfig.notifications.cardPadding * 1.5
                    height: ShellConfig.notifications.actionHeight
                    radius: ShellConfig.visuals.controlRadius
                    color: actionPointer.containsMouse ? Theme.panelHighlight : Theme.panel
                    border.width: ShellConfig.notifications.borderWidth
                    border.color: actionPointer.containsMouse
                        ? root.accent : Theme.frameBorderFaint
                    scale: actionPointer.pressed ? 0.94
                        : actionPointer.containsMouse ? 1.025 : 1

                    Behavior on scale {
                        NumberAnimation {
                            duration: ShellConfig.bar.menuAnimationMs
                            easing.type: Easing.OutCubic
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
                            if (root.notification)
                                root.notification.popup = false;
                        }
                    }
                }
            }
        }
    }

    HoverHandler {
        onHoveredChanged: {
            const activeNotification = root.notification;
            if (!root.popupMode || !activeNotification)
                return;
            if (hovered)
                activeNotification.timer.stop();
            else
                activeNotification.timer.start();
        }
    }

    component CardToolButton: Rectangle {
        id: toolButton

        required property string label
        required property string icon
        property real iconRotation
        signal triggered

        width: toolContent.implicitWidth
            + ShellConfig.notifications.cardPadding * 1.2
        height: ShellConfig.notifications.actionHeight
        radius: ShellConfig.visuals.controlRadius
        color: toolPointer.containsMouse ? Theme.panelHighlight : Theme.panel
        border.width: ShellConfig.notifications.borderWidth
        border.color: toolPointer.containsMouse
            ? root.accent : Theme.frameBorderFaint
        scale: toolPointer.pressed ? 0.94
            : toolPointer.containsMouse ? 1.025 : 1

        Behavior on scale {
            NumberAnimation {
                duration: ShellConfig.bar.menuAnimationMs
                easing.type: Easing.OutCubic
            }
        }

        Row {
            id: toolContent

            anchors.centerIn: parent
            spacing: Math.round(ShellConfig.notifications.cardSpacing * 0.5)
            layoutDirection: Qt.LeftToRight

            CardGlyph {
                width: Math.round(ShellConfig.notifications.metaSize * 1.15)
                height: width
                anchors.verticalCenter: parent.verticalCenter
                kind: toolButton.icon
                glyphColor: toolPointer.containsMouse
                    ? Theme.moduleValue : Theme.textMuted
                rotation: toolButton.iconRotation

                Behavior on rotation {
                    NumberAnimation {
                        duration: ShellConfig.visuals.motionFast
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: toolButton.label
                color: Theme.moduleValue
                renderType: Text.NativeRendering
                font {
                    family: ShellConfig.typography.monoFamily
                    styleName: ShellConfig.typography.fineStyle
                    pixelSize: ShellConfig.notifications.metaSize
                }
            }
        }

        MouseArea {
            id: toolPointer

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: toolButton.triggered()
        }
    }

    component CardGlyph: Canvas {
        id: glyph

        required property string kind
        property color glyphColor: Theme.moduleValue
        property real glyphStroke: Math.max(1.35, width / 9)

        antialiasing: true

        onKindChanged: requestPaint()
        onGlyphColorChanged: requestPaint()
        onGlyphStrokeChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const context = getContext("2d");
            const size = Math.min(width, height);
            const left = (width - size) / 2;
            const top = (height - size) / 2;
            const x = value => left + value * size;
            const y = value => top + value * size;

            context.reset();
            context.strokeStyle = glyph.glyphColor;
            context.fillStyle = glyph.glyphColor;
            context.lineWidth = glyph.glyphStroke;
            context.lineCap = "round";
            context.lineJoin = "round";

            if (glyph.kind === "notification") {
                context.beginPath();
                context.moveTo(x(0.2), y(0.72));
                context.quadraticCurveTo(x(0.32), y(0.6), x(0.32), y(0.39));
                context.bezierCurveTo(x(0.32), y(0.16), x(0.68), y(0.16),
                    x(0.68), y(0.39));
                context.quadraticCurveTo(x(0.68), y(0.6), x(0.8), y(0.72));
                context.closePath();
                context.stroke();
                context.beginPath();
                context.arc(x(0.5), y(0.78), size * 0.085, 0, Math.PI);
                context.stroke();
            } else if (glyph.kind === "close") {
                context.beginPath();
                context.moveTo(x(0.2), y(0.2));
                context.lineTo(x(0.8), y(0.8));
                context.moveTo(x(0.8), y(0.2));
                context.lineTo(x(0.2), y(0.8));
                context.stroke();
            } else if (glyph.kind === "copy") {
                context.strokeRect(x(0.3), y(0.16), size * 0.54, size * 0.58);
                context.strokeRect(x(0.16), y(0.3), size * 0.54, size * 0.58);
            } else if (glyph.kind === "expand") {
                context.beginPath();
                context.moveTo(x(0.17), y(0.35));
                context.lineTo(x(0.5), y(0.68));
                context.lineTo(x(0.83), y(0.35));
                context.stroke();
            }
        }
    }
}
