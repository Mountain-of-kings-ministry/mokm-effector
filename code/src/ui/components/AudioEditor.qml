import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root
    color: Theme.background
    clip: true

    property var timelineModel: null
    property var selectedClip: null        // The currently selected audio strip
    property real pixelPerFrame: 8
    property real zoomLevel: 1.0

    // Demo waveform data (replace with real data from backend later)
    property var waveformData: []

    Component.onCompleted: {
        // Generate fake waveform for demo
        waveformData = [];
        for (let i = 0; i < 1200; i++) {
            let value = Math.sin(i * 0.08) * 0.7 + Math.random() * 0.3;
            waveformData.push(Math.max(-1.0, Math.min(1.0, value)));
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ==================== HEADER ====================
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: Theme.secondaryHover

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Text {
                    text: selectedClip ? selectedClip.name : "No Audio Clip Selected"
                    color: Theme.foreground
                    font.pixelSize: 16
                    font.bold: true
                }

                Item {
                    Layout.fillWidth: true
                }

                ComboBox {
                    model: ["Normal", "Voice", "Music", "SFX"]
                    currentIndex: 1
                }

                Button {
                    text: "Add Effect"
                    icon.source: "qrc:/icons/plus"
                    onClicked: effectMenu.popup()
                }

                Button {
                    text: "Render"
                    highlighted: true
                }
            }
        }

        // ==================== WAVEFORM VIEW ====================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                color: Theme.secondary

                // Waveform Canvas
                Canvas {
                    id: waveform
                    anchors.fill: parent
                    anchors.bottomMargin: 140

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);

                        var w = width;
                        var h = height;
                        var center = h / 2;
                        var step = Math.max(1, Math.floor(waveformData.length / w));

                        ctx.strokeStyle = "#67e8f9";
                        ctx.lineWidth = 1.8;
                        ctx.beginPath();

                        for (var x = 0; x < w; x++) {
                            var idx = Math.floor(x * step);
                            if (idx >= waveformData.length)
                                break;
                            var sample = waveformData[idx];
                            var y = center - sample * center * 0.85;
                            if (x === 0)
                                ctx.moveTo(x, y);
                            else
                                ctx.lineTo(x, y);
                        }
                        ctx.stroke();

                        // Zero line
                        ctx.strokeStyle = Qt.rgba(255, 255, 255, 0.08);
                        ctx.lineWidth = 1;
                        ctx.beginPath();
                        ctx.moveTo(0, center);
                        ctx.lineTo(w, center);
                        ctx.stroke();
                    }
                }

                // Playhead
                Rectangle {
                    x: (timelineModel?.currentFrame ?? 0) * pixelPerFrame * zoomLevel
                    width: 3
                    height: parent.height
                    color: Theme.accent
                    z: 100
                }
            }

            // ==================== AUTOMATION LANES ====================
            Column {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 140

                AutomationLane {
                    width: parent.width
                    height: 46
                    label: "Volume"
                    color: "#c084fc"
                    unit: "dB"
                }

                AutomationLane {
                    width: parent.width
                    height: 46
                    label: "Pan"
                    color: "#fb923c"
                    minValue: -100
                    maxValue: 100
                    defaultValue: 0
                    unit: "%"
                }

                AutomationLane {
                    width: parent.width
                    height: 48
                    label: "Reverb Send"
                    color: "#4ade80"
                    defaultValue: 20
                }
            }
        }

        // ==================== EFFECTS CHAIN ====================
        Rectangle {
            Layout.fillWidth: true
            height: 210
            color: Theme.secondary
            border.color: Theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    text: "Effects Chain"
                    font.bold: true
                    color: Theme.foreground
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: ["EQ Eight", "Dynamic Compressor", "Convolution Reverb", "Limiter"]

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 48
                        radius: 6
                        color: Theme.secondaryHover
                        border.color: index === 0 ? Theme.accent : "transparent"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12

                            Text {
                                text: modelData
                                color: Theme.foreground
                                font.pixelSize: 13
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Switch {
                                checked: true
                            }

                            Button {
                                text: "Edit"
                                flat: true
                                onClicked: console.log("Opening properties for", modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    // ==================== ADD EFFECT MENU ====================
    Menu {
        id: effectMenu
        MenuItem {
            text: "Equalizer"
            onTriggered: console.log("EQ added")
        }
        MenuItem {
            text: "Compressor"
            onTriggered: console.log("Compressor added")
        }
        MenuItem {
            text: "Reverb"
            onTriggered: console.log("Reverb added")
        }
        MenuItem {
            text: "Delay / Echo"
            onTriggered: console.log("Delay added")
        }
        MenuItem {
            text: "Limiter"
            onTriggered: console.log("Limiter added")
        }
        MenuItem {
            text: "Pitch Shifter"
            onTriggered: console.log("Pitch added")
        }
        MenuItem {
            text: "Noise Gate"
            onTriggered: console.log("Gate added")
        }
    }

    // ==================== AUTOMATION LANE COMPONENT ====================
    component AutomationLane: Rectangle {
        id: lane
        color: Theme.secondaryHover
        border.color: Theme.border
        border.width: 1

        property string label: "Parameter"
        property color laneColor: "#a78bfa"
        property real minValue: 0
        property real maxValue: 1
        property real defaultValue: 0.7
        property string unit: ""

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 12

            Text {
                text: lane.label
                color: Theme.foreground
                font.pixelSize: 12
                Layout.preferredWidth: 110
            }

            // Simple automation curve (demo)
            Canvas {
                Layout.fillWidth: true
                Layout.fillHeight: true

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    ctx.strokeStyle = lane.laneColor;
                    ctx.lineWidth = 2.5;
                    ctx.beginPath();

                    for (var i = 0; i < width; i += 8) {
                        var progress = i / width;
                        var y = height * (1 - (defaultValue + Math.sin(progress * 8) * 0.2));
                        if (i === 0)
                            ctx.moveTo(i, y);
                        else
                            ctx.lineTo(i, y);
                    }
                    ctx.stroke();
                }
            }

            Text {
                text: defaultValue.toFixed(1) + lane.unit
                color: Theme.mutedForeground
                font.pixelSize: 11
                Layout.preferredWidth: 50
            }
        }
    }
}
