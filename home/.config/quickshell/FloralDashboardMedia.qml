pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

Item {
    id: root

    required property bool active
    readonly property var player: Players.active
    readonly property real trackLength: player ? player.length : 0
    readonly property real trackPosition: player ? player.position : 0
    readonly property real progress: trackLength > 0
            && trackLength < 2147483647
        ? Math.max(0, Math.min(1, trackPosition / trackLength)) : 0

    function formatTime(seconds) {
        if (!isFinite(seconds) || seconds < 0 || seconds >= 2147483647)
            return "0:00";
        const whole = Math.floor(seconds);
        const minutes = Math.floor(whole / 60);
        const remainder = whole % 60;
        return `${minutes}:${remainder < 10 ? "0" : ""}${remainder}`;
    }

    function seek(ratio) {
        if (!player || !player.positionSupported || trackLength <= 0)
            return;
        player.position = Math.max(0, Math.min(1, ratio)) * trackLength;
    }

    Timer {
        interval: 500
        running: root.active && root.player
            ? root.player.isPlaying : false
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.player)
                root.player.positionChanged();
        }
    }

    Rectangle {
        id: artworkFrame

        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: Math.min(height, 430)
        radius: Math.max(15, FloralSettings.popupRadius + 5)
        color: Theme.panelRaised
        border.width: 2
        border.color: Theme.frameBorder
        clip: true

        Rectangle {
            anchors.fill: parent
            anchors.margins: 6
            radius: Math.max(9, parent.radius - 6)
            color: Theme.panelHighlight
            border.width: 1
            border.color: Theme.frameBorderFaint

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.42
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: Theme.frameBorderFaint

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.22
                    height: width
                    radius: width / 2
                    color: Theme.moduleLabel
                    opacity: 0.76
                }
            }

            Image {
                anchors.fill: parent
                source: Players.getArtUrl(root.player)
                asynchronous: true
                cache: true
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(width, height)
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: FloralSettings.duration(240)
                        easing.type: Easing.InOutCubic
                    }
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: 92
                color: FloralSettings.withAlpha(Theme.panel, 0.78)
            }

            SpectrumBars {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: 13
                }
                height: 58
                count: 26
                spacing: 3
                minimumLevel: 0.045
                levelGain: 0.92
                active: root.active
            }
        }
    }

    Item {
        id: content

        anchors {
            left: artworkFrame.right
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            leftMargin: 26
        }

        Text {
            id: pageLabel

            anchors {
                left: parent.left
                top: parent.top
                topMargin: 4
            }
            text: root.player
                ? Players.getIdentity(root.player).toLowerCase()
                : "media"
            color: Theme.moduleLabel
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                styleName: ShellConfig.typography.fineStyle
                pixelSize: 12
                weight: Font.DemiBold
                letterSpacing: 0.8
            }
        }

        Text {
            id: title

            anchors {
                left: parent.left
                right: parent.right
                top: pageLabel.bottom
                topMargin: 18
            }
            text: root.player
                ? (root.player.trackTitle || root.player.identity || "nothing playing")
                : "nothing playing"
            color: Theme.moduleValue
            elide: Text.ElideRight
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                styleName: ShellConfig.typography.fineStyle
                pixelSize: 27
                weight: Font.DemiBold
            }
        }

        Text {
            id: artist

            anchors {
                left: parent.left
                right: parent.right
                top: title.bottom
                topMargin: 7
            }
            text: root.player
                ? (root.player.trackArtist || root.player.trackAlbum || "") : ""
            color: Theme.textMuted
            elide: Text.ElideRight
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                styleName: ShellConfig.typography.fineStyle
                pixelSize: 14
            }
        }

        ListView {
            id: playerSelector

            anchors {
                left: parent.left
                right: parent.right
                top: artist.bottom
                topMargin: 24
            }
            height: 38
            orientation: ListView.Horizontal
            spacing: 7
            clip: true
            model: Players.list

            delegate: Rectangle {
                id: playerChoice

                required property var modelData
                readonly property bool selected: modelData === root.player
                width: Math.min(152, Math.max(78,
                    choiceText.implicitWidth + 28))
                height: 35
                radius: Math.max(8, FloralSettings.popupRadius * 0.72)
                color: selected
                    ? FloralSettings.withAlpha(FloralSettings.accentColor, 0.18)
                    : choicePointer.containsMouse
                        ? FloralSettings.elevatedColor
                        : FloralSettings.withAlpha(Theme.panelRaised, 0.50)
                border.width: selected ? 1.5 : 1
                border.color: selected
                    ? FloralSettings.accentColor : Theme.frameBorderFaint

                Text {
                    id: choiceText

                    anchors.centerIn: parent
                    width: parent.width - 20
                    text: Players.getIdentity(playerChoice.modelData).toLowerCase()
                    color: playerChoice.selected
                        ? Theme.moduleValue : Theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                    font {
                        family: ShellConfig.typography.monoFamily
                        styleName: ShellConfig.typography.fineStyle
                        pixelSize: 11
                        weight: playerChoice.selected
                            ? Font.DemiBold : Font.Normal
                    }
                }

                MouseArea {
                    id: choicePointer

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Players.manualActive = playerChoice.modelData
                }
            }
        }

        Item {
            id: timeline

            anchors {
                left: parent.left
                right: parent.right
                top: playerSelector.bottom
                topMargin: 30
            }
            height: 46

            Rectangle {
                id: track

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    topMargin: 3
                }
                height: 7
                radius: height / 2
                color: Theme.panelHighlight
                border.width: 1
                border.color: Theme.frameBorderFaint

                Rectangle {
                    width: parent.width * root.progress
                    height: parent.height
                    radius: parent.radius
                    color: FloralSettings.accentColor

                    Behavior on width {
                        NumberAnimation {
                            duration: timelinePointer.pressed
                                ? 0 : FloralSettings.duration(480)
                            easing.type: Easing.InOutCubic
                        }
                    }
                }

                Rectangle {
                    visible: timelinePointer.containsMouse
                    x: Math.max(0, Math.min(parent.width - width,
                        root.progress * parent.width - width / 2))
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                    height: width
                    radius: width / 2
                    color: Theme.moduleValue
                    border.width: 2
                    border.color: FloralSettings.accentColor
                }

                MouseArea {
                    id: timelinePointer

                    anchors {
                        fill: parent
                        topMargin: -8
                        bottomMargin: -8
                    }
                    enabled: root.player
                        ? root.player.positionSupported : false
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onPressed: event => root.seek(event.x / width)
                    onPositionChanged: event => {
                        if (pressed)
                            root.seek(event.x / width);
                    }
                }
            }

            Text {
                anchors {
                    left: parent.left
                    bottom: parent.bottom
                }
                text: root.formatTime(root.trackPosition)
                color: Theme.textMuted
                renderType: Text.NativeRendering
                font {
                    family: ShellConfig.typography.monoFamily
                    pixelSize: 10
                }
            }

            Text {
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                }
                text: root.formatTime(root.trackLength)
                color: Theme.textMuted
                renderType: Text.NativeRendering
                font {
                    family: ShellConfig.typography.monoFamily
                    pixelSize: 10
                }
            }
        }

        Row {
            id: controls

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: timeline.bottom
                topMargin: 23
            }
            spacing: 12

            FloralDashboardMediaButton {
                kind: "previous"
                available: root.player
                    ? root.player.canGoPrevious : false
                onClicked: root.player?.previous()
            }

            FloralDashboardMediaButton {
                kind: "toggle"
                prominent: true
                playing: root.player ? root.player.isPlaying : false
                available: root.player
                    ? root.player.canTogglePlaying : false
                onClicked: root.player?.togglePlaying()
            }

            FloralDashboardMediaButton {
                kind: "next"
                available: root.player ? root.player.canGoNext : false
                onClicked: root.player?.next()
            }
        }

        Item {
            visible: root.player ? root.player.volumeSupported : false
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                bottomMargin: 7
            }
            height: 52

            Text {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                text: "player volume"
                color: Theme.textMuted
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
                    verticalCenter: parent.verticalCenter
                    leftMargin: 116
                }
                from: 0
                to: 1
                stepSize: 0.01
                value: root.player ? root.player.volume : 0
                onMoved: value => {
                    if (root.player)
                        root.player.volume = value;
                }
            }
        }
    }
}
