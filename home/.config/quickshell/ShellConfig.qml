pragma Singleton

import QtQuick

QtObject {
    id: root

    // global size multiplier
    property real uiScale: 1.2

    function scaled(value) {
        return Math.round(value * uiScale)
    }

    // shared font names and styles
    property QtObject typography: QtObject {
        property string monoFamily: "PP Right Serif Mono"
        property string fineStyle: "Fine"
        property string iconFamily: "Symbols Nerd Font Mono"
    }

    property QtObject visuals: QtObject {
        // shared depth and rounding
        property int surfaceRadius: root.scaled(16)
        property int cardRadius: root.scaled(12)
        property int controlRadius: root.scaled(9)
        property int innerInset: root.scaled(6)
        property int innerLineWidth: 1
        property int shadowBleed: root.scaled(28)
        property real shadowBlur: root.scaled(14)
        property real shadowSpread: root.scaled(1)
        property real shadowOffsetY: root.scaled(4)
        property real shadowOpacity: 0.68
        property real ambientGlowOpacity: 0.18

        // shared motion
        property int motionFast: 130
        property int motionNormal: 230
        property int motionSlow: 380
        property real hoverLift: root.scaled(3)
        property real pressedScale: 0.94
    }

    property QtObject bar: QtObject {
        // top bar size and layout
        property int surfaceHeight: 50
        property int windowHeight: 145
        property int popupHostHeight: 220 + mediaPopupBounceBridge
            + root.visuals.shadowBleed
        property int exclusiveZone: 50
        property int notchWidth: root.scaled(240) // this is for m2 macbooks
        property int contentMargin: root.scaled(14)
        property int leftSpacing: root.scaled(12)
        property int rightSpacing: root.scaled(12)

        // bar text dividers and borders
        property int labelFontSize: root.scaled(16)
        property int labelFontWeight: Font.DemiBold
        property int valueFontSize: root.scaled(15)
        property int dateFontSize: root.scaled(15)
        property int separatorFontSize: root.scaled(15)
        property int separatorWidth: root.scaled(14)
        property int separatorDiamondSize: root.scaled(4)
        property int hairlineThickness: 1
        property int buttonBorderWidth: hairlineThickness + 1
        property real labelLetterSpacing: root.scaled(0.8)
        property int windowFontSize: root.scaled(14)

        // workspaces and fixed text widths
        property int workspaceCount: 4
        property int workspaceButtonSize: root.scaled(24)
        property int workspaceButtonWidth: root.scaled(30)
        property int workspaceSpacing: root.scaled(3)
        property int workspaceFontSize: root.scaled(14)
        property int workspaceAnimationMs: 120
        property int clockTimeValueWidth: root.scaled(48)
        property int clockSummaryPadding: root.scaled(5)
        property int dateValueWidth: root.scaled(94)
        property int windowTitleWidth: root.scaled(210)
        property int networkMaximumWidth: root.scaled(120)

        // calendar popup
        property int calendarPopupWidth: 344
        property int calendarPopupHeight: 198
        property int calendarPopupPadding: 12
        property int calendarHeaderHeight: 27
        property int calendarNavButtonSize: 24
        property int calendarWeekdayHeight: 16
        property int calendarDayCellHeight: 19
        property int calendarMonthTitleSize: 14
        property int calendarWeekdaySize: 10
        property int calendarDaySize: 12
        property int calendarAnimationMs: root.visuals.motionNormal

        // network popup
        property int networkPopupWidth: 310
        property int networkPopupHeight: 160
        property int networkPopupPadding: 16
        property int networkPopupContentTop: 16
        property int networkPopupSectionSpacing: 6
        property int networkPopupRowSpacing: 4
        property int networkPopupLabelWidth: 76
        property int networkPopupTitleSize: 14
        property int networkPopupTextSize: 12

        // media in the bar
        property int mediaSummaryWidth: root.scaled(144)
        property int mediaTextWidth: root.scaled(105)
        property int mediaButtonSize: root.scaled(22)
        property int popupTriggerTopExtension: Math.max(0,
            (surfaceHeight - mediaButtonSize) / 2)
        property int mediaIconSize: root.scaled(12)
        property int mediaSpacing: root.scaled(5)
        property int mediaSummaryPadding: root.scaled(4)
        property int mediaFontSize: root.scaled(13)
        property int mediaAnimationMs: 140

        // media popup and controls
        property int mediaPopupWidth: 300
        property int mediaPopupHeight: 112
        property int mediaPopupHoverBridge: 10
        property int mediaPopupBorderOverlap: 2
        property int mediaPopupBounceBridge: 14
        property int mediaPopupPadding: 10
        property int mediaPopupContentTop: 18
        property int mediaPopupTitleSize: 14
        property int mediaPopupArtistSize: 12
        property int mediaPopupButtonSize: 24
        property int mediaPopupIconSize: 12
        property int mediaPopupControlSpacing: 10
        property int mediaPopupArtworkSize: 82
        property int mediaPopupArtworkGap: 12
        property int mediaPopupProgressHeight: 5
        property int mediaPopupProgressUpdateMs: 500

        // popup and image corners
        property int popupCornerRadius: root.visuals.surfaceRadius
        property int popupInnerInset: engravedInset
        property int mediaArtworkCornerRadius: 9
        property int powerImageCornerRadius: root.scaled(12)

        // brightness and volume in the bar
        property int controlSummaryPadding: root.scaled(4)
        property int controlSummarySpacing: root.scaled(5)
        property int controlSummaryLabelWidth: root.scaled(30)
        property int controlSummaryValueWidth: root.scaled(36)
        property int controlSummaryWidth: controlSummaryPadding * 2
            + controlSummaryLabelWidth + controlSummarySpacing
            + controlSummaryValueWidth

        // brightness and volume popups
        property int controlPopupWidth: 200
        property int controlPopupHeight: 76
        property int controlPopupPadding: 16
        property int controlPopupContentTop: 18
        property int controlPopupSpacing: 8
        property int controlSliderHeight: 26
        property int controlSliderTrackHeight: 6
        property int controlSliderHandleWidth: 7
        property int controlSliderHandleHeight: 18
        property real controlSliderWheelStep: 0.05

        // corner buttons and launcher
        property int menuButtonSize: root.scaled(24)
        property int launcherIconSize: root.scaled(18)
        property real launcherScale: 1.12

        function launcherScaled(value) {
            return root.scaled(value * launcherScale)
        }

        property int launcherPanelWidth: launcherScaled(520)
        property int launcherHeaderHeight: launcherScaled(46)
        property int launcherItemHeight: launcherScaled(54)
        property int launcherItemRadius: launcherScaled(9)
        property int launcherIconFrameSize: launcherScaled(38)
        property int launcherAppIconSize: launcherScaled(26)
        property int launcherNameSize: launcherScaled(14)
        property int launcherDetailSize: launcherScaled(10)
        property int launcherSearchRadius: launcherScaled(10)
        property int launcherInnerInset: launcherScaled(7)
        property int launcherOrnamentSize: launcherScaled(68)

        // power icon buttons and hitboxes
        property int powerIconSize: root.scaled(15)
        property real menuButtonCornerRadius: 4 * root.uiScale
        property real contentBorderWidth: buttonBorderWidth
        property real powerIconStrokeWidth: 2 * root.uiScale
        property int menuAnimationMs: 140
        property int cornerButtonHorizontalExtension: contentMargin
        property int cornerButtonVerticalExtension: (surfaceHeight - menuButtonSize) / 2

        // battery size and animation
        property int batteryWidth: root.scaled(42)
        property int batteryHeight: root.scaled(18)
        property int batteryPoleWidth: root.scaled(3)
        property int batteryPoleHeight: root.scaled(8)
        property real batteryBorderWidth: root.uiScale
        property int batteryCornerRadius: root.scaled(4)
        property int batteryFontSize: root.scaled(13)
        property int batteryAnimationMs: 180

        // inner line and center detail
        property int engravedInset: root.scaled(5)
        property int centreOrnamentWidth: root.scaled(104)
        property int centreOrnamentHeight: root.scaled(8)

        // power menu sizing, image height only uses ui scale
        property real powerMenuScale: 1.12

        function powerMenuScaled(value) {
            return root.scaled(value * powerMenuScale)
        }

        property int powerMenuWidth: powerMenuScaled(168)
        property int powerMenuPadding: powerMenuScaled(16)
        property int powerMenuSpacing: powerMenuScaled(10)
        property int powerMenuHeaderHeight: powerMenuScaled(40)
        property int powerMenuActionHeight: powerMenuScaled(54)
        property int powerMenuActionRadius: powerMenuScaled(10)
        property int powerMenuButtonBorderWidth: buttonBorderWidth
        property int powerMenuActionIconSize: powerMenuScaled(18)
        property int powerMenuIconTextGap: powerMenuScaled(18)
        property int powerMenuActionTitleSize: powerMenuScaled(13)
        property int powerMenuActionDetailSize: powerMenuScaled(10)
        property int powerMenuImageHeight: root.scaled(120)
        property int powerMenuInnerInset: powerMenuScaled(7)
        property int powerMenuOrnamentSize: powerMenuScaled(64)
        property real powerMenuDimOpacity: 0.80
    }

    // bar and popup borders
    property QtObject frame: QtObject {
        property int lineThickness: 2
        property int cornerSize: 35
        property int curveControl: 28
        property int curveEnd: cornerSize + 1
        property int powerMenuTopOverlap: 12
        property int popupEdgeExtension: 24
        property int borderZ: 100
    }

    property QtObject notifications: QtObject {
        // drawer size and borders
        property int panelWidth: root.scaled(420)
        property int panelPadding: root.scaled(18)
        property int panelInnerInset: root.scaled(7)
        property int panelRadius: root.scaled(18)

        // base corner size, use zero for a square corner
        property real topLeftRounding: 26

        function topLeftBorderRadius(innerBorder) {
            return Math.max(0, root.scaled(topLeftRounding)
                - (innerBorder ? panelInnerInset : 0))
        }

        property int borderWidth: 2
        property int headerHeight: root.scaled(150)
        property int statsHeight: root.scaled(256)

        // notification cards actions and system rows
        property int cardRadius: root.scaled(12)
        property int cardPadding: root.scaled(15)
        property int cardSpacing: root.scaled(11)
        property int iconSize: root.scaled(46)
        property int closeButtonSize: root.scaled(36)
        property int titleSize: root.scaled(17)
        property int bodySize: root.scaled(14)
        property int metaSize: root.scaled(13)
        property int actionHeight: root.scaled(38)
        property int statRowHeight: root.scaled(52)
        property int statBarHeight: root.scaled(6)

        // screenshot and recording list
        property int screenshotAreaHeight: root.scaled(136)
        property int screenshotRowHeight: root.scaled(30)

        // details and notification popups
        property int notificationOrnamentSize: root.scaled(96)
        property int emptyOrnamentSize: root.scaled(118)
        property int toastWidth: root.scaled(350)
        property int toastEdgeMargin: root.scaled(12)
        property int toastMaximumHeight: root.scaled(460)

        // drawer motion dimming and refresh
        property int animationBleed: root.scaled(32)
        property real dimOpacity: 0.58
        property int animationMs: 260
        property int statsUpdateMs: 2000
    }

    property QtObject wallpaperPicker: QtObject {
        // wallpaper picker layout
        property int panelInset: root.scaled(8)
        property int panelHeight: root.scaled(600)
        property int headerHeight: root.scaled(76)
        property int footerHeight: root.scaled(70)
        property int horizontalPadding: root.scaled(30)
        property int edgeFadeWidth: root.scaled(92)
        property int ornamentSize: root.scaled(112)
        property int titleSize: root.scaled(20)
        property int detailSize: root.scaled(12)
    }
}
