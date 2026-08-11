pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.items
import qs.modules.launcher.services

Item {
    id: root

    required property ScreenState screenState
    required property var panels
    required property real maxHeight

    readonly property int padding: Tokens.padding.large
    readonly property int rounding: 0

    implicitWidth: ShellConfig.bar.launcherPanelWidth
    implicitHeight: header.height + listWrapper.height + search.height
        + padding * 3 + search.anchors.bottomMargin

    Item {
        id: header

        anchors {
            left: parent.left
            right: parent.right
            bottom: listWrapper.top
            bottomMargin: root.padding
            leftMargin: root.padding
            rightMargin: root.padding
        }
        height: ShellConfig.bar.launcherHeaderHeight

        Text {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
            }
            text: "App Launcher"
            color: Theme.moduleLabel
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                styleName: ShellConfig.typography.fineStyle
                pixelSize: ShellConfig.bar.launcherNameSize + 1
                letterSpacing: ShellConfig.bar.labelLetterSpacing * 1.5
            }
        }

        Text {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: ShellConfig.bar.launcherNameSize + 8
            }
            text: "enter to launch"
            color: Theme.textMuted
            renderType: Text.NativeRendering
            font {
                family: ShellConfig.typography.monoFamily
                styleName: ShellConfig.typography.fineStyle
                pixelSize: ShellConfig.bar.launcherDetailSize
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

    Item {
        id: listWrapper

        width: root.width - root.padding * 2
        implicitWidth: width
        implicitHeight: list.height + root.padding

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: search.top
        anchors.bottomMargin: root.padding

        ContentList {
            id: list

            width: parent.width
            content: root
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight - search.implicitHeight - header.height
                - root.padding * 4
            search: search
            padding: root.padding
            rounding: root.rounding
        }
    }

    SearchBar {
        id: search

        objectName: "launcherSearch"

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: root.padding
            bottomMargin: CUtils.clamp(root.padding - Config.border.thickness,
                0, root.padding)
        }

        topPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)
        bottomPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)
        font.family: ShellConfig.typography.monoFamily
        font.styleName: ShellConfig.typography.fineStyle
        font.pixelSize: ShellConfig.bar.launcherNameSize
        bg.color: Theme.panelRaised
        bg.radius: 0
        bg.border.width: ShellConfig.bar.hairlineThickness
        bg.border.color: activeFocus ? Theme.frameBorder : Theme.frameBorderFaint
        searchIcon.color: Theme.moduleLabel

        placeholderText: qsTr("Search applications…")

        onAccepted: {
            const currentItem = list.currentList?.currentItem;
            if (!currentItem)
                return;

            Apps.launch(currentItem.modelData);
            root.screenState.launcher = false;
        }

        Keys.onUpPressed: list.currentList?.decrementCurrentIndex()
        Keys.onDownPressed: list.currentList?.incrementCurrentIndex()
        Keys.onEscapePressed: root.screenState.launcher = false

        Keys.onPressed: event => {
            if (!GlobalConfig.launcher.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                    list.currentList?.incrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                    list.currentList?.decrementCurrentIndex();
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab) {
                list.currentList?.incrementCurrentIndex();
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab
                    || (event.key === Qt.Key_Tab
                        && (event.modifiers & Qt.ShiftModifier))) {
                list.currentList?.decrementCurrentIndex();
                event.accepted = true;
            }
        }

        Component.onCompleted: forceActiveFocus()

        Connections {
            function onLauncherChanged(): void {
                if (root.screenState.launcher)
                    Qt.callLater(() => search.forceActiveFocus());
                else
                    search.text = "";
            }

            target: root.screenState
        }
    }
}
