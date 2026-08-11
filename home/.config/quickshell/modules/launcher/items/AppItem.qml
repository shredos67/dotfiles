import QtQuick
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

    implicitHeight: ShellConfig.bar.launcherItemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: 0
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

        Rectangle {
            id: iconFrame

            anchors.verticalCenter: parent.verticalCenter
            width: ShellConfig.bar.launcherIconFrameSize
            height: width
            radius: 0
            color: Theme.panelRaised
            border.width: ShellConfig.bar.hairlineThickness
            border.color: Theme.frameBorderFaint
        }

        IconImage {
            anchors {
                left: parent.left
                leftMargin: (ShellConfig.bar.launcherIconFrameSize
                    - ShellConfig.bar.launcherAppIconSize) / 2
                verticalCenter: parent.verticalCenter
            }
            asynchronous: true
            source: Quickshell.iconPath(root.modelData?.icon, "image-missing")
            implicitSize: ShellConfig.bar.launcherAppIconSize
            z: 1
        }

        Item {
            anchors {
                left: iconFrame.right
                right: favouriteIcon.left
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

        Loader {
            id: favouriteIcon

            asynchronous: true
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
            }
            active: root.modelData
                && Strings.testRegexList(GlobalConfig.launcher.favouriteApps,
                    root.modelData.id)

            sourceComponent: MaterialIcon {
                text: "favorite"
                fill: 1
                color: Theme.moduleLabel
            }
        }
    }
}
