import QtQuick

Canvas {
    id: root

    property string kind: "network"
    property color color: Theme.moduleValue
    property real strokeWidth: 1.8

    antialiasing: true

    onColorChanged: requestPaint()
    onKindChanged: requestPaint()
    onStrokeWidthChanged: requestPaint()

    function line(context, points) {
        context.beginPath();
        context.moveTo(points[0][0], points[0][1]);
        for (let index = 1; index < points.length; ++index)
            context.lineTo(points[index][0], points[index][1]);
        context.stroke();
    }

    onPaint: {
        const context = getContext("2d");
        const sx = width / 24;
        const sy = height / 24;
        context.reset();
        context.scale(sx, sy);
        context.strokeStyle = color;
        context.fillStyle = color;
        context.lineWidth = strokeWidth;
        context.lineCap = "round";
        context.lineJoin = "round";

        if (kind === "network") {
            context.beginPath();
            context.arc(12, 19, 1.5, 0, Math.PI * 2);
            context.fill();
            context.beginPath();
            context.arc(12, 18.5, 5, Math.PI * 1.22, Math.PI * 1.78);
            context.stroke();
            context.beginPath();
            context.arc(12, 18.5, 9, Math.PI * 1.2, Math.PI * 1.8);
            context.stroke();
        } else if (kind === "bluetooth") {
            line(context, [[12, 3], [17, 8], [7, 17], [12, 21], [12, 3], [17, 8]]);
            line(context, [[7, 7], [17, 17]]);
        } else if (kind === "audio") {
            context.beginPath();
            context.moveTo(4, 10);
            context.lineTo(8, 10);
            context.lineTo(13, 6);
            context.lineTo(13, 18);
            context.lineTo(8, 14);
            context.lineTo(4, 14);
            context.closePath();
            context.stroke();
            context.beginPath();
            context.arc(13, 12, 5, -0.85, 0.85);
            context.stroke();
            context.beginPath();
            context.arc(13, 12, 8, -0.72, 0.72);
            context.stroke();
        } else if (kind === "system") {
            context.strokeRect(5, 5, 14, 14);
            context.strokeRect(9, 9, 6, 6);
            for (let index = 0; index < 4; ++index) {
                const pos = 7 + index * 3.3;
                line(context, [[pos, 2.5], [pos, 5]]);
                line(context, [[pos, 19], [pos, 21.5]]);
                line(context, [[2.5, pos], [5, pos]]);
                line(context, [[19, pos], [21.5, pos]]);
            }
        } else if (kind === "refresh") {
            context.beginPath();
            context.arc(12, 12, 7, -0.15, Math.PI * 1.48);
            context.stroke();
            line(context, [[5.2, 6.4], [5.1, 11.2], [9.5, 9.2]]);
        } else if (kind === "lock") {
            context.strokeRect(6, 10, 12, 10);
            context.beginPath();
            context.arc(12, 10, 4.5, Math.PI, 0);
            context.stroke();
            context.beginPath();
            context.arc(12, 15, 1.2, 0, Math.PI * 2);
            context.fill();
        } else if (kind === "suspend") {
            context.beginPath();
            context.arc(12, 12, 8, -1.15, 1.15);
            context.stroke();
            line(context, [[12, 3], [12, 12]]);
        } else if (kind === "power") {
            context.beginPath();
            context.arc(12, 12, 8, -0.82, Math.PI * 1.82);
            context.stroke();
            line(context, [[12, 3], [12, 12]]);
        } else if (kind === "display") {
            context.strokeRect(3.5, 5, 17, 12);
            line(context, [[9, 21], [15, 21]]);
            line(context, [[12, 17], [12, 21]]);
        } else if (kind === "mic") {
            context.beginPath();
            context.moveTo(12, 3);
            context.bezierCurveTo(10.3, 3, 9, 4.3, 9, 6);
            context.lineTo(9, 11);
            context.bezierCurveTo(9, 12.7, 10.3, 14, 12, 14);
            context.bezierCurveTo(13.7, 14, 15, 12.7, 15, 11);
            context.lineTo(15, 6);
            context.bezierCurveTo(15, 4.3, 13.7, 3, 12, 3);
            context.stroke();
            context.beginPath();
            context.arc(12, 11, 7, 0.15, Math.PI - 0.15);
            context.stroke();
            line(context, [[12, 18], [12, 22]]);
            line(context, [[8, 22], [16, 22]]);
        } else {
            context.beginPath();
            context.arc(12, 12, 3, 0, Math.PI * 2);
            context.fill();
        }
    }
}
