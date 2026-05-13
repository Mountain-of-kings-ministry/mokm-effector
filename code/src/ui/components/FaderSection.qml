import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root
    color: Theme.secondary

    property var timelineModel: null
    property var target: null
    property var masterVolume: _audioEngine ? _audioEngine.masterVolume : 1.0
    property var masterPan: _audioEngine ? _audioEngine.masterPan : 0.0
    property bool showAutomation: true
    property bool animateFaders: false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Faders"
                color: Theme.foreground
                font.pixelSize: 12
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            // Automation toggle
            Image {
                source: "qrc:/icons/outline/menu-2.svg"
                width: 20; height: 20
                sourceSize: Qt.size(20, 20)
                opacity: showAutomation ? 1.0 : 0.5
                MouseArea { anchors.fill: parent; onClicked: showAutomation = !showAutomation }
            }

            // Animate faders toggle
            Image {
                source: "qrc:/icons/outline/music.svg"
                width: 20; height: 20
                sourceSize: Qt.size(20, 20)
                opacity: animateFaders ? 1.0 : 0.5
                MouseArea { anchors.fill: parent; onClicked: animateFaders = !animateFaders }
            }
        }

        // Faders Area
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // Master Channel
            FaderColumn {
                label: "MASTER"
                vol: root.masterVolume
                pan: root.masterPan
                color: "#eab308"
                animateValue: root.animateFaders && root.timelineModel && root.timelineModel.playing
                onVolChanged: if (_audioEngine) _audioEngine.masterVolume = vol
                onPanChanged: if (_audioEngine) _audioEngine.masterPan = pan
            }

            // Track Channel
            FaderColumn {
                label: target ? target.name : "TRACK"
                vol: target ? target.opacity : 1.0
                pan: target ? target.pan : 0.0
                color: "#60a5fa"
                animateValue: root.animateFaders && root.timelineModel && root.timelineModel.playing
                onVolChanged: {
                    if (target) {
                        target.opacity = vol;
                        if (root.timelineModel) root.timelineModel.tryAutoKeyframe(target, "opacity", vol);
                    }
                }
                onPanChanged: {
                    if (target) {
                        target.pan = pan;
                        if (root.timelineModel) root.timelineModel.tryAutoKeyframe(target, "pan", pan);
                    }
                }
            }
        }
    }

    component FaderColumn: ColumnLayout {
        id: colRoot
        property string label: ""
        property real vol: 0.5
        property real pan: 0.0
        property color color: Theme.accent
        property bool animateValue: false
        
        spacing: 8
        Layout.fillHeight: true
        Layout.preferredWidth: 60

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: label
            color: Theme.foreground
            font.pixelSize: 10
            font.bold: true
        }

        // Pan Knob
        Image {
            Layout.alignment: Qt.AlignHCenter
            source: "qrc:/circular-numb.svg"
            width: 32; height: 32
            rotation: pan * 45
            MouseArea {
                anchors.fill: parent
                onPositionChanged: function(mouse) {
                    var delta = (mouse.y - height/2) / height;
                    colRoot.pan = Math.max(-1, Math.min(1, pan - delta));
                }
            }
        }

        // Fader
        Slider {
            id: faderSlider
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            orientation: Qt.Vertical
            from: 0; to: 1
            value: vol
            onMoved: colRoot.vol = value
            
            background: Rectangle {
                x: faderSlider.leftPadding + faderSlider.availableWidth / 2 - width / 2
                implicitWidth: 10
                height: faderSlider.availableHeight
                radius: 5
                color: "#1a1a1a"
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.height * faderSlider.visualPosition
                    color: colRoot.color
                    opacity: 0.3
                    radius: 5
                }
            }

            handle: Image {
                x: faderSlider.leftPadding + faderSlider.availableWidth / 2 - width / 2
                y: faderSlider.topPadding + faderSlider.visualPosition * (faderSlider.availableHeight - height)
                width: 48; height: 24
                source: "qrc:/slide-nub.svg"
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: vol.toFixed(2)
            color: Theme.foreground
            font.pixelSize: 10
            font.family: "Monospace"
        }
    }
}
