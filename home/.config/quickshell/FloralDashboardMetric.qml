import QtQuick

Rectangle {
    id: root

    required property string title
    required property string value
    property string detail: ""
    property color accent: FloralSettings.accentColor
    property real ratio: 0
    property var history: []
    property var secondHistory: []
    property color secondAccent: Theme.accentSecondary

    implicitHeight: 190
    radius: Math.max(11, FloralSettings.popupRadius + 1)
    color: FloralSettings.withAlpha(Theme.panelRaised, 0.50)
    border.width: 1
    border.color: Theme.frameBorderFaint
    clip: true

    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: 1
            topMargin: 15
        }
        width: 3
        height: 34
        radius: 2
        color: root.accent
    }

    Text {
        anchors {
            left: parent.left
            leftMargin: 17
            top: parent.top
            topMargin: 14
        }
        text: root.title
        color: Theme.moduleLabel
        renderType: Text.NativeRendering
        font {
            family: ShellConfig.typography.monoFamily
            styleName: ShellConfig.typography.fineStyle
            pixelSize: 12
            weight: Font.DemiBold
            letterSpacing: 0.7
        }
    }

    Text {
        anchors {
            right: parent.right
            rightMargin: 17
            top: parent.top
            topMargin: 11
        }
        text: root.value
        color: Theme.moduleValue
        renderType: Text.NativeRendering
        font {
            family: ShellConfig.typography.monoFamily
            styleName: ShellConfig.typography.fineStyle
            pixelSize: 22
            weight: Font.DemiBold
        }
    }

    Text {
        anchors {
            left: parent.left
            leftMargin: 17
            top: parent.top
            topMargin: 39
            right: parent.right
            rightMargin: 17
        }
        text: root.detail
        color: Theme.textMuted
        elide: Text.ElideRight
        renderType: Text.NativeRendering
        font {
            family: ShellConfig.typography.monoFamily
            styleName: ShellConfig.typography.fineStyle
            pixelSize: 10
        }
    }

    Canvas {
        id: graph

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: progressTrack.top
            leftMargin: 17
            rightMargin: 17
            topMargin: 67
            bottomMargin: 12
        }
        antialiasing: true

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        function drawSeries(context, series, colour, normalised) {
            if (!series || series.length < 2)
                return;
            let maximum = normalised ? 1 : 1;
            if (!normalised) {
                for (const sample of series)
                    maximum = Math.max(maximum, Number(sample) || 0);
            }

            context.beginPath();
            for (let index = 0; index < series.length; ++index) {
                const x = index * width / Math.max(1, series.length - 1);
                const value = Math.max(0, Math.min(1,
                    (Number(series[index]) || 0) / maximum));
                const y = height - value * (height - 4) - 2;
                if (index === 0)
                    context.moveTo(x, y);
                else
                    context.lineTo(x, y);
            }
            context.strokeStyle = colour;
            context.lineWidth = 1.7;
            context.lineCap = "round";
            context.lineJoin = "round";
            context.stroke();
        }

        onPaint: {
            const context = getContext("2d");
            context.reset();
            context.globalAlpha = 0.22;
            context.strokeStyle = Theme.frameBorder;
            context.lineWidth = 1;
            for (let row = 1; row < 4; ++row) {
                context.beginPath();
                context.moveTo(0, row * height / 4);
                context.lineTo(width, row * height / 4);
                context.stroke();
            }
            context.globalAlpha = 0.82;
            drawSeries(context, root.history, root.accent,
                root.title !== "network");
            context.globalAlpha = 0.58;
            drawSeries(context, root.secondHistory, root.secondAccent, false);
        }

        Connections {
            target: root
            function onHistoryChanged() { graph.requestPaint(); }
            function onSecondHistoryChanged() { graph.requestPaint(); }
            function onAccentChanged() { graph.requestPaint(); }
            function onSecondAccentChanged() { graph.requestPaint(); }
        }
    }

    Rectangle {
        id: progressTrack

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 17
            rightMargin: 17
            bottomMargin: 14
        }
        height: 5
        radius: height / 2
        color: Theme.panelHighlight
        border.width: 1
        border.color: Theme.frameBorderFaint

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.ratio))
            height: parent.height
            radius: parent.radius
            color: root.accent

            Behavior on width {
                NumberAnimation {
                    duration: FloralSettings.duration(260)
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
