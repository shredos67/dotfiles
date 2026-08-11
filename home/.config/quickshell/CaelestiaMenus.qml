/*
 * this file holds the launcher and power menu
 * most sizes are in shellconfig qml
 * change that first
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.launcher as Launcher
import qs.modules.session as Session

Scope {
    id: root

    readonly property bool active: screenState.launcher || screenState.session

    Binding {
        target: Colours
        property: "showPreview"
        value: false
    }

    function applyTheme(): void {
        const p = Colours.current;

        Colours.showPreview = false;
        Colours.currentLight = false;
        Colours.scheme = "quickshell";
        Colours.flavour = "pywal";

        p.m3primary_paletteKeyColor = Theme.accentPrimary;
        p.m3secondary_paletteKeyColor = Theme.accentSecondary;
        p.m3tertiary_paletteKeyColor = Theme.accentTertiary;
        p.m3neutral_paletteKeyColor = Theme.panel;
        p.m3neutral_variant_paletteKeyColor = Theme.textMuted;

        p.m3background = Theme.panel;
        p.m3onBackground = Theme.moduleValue;
        p.m3surface = Theme.panel;
        p.m3surfaceDim = Theme.panel;
        p.m3surfaceBright = Theme.panelHighlight;
        p.m3surfaceContainerLowest = Qt.darker(Theme.panel, 1.08);
        p.m3surfaceContainerLow = Theme.panel;
        p.m3surfaceContainer = Theme.panelRaised;
        p.m3surfaceContainerHigh = Theme.panelHighlight;
        p.m3surfaceContainerHighest = Theme.panelHighlight;
        p.m3onSurface = Theme.moduleValue;
        p.m3surfaceVariant = Theme.panelHighlight;
        p.m3onSurfaceVariant = Theme.textMuted;
        p.m3inverseSurface = Theme.moduleValue;
        p.m3inverseOnSurface = Theme.panel;
        p.m3outline = Theme.textMuted;
        p.m3outlineVariant = Theme.separator;
        p.m3shadow = Theme.term0;
        p.m3scrim = Theme.panel;
        p.m3surfaceTint = Theme.accentPrimary;

        p.m3primary = Theme.accentPrimary;
        p.m3onPrimary = Theme.panel;
        p.m3primaryContainer = Theme.panelHighlight;
        p.m3onPrimaryContainer = Theme.moduleValue;
        p.m3inversePrimary = Theme.accentPrimary;
        p.m3secondary = Theme.accentSecondary;
        p.m3onSecondary = Theme.panel;
        p.m3secondaryContainer = Theme.panelHighlight;
        p.m3onSecondaryContainer = Theme.moduleValue;
        p.m3tertiary = Theme.accentTertiary;
        p.m3onTertiary = Theme.panel;
        p.m3tertiaryContainer = Theme.panelHighlight;
        p.m3onTertiaryContainer = Theme.moduleValue;
        p.m3error = Theme.statusDanger;
        p.m3onError = Theme.panel;
        p.m3errorContainer = Theme.panelHighlight;
        p.m3onErrorContainer = Theme.statusDanger;
        p.m3success = Theme.statusSuccess;
        p.m3onSuccess = Theme.panel;
        p.m3successContainer = Theme.panelHighlight;
        p.m3onSuccessContainer = Theme.statusSuccess;

        p.m3primaryFixed = Theme.accentPrimary;
        p.m3primaryFixedDim = Theme.accentPrimary;
        p.m3onPrimaryFixed = Theme.panel;
        p.m3onPrimaryFixedVariant = Theme.moduleValue;
        p.m3secondaryFixed = Theme.accentSecondary;
        p.m3secondaryFixedDim = Theme.accentSecondary;
        p.m3onSecondaryFixed = Theme.panel;
        p.m3onSecondaryFixedVariant = Theme.moduleValue;
        p.m3tertiaryFixed = Theme.accentTertiary;
        p.m3tertiaryFixedDim = Theme.accentTertiary;
        p.m3onTertiaryFixed = Theme.panel;
        p.m3onTertiaryFixedVariant = Theme.moduleValue;

        p.term0 = Theme.term0;
        p.term1 = Theme.term1;
        p.term2 = Theme.term2;
        p.term3 = Theme.term3;
        p.term4 = Theme.term4;
        p.term5 = Theme.term5;
        p.term6 = Theme.term6;
        p.term7 = Theme.term7;
        p.term8 = Theme.term8;
        p.term9 = Theme.term9;
        p.term10 = Theme.term10;
        p.term11 = Theme.term11;
        p.term12 = Theme.term12;
        p.term13 = Theme.term13;
        p.term14 = Theme.term14;
        p.term15 = Theme.term15;
    }

    Component.onCompleted: applyTheme()

    Connections {
        target: Theme

        function onColoursChanged(): void {
            root.applyTheme();
        }
    }

    FontLoader {
        source: Quickshell.shellPath("assets/material-symbols/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf")
    }

    function close(): void {
        screenState.launcher = false;
        screenState.session = false;
    }

    function openLauncher(): void {
        applyTheme();
        screenState.session = false;
        screenState.launcher = true;
    }

    function openSession(): void {
        applyTheme();
        screenState.launcher = false;
        screenState.session = true;
    }

    function toggleLauncher(): void {
        if (screenState.launcher)
            close();
        else
            openLauncher();
    }

    function toggleSession(): void {
        if (screenState.session)
            close();
        else
            openSession();
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggleLauncher();
        }

        function open(): void {
            root.openLauncher();
        }

        function close(): void {
            screenState.launcher = false;
        }
    }

    IpcHandler {
        target: "powerMenu"

        function toggle(): void {
            root.toggleSession();
        }

        function open(): void {
            root.openSession();
        }

        function close(): void {
            screenState.session = false;
        }
    }

    ScreenState {
        id: screenState

        modelData: window.screen
    }

    StyledWindow {
        id: window

        name: "menus"
        visible: true

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        mask: Region {
            width: root.active ? window.width : 0
            height: root.active ? window.height : 0
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.active
            z: 1
            onClicked: root.close()
        }

        Item {
            id: workspaceScrim

            anchors.fill: parent
            opacity: screenState.session && Config.session.enabled
                ? ShellConfig.bar.powerMenuDimOpacity : 0
            z: 0

			readonly property real topCornerInset: ShellConfig.frame.cornerSize

            StyledRect {
				visible: true

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
					topMargin: ShellConfig.bar.surfaceHeight
				}

                color: Theme.panel
            }

            StyledRect {
                visible: false

				anchors {
					left: parent.left
					right: parent.right
					top: parent.top
					bottom: parent.bottom
					topMargin: ShellConfig.bar.surfaceHeight
						+ ShellConfig.frame.curveEnd
				}

				color: Theme.panel
			}

			StyledRect {
				visible: false

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: workspaceScrim.topCornerInset
                    rightMargin: workspaceScrim.topCornerInset
                    topMargin: ShellConfig.bar.surfaceHeight
                }

				height: ShellConfig.frame.curveEnd
                color: Theme.panel
            }

			Shape {
				visible: false

				anchors {
					left: parent.left
					top: parent.top
					topMargin: ShellConfig.bar.surfaceHeight
				}

				width: ShellConfig.frame.cornerSize
				height: ShellConfig.frame.curveEnd

				ShapePath {
					fillColor: Theme.panel
					strokeWidth: 0
					startX: 0
					startY: ShellConfig.frame.cornerSize

					PathCubic {
						x: ShellConfig.frame.cornerSize
						y: 0
						control1X: 0
						control1Y: ShellConfig.frame.cornerSize
							- ShellConfig.frame.curveControl
						control2X: ShellConfig.frame.cornerSize
							- ShellConfig.frame.curveControl
						control2Y: 0
					}

					PathLine {
						x: ShellConfig.frame.cornerSize
						y: ShellConfig.frame.curveEnd
					}

					PathLine {
						x: 0
						y: ShellConfig.frame.curveEnd
					}
				}
			}

			Shape {
				visible: false

				anchors {
					right: parent.right
					top: parent.top
					topMargin: ShellConfig.bar.surfaceHeight
				}

				width: ShellConfig.frame.cornerSize
				height: ShellConfig.frame.curveEnd
				transform: Scale {
					origin.x: ShellConfig.frame.cornerSize / 2
					xScale: -1
				}

				ShapePath {
					fillColor: Theme.panel
					strokeWidth: 0
					startX: 0
					startY: ShellConfig.frame.cornerSize

					PathCubic {
						x: ShellConfig.frame.cornerSize
						y: 0
						control1X: 0
						control1Y: ShellConfig.frame.cornerSize
							- ShellConfig.frame.curveControl
						control2X: ShellConfig.frame.cornerSize
							- ShellConfig.frame.curveControl
						control2Y: 0
					}

					PathLine {
						x: ShellConfig.frame.cornerSize
						y: ShellConfig.frame.curveEnd
					}

					PathLine {
						x: 0
						y: ShellConfig.frame.curveEnd
					}
				}
			}

            Behavior on opacity {
                Anim {
                    type: Anim.SlowEffects
                }
            }
        }

		Item {
			id: panelArea

			anchors.fill: parent

            Item {
                id: popupBackgrounds

                anchors.fill: parent
                visible: launcher.visible || session.visible
                opacity: 1
                z: 0
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    blurMax: 15
                    shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
                }

                Item {
                    id: squarePopupBackgrounds

                    anchors.fill: parent
                    visible: true

                    Rectangle {
                        visible: launcher.visible
                        x: launcher.x - ShellConfig.frame.lineThickness
                        y: launcher.y - ShellConfig.frame.lineThickness
                        width: launcher.width + ShellConfig.frame.lineThickness * 2
                        height: launcher.height + ShellConfig.frame.lineThickness * 2
                            + ShellConfig.frame.popupEdgeExtension
                        color: Theme.frameBorder
                    }

                    Rectangle {
                        visible: session.visible
                        x: session.x - ShellConfig.frame.lineThickness
                        y: session.y - ShellConfig.frame.lineThickness
                        width: session.width + ShellConfig.frame.lineThickness * 2
                            + ShellConfig.frame.popupEdgeExtension
                        height: session.height + ShellConfig.frame.lineThickness * 2
                        color: Theme.frameBorder
                    }

                    Rectangle {
                        visible: launcher.visible
                        x: launcher.x
                        y: launcher.y
                        width: launcher.width
                        height: launcher.height + ShellConfig.frame.popupEdgeExtension
                        color: Theme.panel
                    }

                    Rectangle {
                        visible: session.visible
                        x: session.x
                        y: session.y
                        width: session.width + ShellConfig.frame.popupEdgeExtension
                        height: session.height
                        color: Theme.panel
                    }

                }

                Item {
                    id: roundedPopupBackgrounds

                    anchors.fill: parent
                    visible: false

                    StyledRect {
                        visible: launcher.visible
                        x: launcher.x - ShellConfig.frame.lineThickness
                        y: launcher.y - ShellConfig.frame.lineThickness
                        width: launcher.width + ShellConfig.frame.lineThickness * 2
                        height: launcher.height + ShellConfig.frame.lineThickness
                            + ShellConfig.frame.popupEdgeExtension
                        color: Theme.frameBorder
                        radius: 0
                        topLeftRadius: 0
                        topRightRadius: 0
                        bottomLeftRadius: 0
                        bottomRightRadius: 0
                    }

                    StyledRect {
                        visible: launcher.visible
                        x: launcher.x
                        y: launcher.y
                        width: launcher.width
                        height: launcher.height + ShellConfig.frame.popupEdgeExtension
                        color: Theme.panel
                        radius: 0
                        topLeftRadius: 0
                        topRightRadius: 0
                        bottomLeftRadius: 0
                        bottomRightRadius: 0
                    }

                    StyledRect {
                        visible: session.visible
                        x: session.x - ShellConfig.frame.lineThickness
                        y: session.y - ShellConfig.frame.lineThickness
                        width: session.width + ShellConfig.frame.lineThickness
                            + ShellConfig.frame.popupEdgeExtension
                        height: session.height + ShellConfig.frame.lineThickness * 2
                        color: Theme.frameBorder
                        radius: 0
                        topLeftRadius: 0
                        topRightRadius: 0
                        bottomLeftRadius: 0
                        bottomRightRadius: 0
                    }

                    StyledRect {
                        visible: session.visible
                        x: session.x
                        y: session.y
                        width: session.width + ShellConfig.frame.popupEdgeExtension
                        height: session.height
                        color: Theme.panel
                        radius: 0
                        topLeftRadius: 0
                        topRightRadius: 0
                        bottomLeftRadius: 0
                        bottomRightRadius: 0
                    }
                }

                StyledRect {
                    visible: launcher.visible
                    x: launcher.x + ShellConfig.bar.launcherInnerInset
                    y: launcher.y + ShellConfig.bar.launcherInnerInset
                    width: launcher.width - ShellConfig.bar.launcherInnerInset * 2
                    height: launcher.height + ShellConfig.frame.popupEdgeExtension
                        - ShellConfig.bar.launcherInnerInset * 2
                    color: "transparent"
                    radius: 0
                    bottomLeftRadius: 0
                    bottomRightRadius: 0
                    border.width: ShellConfig.bar.hairlineThickness
                    border.color: Theme.frameBorderFaint
                }

                FloralCorner {
                    visible: launcher.visible
                    x: launcher.x + ShellConfig.frame.lineThickness
                    y: launcher.y + ShellConfig.frame.lineThickness
                    width: ShellConfig.bar.launcherOrnamentSize
                    height: width
                    location: FloralCorner.TopLeft
                    strength: 1.0
                }

                FloralCorner {
                    visible: launcher.visible
                    x: launcher.x + launcher.width - width
                        - ShellConfig.frame.lineThickness
                    y: launcher.y + ShellConfig.frame.lineThickness
                    width: ShellConfig.bar.launcherOrnamentSize
                    height: width
                    location: FloralCorner.TopRight
                    strength: 1.0
                }

                StyledRect {
                    visible: session.visible
                    x: session.x + ShellConfig.bar.powerMenuInnerInset
                    y: session.y + ShellConfig.bar.powerMenuInnerInset
                    width: session.width + ShellConfig.frame.popupEdgeExtension
                        - ShellConfig.bar.powerMenuInnerInset * 2
                    height: session.height - ShellConfig.bar.powerMenuInnerInset * 2
                    color: "transparent"
                    radius: 0
                    topRightRadius: 0
                    bottomRightRadius: 0
                    border.width: ShellConfig.bar.hairlineThickness
                    border.color: Theme.frameBorderFaint
                }

                FloralCorner {
                    visible: session.visible
                    x: session.x + ShellConfig.frame.lineThickness
                    y: session.y + ShellConfig.frame.lineThickness
                    width: ShellConfig.bar.powerMenuOrnamentSize
                    height: width
                    location: FloralCorner.TopLeft
                    strength: 1.0
                }

                FloralCorner {
                    visible: session.visible
                    x: session.x + ShellConfig.frame.lineThickness
                    y: session.y + session.height - height
                        - ShellConfig.frame.lineThickness
                    width: ShellConfig.bar.powerMenuOrnamentSize
                    height: width
                    location: FloralCorner.BottomLeft
                    strength: 1.0
                }
            }

            MouseArea {
                anchors.fill: launcher
                enabled: launcher.visible
                z: 2
                onClicked: mouse.accepted = true
            }

            MouseArea {
                anchors.fill: session
                enabled: session.visible
                z: 2
                onClicked: mouse.accepted = true
            }

            Launcher.Wrapper {
                id: launcher

                screen: window.screen
                screenState: screenState
                panels: panelContract

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                z: 3
            }

            Session.Wrapper {
                id: session

                screenState: screenState
                sidebarVisible: false

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                z: 3
            }
        }
    }

    QtObject {
        id: panelContract

        readonly property QtObject dashboard: QtObject {
            property real nonAnimHeight: 0
        }

        readonly property QtObject bar: QtObject {
            property real implicitWidth: 0
        }

        readonly property QtObject popouts: QtObject {
            property bool hasCurrent: false
            property real currentCenter: 0
            property real nonAnimHeight: 0
            property real nonAnimWidth: 0
        }

        readonly property QtObject utilities: QtObject {
            property real implicitWidth: 0
        }
    }

}
