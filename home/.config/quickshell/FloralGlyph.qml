import QtQuick

Item {
    id: root

    property string kind: "settings"
    property color color: Theme.moduleValue
    property real strokeWidth: Math.max(1.5, width / 12)
    property bool active: false

    onKindChanged: drawing.requestPaint()
    onColorChanged: drawing.requestPaint()
    onStrokeWidthChanged: drawing.requestPaint()
    onActiveChanged: drawing.requestPaint()
    onWidthChanged: drawing.requestPaint()
    onHeightChanged: drawing.requestPaint()

    Canvas {
        id: drawing

        anchors.fill: parent
        antialiasing: true

        function line(context, x1, y1, x2, y2) {
            context.beginPath();
            context.moveTo(x1, y1);
            context.lineTo(x2, y2);
            context.stroke();
        }

        function circle(context, x, y, radius, fill) {
            context.beginPath();
            context.arc(x, y, radius, 0, Math.PI * 2);
            if (fill)
                context.fill();
            else
                context.stroke();
        }

        function roundedRectangle(context, x, y, width, height, radius) {
            const r = Math.min(radius, width / 2, height / 2);
            context.beginPath();
            context.moveTo(x + r, y);
            context.lineTo(x + width - r, y);
            context.quadraticCurveTo(x + width, y, x + width, y + r);
            context.lineTo(x + width, y + height - r);
            context.quadraticCurveTo(x + width, y + height,
                x + width - r, y + height);
            context.lineTo(x + r, y + height);
            context.quadraticCurveTo(x, y + height, x, y + height - r);
            context.lineTo(x, y + r);
            context.quadraticCurveTo(x, y, x + r, y);
            context.closePath();
        }

        onPaint: {
            const context = getContext("2d");
            const w = width;
            const h = height;
            const s = Math.min(w, h);
            const left = (w - s) / 2;
            const top = (h - s) / 2;
            const x = value => left + value * s;
            const y = value => top + value * s;

            context.reset();
            context.strokeStyle = root.color;
            context.fillStyle = root.color;
            context.lineWidth = root.strokeWidth;
            context.lineCap = "round";
            context.lineJoin = "round";

            if (root.kind === "launcher") {
                context.save();
                context.translate(x(0.5), y(0.5));
                for (let index = 0; index < 4; ++index) {
                    context.rotate(Math.PI / 2);
                    context.beginPath();
                    context.moveTo(0, -s * 0.09);
                    context.bezierCurveTo(-s * 0.25, -s * 0.13,
                        -s * 0.28, -s * 0.37, 0, -s * 0.39);
                    context.bezierCurveTo(s * 0.14, -s * 0.28,
                        s * 0.13, -s * 0.14, 0, -s * 0.09);
                    if (root.active)
                        context.fill();
                    else
                        context.stroke();
                }
                context.restore();
                circle(context, x(0.5), y(0.5), s * 0.075, true);
            } else if (root.kind === "settings") {
                line(context, x(0.14), y(0.25), x(0.86), y(0.25));
                line(context, x(0.14), y(0.5), x(0.86), y(0.5));
                line(context, x(0.14), y(0.75), x(0.86), y(0.75));
                circle(context, x(0.36), y(0.25), s * 0.075, true);
                circle(context, x(0.67), y(0.5), s * 0.075, true);
                circle(context, x(0.46), y(0.75), s * 0.075, true);
            } else if (root.kind === "wallpaper") {
                roundedRectangle(context, x(0.12), y(0.18),
                    s * 0.76, s * 0.64, s * 0.1);
                context.stroke();
                circle(context, x(0.68), y(0.36), s * 0.07, false);
                context.beginPath();
                context.moveTo(x(0.2), y(0.7));
                context.lineTo(x(0.4), y(0.47));
                context.lineTo(x(0.54), y(0.61));
                context.lineTo(x(0.64), y(0.51));
                context.lineTo(x(0.81), y(0.7));
                context.stroke();
            } else if (root.kind === "dock") {
                roundedRectangle(context, x(0.1), y(0.25),
                    s * 0.8, s * 0.5, s * 0.18);
                context.stroke();
                for (let index = 0; index < 3; ++index)
                    circle(context, x(0.34 + index * 0.16), y(0.5), s * 0.055, true);
            } else if (root.kind === "motion") {
                context.beginPath();
                context.moveTo(x(0.1), y(0.62));
                context.bezierCurveTo(x(0.28), y(0.15), x(0.42), y(0.85), x(0.58), y(0.42));
                context.bezierCurveTo(x(0.69), y(0.14), x(0.79), y(0.32), x(0.9), y(0.22));
                context.stroke();
            } else if (root.kind === "appearance") {
                circle(context, x(0.5), y(0.5), s * 0.13, false);
                for (let index = 0; index < 8; ++index) {
                    const angle = index * Math.PI / 4;
                    line(context,
                        x(0.5 + Math.cos(angle) * 0.25),
                        y(0.5 + Math.sin(angle) * 0.25),
                        x(0.5 + Math.cos(angle) * 0.39),
                        y(0.5 + Math.sin(angle) * 0.39));
                }
            } else if (root.kind === "interface") {
                for (let row = 0; row < 2; ++row) {
                    for (let column = 0; column < 2; ++column) {
                        roundedRectangle(context,
                            x(0.13 + column * 0.4),
                            y(0.13 + row * 0.4),
                            s * 0.32, s * 0.32, s * 0.07);
                        context.stroke();
                    }
                }
            } else if (root.kind === "close") {
                line(context, x(0.24), y(0.24), x(0.76), y(0.76));
                line(context, x(0.76), y(0.24), x(0.24), y(0.76));
            } else if (root.kind === "check") {
                context.beginPath();
                context.moveTo(x(0.18), y(0.52));
                context.lineTo(x(0.4), y(0.73));
                context.lineTo(x(0.82), y(0.27));
                context.stroke();
            } else if (root.kind === "edit") {
                context.beginPath();
                context.moveTo(x(0.2), y(0.8));
                context.lineTo(x(0.29), y(0.53));
                context.lineTo(x(0.67), y(0.15));
                context.lineTo(x(0.84), y(0.32));
                context.lineTo(x(0.46), y(0.7));
                context.closePath();
                context.stroke();
                line(context, x(0.29), y(0.53), x(0.46), y(0.7));
            }
        }
    }
}
