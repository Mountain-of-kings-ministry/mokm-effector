import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root
    color: Theme.background
    clip: true

    property int timelineHeight: 60
    property int rulerHeight: 30

    // Top toolbar
    Rectangle {
        id: toolbar
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
                model: ["Select", "Move", "Add Key", "Delete"]

                delegate: Rectangle {
                    width: 80
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

    // Left property panel
    Rectangle {
        id: propertyPanel
        anchors.top: toolbar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        width: 220

        color: Theme.secondary
        border.color: Theme.border

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Text {
                text: "Animated Properties"
                color: Theme.foreground
                font.pixelSize: 14
                font.bold: true
            }

            Repeater {
                model: ["Position X", "Position Y", "Scale", "Rotation", "Opacity"]

                delegate: Rectangle {
                    width: parent.width
                    height: 36
                    radius: 6

                    color: index === 0 ? Theme.selected : Theme.muted

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
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

    // Timeline area
    Rectangle {
        id: timelineArea

        anchors.top: toolbar.bottom
        anchors.left: propertyPanel.right
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        color: Theme.background

        // Time ruler
        Rectangle {
            id: ruler
            anchors.top: parent.top
            width: parent.width
            height: rulerHeight

            color: Theme.secondary
            border.color: Theme.border

            Repeater {
                model: 20

                delegate: Item {
                    x: index * 80
                    width: 80
                    height: parent.height

                    Rectangle {
                        width: 1
                        height: parent.height
                        color: Theme.border
                    }

                    Text {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.topMargin: 6

                        text: (index * 10).toString()
                        color: Theme.mutedForeground
                        font.pixelSize: 10
                    }
                }
            }
        }

        // Grid background
        Canvas {
            anchors.top: ruler.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                ctx.strokeStyle = Theme.border;
                ctx.lineWidth = 1;

                // Vertical lines
                for (let x = 0; x < width; x += 80) {
                    ctx.beginPath();
                    ctx.moveTo(x, 0);
                    ctx.lineTo(x, height);
                    ctx.stroke();
                }

                // Horizontal lines
                for (let y = 0; y < height; y += 60) {
                    ctx.beginPath();
                    ctx.moveTo(0, y);
                    ctx.lineTo(width, y);
                    ctx.stroke();
                }
            }
        }

        // Curves canvas
        Canvas {
            anchors.top: ruler.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                // Curve 1
                ctx.strokeStyle = Theme.primary;
                ctx.lineWidth = 3;

                ctx.beginPath();
                ctx.moveTo(40, 220);

                ctx.bezierCurveTo(180, 120, 300, 280, 420, 180);

                ctx.bezierCurveTo(520, 100, 700, 220, 860, 140);

                ctx.stroke();

                // Curve 2
                ctx.strokeStyle = Theme.accent;

                ctx.beginPath();
                ctx.moveTo(40, 320);

                ctx.bezierCurveTo(160, 260, 340, 380, 520, 300);

                ctx.bezierCurveTo(620, 240, 760, 360, 920, 260);

                ctx.stroke();
            }
        }

        // Keyframes
        Repeater {
            model: [
                {
                    x: 40,
                    y: 220
                },
                {
                    x: 220,
                    y: 180
                },
                {
                    x: 420,
                    y: 180
                },
                {
                    x: 620,
                    y: 150
                },
                {
                    x: 860,
                    y: 140
                },
                {
                    x: 40,
                    y: 320
                },
                {
                    x: 260,
                    y: 340
                },
                {
                    x: 520,
                    y: 300
                },
                {
                    x: 760,
                    y: 330
                },
                {
                    x: 920,
                    y: 260
                }
            ]

            delegate: Rectangle {
                width: 12
                height: 12

                x: modelData.x - 6
                y: rulerHeight + modelData.y - 6

                rotation: 45
                radius: 2

                color: index < 5 ? Theme.primary : Theme.accent

                border.color: Theme.foreground
                border.width: 1
            }
        }

        // Playhead
        Rectangle {
            x: 320
            y: rulerHeight

            width: 2
            height: parent.height - rulerHeight

            color: Theme.error

            Rectangle {
                width: 14
                height: 14
                radius: 7

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: -7

                color: Theme.error
            }
        }
    }
}
