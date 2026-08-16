import QtQuick

Canvas {
    id: root

    property string kind: "overview"
    property color color: Theme.moduleValue
    property real strokeWidth: Math.max(1.5, Math.min(width, height) / 11)
    property bool active: false

    antialiasing: true

    onKindChanged: requestPaint()
    onColorChanged: requestPaint()
    onStrokeWidthChanged: requestPaint()
    onActiveChanged: requestPaint()

    function line(context, points) {
        context.beginPath();
        context.moveTo(points[0][0], points[0][1]);
        for (let index = 1; index < points.length; ++index)
            context.lineTo(points[index][0], points[index][1]);
        context.stroke();
    }

    function circle(context, x, y, radius, filled) {
        context.beginPath();
        context.arc(x, y, radius, 0, Math.PI * 2);
        if (filled)
            context.fill();
        else
            context.stroke();
    }

    onPaint: {
        const context = getContext("2d");
        const sx = width / 24;
        const sy = height / 24;
        context.reset();
        context.scale(sx, sy);
        context.strokeStyle = root.color;
        context.fillStyle = root.color;
        context.lineWidth = root.strokeWidth / Math.max(sx, sy);
        context.lineCap = "round";
        context.lineJoin = "round";

        if (root.kind === "overview") {
            context.beginPath();
            context.moveTo(12, 20);
            context.bezierCurveTo(11.5, 15, 10, 11, 6, 7);
            context.stroke();
            context.beginPath();
            context.moveTo(12, 15);
            context.bezierCurveTo(13, 10, 16, 7, 20, 6);
            context.stroke();
            context.beginPath();
            context.moveTo(7, 8);
            context.bezierCurveTo(3, 7, 3, 3, 7, 3);
            context.bezierCurveTo(11, 3, 11, 7, 7, 8);
            if (root.active)
                context.fill();
            else
                context.stroke();
            context.beginPath();
            context.moveTo(18, 7);
            context.bezierCurveTo(14, 7, 14, 3, 18, 3);
            context.bezierCurveTo(22, 3, 22, 6, 18, 7);
            if (root.active)
                context.fill();
            else
                context.stroke();
        } else if (root.kind === "performance") {
            line(context, [[4, 19], [4, 12], [8, 12], [8, 19]]);
            line(context, [[10, 19], [10, 8], [14, 8], [14, 19]]);
            line(context, [[16, 19], [16, 4], [20, 4], [20, 19]]);
            line(context, [[3, 19], [21, 19]]);
        } else if (root.kind === "media") {
            line(context, [[9, 17], [9, 6], [19, 4], [19, 15]]);
            line(context, [[9, 8], [19, 6]]);
            circle(context, 6.5, 18, 2.7, root.active);
            circle(context, 16.5, 16, 2.7, root.active);
        } else if (root.kind === "controls") {
            line(context, [[4, 6], [20, 6]]);
            line(context, [[4, 12], [20, 12]]);
            line(context, [[4, 18], [20, 18]]);
            circle(context, 9, 6, 2, true);
            circle(context, 16, 12, 2, true);
            circle(context, 11, 18, 2, true);
        } else if (root.kind === "screenshot") {
            context.strokeRect(4, 6, 16, 13);
            line(context, [[8, 6], [9.5, 3.8], [14.5, 3.8], [16, 6]]);
            circle(context, 12, 12.5, 3.2, false);
        } else if (root.kind === "record") {
            circle(context, 12, 12, 8, false);
            circle(context, 12, 12, root.active ? 5.1 : 3.2, true);
        } else if (root.kind === "notifications") {
            context.beginPath();
            context.moveTo(5.5, 17);
            context.bezierCurveTo(7, 15.5, 7.2, 13.5, 7.2, 10);
            context.bezierCurveTo(7.2, 6.8, 9.2, 4.5, 12, 4.5);
            context.bezierCurveTo(14.8, 4.5, 16.8, 6.8, 16.8, 10);
            context.bezierCurveTo(16.8, 13.5, 17, 15.5, 18.5, 17);
            context.closePath();
            if (root.active)
                context.fill();
            else
                context.stroke();
            context.beginPath();
            context.arc(12, 17.5, 2.5, 0.2, Math.PI - 0.2);
            context.stroke();
        } else if (root.kind === "calendar") {
            context.strokeRect(4, 5, 16, 15);
            line(context, [[4, 9], [20, 9]]);
            line(context, [[8, 3], [8, 7]]);
            line(context, [[16, 3], [16, 7]]);
            circle(context, 9, 13, 1.1, true);
            circle(context, 15, 13, 1.1, true);
            circle(context, 9, 17, 1.1, true);
            circle(context, 15, 17, 1.1, true);
        } else if (root.kind === "user") {
            circle(context, 12, 8, 4, root.active);
            context.beginPath();
            context.arc(12, 21, 7, Math.PI * 1.1, Math.PI * 1.9);
            context.stroke();
        } else if (root.kind === "awake") {
            context.beginPath();
            context.moveTo(3, 12);
            context.bezierCurveTo(7, 6.5, 17, 6.5, 21, 12);
            context.bezierCurveTo(17, 17.5, 7, 17.5, 3, 12);
            context.closePath();
            context.stroke();
            circle(context, 12, 12, 3.1, root.active);
        } else {
            circle(context, 12, 12, 7, false);
            circle(context, 12, 12, 2.4, true);
        }
    }
}
