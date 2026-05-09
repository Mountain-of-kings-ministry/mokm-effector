import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root
    color: Theme.background
    clip: true

    // Background grid
    Canvas {
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            ctx.strokeStyle = Theme.border;
            ctx.lineWidth = 1;

            const gridSize = 24;

            for (let x = 0; x < width; x += gridSize) {
                ctx.beginPath();
                ctx.moveTo(x, 0);
                ctx.lineTo(x, height);
                ctx.stroke();
            }

            for (let y = 0; y < height; y += gridSize) {
                ctx.beginPath();
                ctx.moveTo(0, y);
                ctx.lineTo(width, y);
                ctx.stroke();
            }
        }
    }

    // Connection lines
    Canvas {
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            ctx.strokeStyle = Theme.accent;
            ctx.lineWidth = 3;

            drawConnection(260, 120, 420, 180);
            drawConnection(260, 120, 420, 320);

            function drawConnection(x1, y1, x2, y2) {
                ctx.beginPath();
                ctx.moveTo(x1, y1);

                const cp1x = x1 + 80;
                const cp1y = y1;

                const cp2x = x2 - 80;
                const cp2y = y2;

                ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x2, y2);

                ctx.stroke();
            }
        }
    }

    // Node 1
    Rectangle {
        x: 80
        y: 70
        width: 180
        height: 100
        radius: 8

        color: Theme.secondary
        border.color: Theme.border
        border.width: 1

        Column {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                width: parent.width
                height: 32
                radius: 8
                color: Theme.primary

                Text {
                    anchors.centerIn: parent
                    text: "Input Node"
                    color: Theme.background
                    font.bold: true
                }
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 12
                spacing: 10

                Repeater {
                    model: ["Image", "Mask"]

                    delegate: Row {
                        spacing: 8

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: Theme.accent
                        }

                        Text {
                            text: modelData
                            color: Theme.foreground
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }

    // Node 2
    Rectangle {
        x: 420
        y: 140
        width: 180
        height: 110
        radius: 8

        color: Theme.secondary
        border.color: Theme.border
        border.width: 1

        Column {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                width: parent.width
                height: 32
                radius: 8
                color: Theme.accent

                Text {
                    anchors.centerIn: parent
                    text: "Blur Effect"
                    color: Theme.foreground
                    font.bold: true
                }
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 12
                spacing: 10

                Repeater {
                    model: ["Radius", "Strength"]

                    delegate: Row {
                        spacing: 8

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: Theme.primary
                        }

                        Text {
                            text: modelData
                            color: Theme.foreground
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }

    // Node 3
    Rectangle {
        x: 420
        y: 290
        width: 180
        height: 110
        radius: 8

        color: Theme.secondary
        border.color: Theme.border
        border.width: 1

        Column {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                width: parent.width
                height: 32
                radius: 8
                color: Theme.success

                Text {
                    anchors.centerIn: parent
                    text: "Color Adjust"
                    color: Theme.background
                    font.bold: true
                }
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 12
                spacing: 10

                Repeater {
                    model: ["Exposure", "Contrast"]

                    delegate: Row {
                        spacing: 8

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: Theme.warning
                        }

                        Text {
                            text: modelData
                            color: Theme.foreground
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }

    // Top toolbar
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 42

        color: Theme.secondary
        border.color: Theme.border

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 12
            spacing: 12

            Repeater {
                model: ["Select", "Move", "Connect", "Delete"]

                delegate: Rectangle {
                    width: 70
                    height: 28
                    radius: 6

                    color: Theme.muted

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: Theme.foreground
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
