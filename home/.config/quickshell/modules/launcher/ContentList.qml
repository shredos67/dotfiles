pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property var content
    required property ScreenState screenState
    required property var panels
    required property real maxHeight
    required property SearchBar search
    required property int padding
    required property int rounding
    property bool animateGeometry: true

    readonly property bool showWallpapers: false
    readonly property var currentList: appList.item
    readonly property real currentHeaderHeight: currentList?.headerHeight ?? 0
    property string animState: "apps"

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    height: root.animateGeometry
        ? implicitHeight
        : Math.max(0, (parent?.height ?? implicitHeight) - root.padding)

    clip: true
    state: animState

    states: [
        State {
            name: "apps"

            PropertyChanges {
                root.implicitWidth: ShellConfig.bar.launcherPanelWidth
                    - root.padding * 2
                root.implicitHeight: Math.min(root.maxHeight, root.currentList?.count === 0
                    ? root.currentHeaderHeight + empty.implicitHeight
                    : appList.implicitHeight > 0 ? appList.implicitHeight : empty.implicitHeight)
                appList.active: true
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        }
    ]

    Loader {
        id: appList

        active: false

        anchors.fill: parent

        sourceComponent: AppList {
            objectName: "launcherAppList"

            search: root.search
            screenState: root.screenState
        }
    }

    Row {
        id: empty

        opacity: root.currentList?.count === 0 ? 1 : 0
        scale: root.currentList?.count === 0 ? 1 : 0.5

        spacing: Tokens.spacing.medium
        padding: Tokens.padding.large

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.currentHeaderHeight + Math.max(0,
            (root.height - root.currentHeaderHeight - implicitHeight) / 2)

        MaterialIcon {
            text: "manage_search"
            color: Theme.moduleLabel
            fontStyle: Tokens.font.icon.extraLarge

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: qsTr("no results")
                color: Theme.moduleValue
                font.family: ShellConfig.typography.monoFamily
                font.styleName: ShellConfig.typography.fineStyle
                font.pixelSize: ShellConfig.bar.launcherNameSize
            }

            StyledText {
                text: qsTr("try another name")
                color: Theme.textMuted
                font.family: ShellConfig.typography.monoFamily
                font.pixelSize: ShellConfig.bar.launcherDetailSize
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on scale {
            Anim {}
        }
    }

    Behavior on implicitWidth {
        enabled: root.screenState.launcher && root.animateGeometry

        Anim {}
    }

    Behavior on implicitHeight {
        enabled: root.screenState.launcher && root.animateGeometry

        Anim {}
    }
}
