import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root
    color: Theme.secondary

    property var timelineModel: null
    property var target: null          // selected track/layer/strip
    property var masterVolume: _audioEngine ? _audioEngine.masterVolume : 1.0
    property var masterPan: _audioEngine ? _audioEngine.masterPan : 0.0
    property bool showAutomation: true
    property bool animateFaders: false

    signal masterVolumeChanged(var v)
    signal masterPanChanged(var v)
    signal showAutomationToggled()
    signal animateFadersToggled()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

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
            Rectangle {
                width: 28; height: 28; radius: 4
                color: showAutomation ? Qt.alpha(Theme.accent, 0.2) : "transparent"
                border.color: showAutomation ? Theme.accent : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\u2630"
                    color: showAutomation ? Theme.accent : Theme.mutedForeground
                    font.pixelSize: 14
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        showAutomation = !showAutomation;
                        root.showAutomationToggled();
                    }
                    ToolTip {
                        text: "Toggle Automation View"
                        delay: 800
                        visible: parent.containsMouse
                    }
                }
            }

            // Animate faders toggle
            Rectangle {
                width: 28; height: 28; radius: 4
                color: animateFaders ? Qt.alpha(Theme.accent, 0.2) : "transparent"
                border.color: animateFaders ? Theme.accent : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\u266B"
                    color: animateFaders ? Theme.accent : Theme.mutedForeground
                    font.pixelSize: 14
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        animateFaders = !animateFaders;
                        root.animateFadersToggled();
                    }
                    ToolTip {
                        text: "Animate Faders"
                        delay: 800
                        visible: parent.containsMouse
                    }
                }
            }
        }

        // Master Fader
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "MASTER"
                color: Theme.mutedForeground
                font.pixelSize: 9
                font.bold: true
            }

            FaderUnit {
                id: masterFader
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                label: "Vol"
                value: root.masterVolume
                from: 0; to: 1
                color: "#eab308"
                animateValue: root.animateFaders && root.timelineModel && root.timelineModel.playing
                showAutomation: root.showAutomation
                onValueChanged: {
                    if (_audioEngine)
                        _audioEngine.masterVolume = value;
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                FaderUnit {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    label: "Pan"
                    value: root.masterPan
                    from: -1; to: 1
                    color: "#f97316"
                    animateValue: root.animateFaders && root.timelineModel && root.timelineModel.playing
                    showAutomation: root.showAutomation
                    onValueChanged: {
                        if (_audioEngine)
                            _audioEngine.masterPan = value;
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1; color: Theme.border
        }

        // Track Fader
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: target ? (target.name || "TRACK") : "NO TARGET"
                color: Theme.mutedForeground
                font.pixelSize: 9
                font.bold: true
            }

            FaderUnit {
                id: trackFader
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                label: "Vol"
                value: target ? target.opacity : 1.0
                from: 0; to: 1
                color: "#60a5fa"
                animateValue: root.animateFaders && root.timelineModel && root.timelineModel.playing
                showAutomation: root.showAutomation
                keyframeEnabled: true
                onValueChanged: {
                    if (target) target.opacity = value;
                    if (root.timelineModel)
                        root.timelineModel.tryAutoKeyframe(target, "opacity", value);
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                FaderUnit {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    label: "Pan"
                    value: target ? target.pan : 0.0
                    from: -1; to: 1
                    color: "#fb923c"
                    animateValue: root.animateFaders && root.timelineModel && root.timelineModel.playing
                    showAutomation: root.showAutomation
                    keyframeEnabled: true
                    onValueChanged: {
                        if (target) target.pan = value;
                        if (root.timelineModel)
                            root.timelineModel.tryAutoKeyframe(target, "pan", value);
                    }
                }
            }
        }
    }

    component FaderUnit: ColumnLayout {
        property string label: ""
        property real from: 0
        property real to: 1
        property real value: 0.5
        property color color: Theme.accent
        property bool animateValue: false
        property bool showAutomation: true
        property bool keyframeEnabled: false

        signal valueChanged()

        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.background
                radius: 4
                border.color: Theme.border
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 0

                    // Value label
                    Text {
                        text: label
                        color: Theme.mutedForeground
                        font.pixelSize: 9
                    }

                    Item { Layout.fillHeight: true }

                    // Slider area
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: parent.height * 0.65
                        Layout.maximumHeight: 80
                        color: Theme.input
                        radius: 3

                        Slider {
                            id: slider
                            anchors.fill: parent
                            anchors.margins: 2
                            orientation: Qt.Vertical
                            from: parent.parent.parent.from
                            to: parent.parent.parent.to
                            value: parent.parent.parent.value
                            // Animate when playing
                            Behavior on value {
                                enabled: animateValue
                                NumberAnimation { duration: 100 }
                            }
                            onMoved: {
                                parent.parent.parent.value = value;
                                parent.parent.parent.valueChanged();
                            }

                            background: Rectangle {
                                x: slider.leftPadding + slider.availableWidth / 2 - width / 2
                                y: slider.topPadding
                                implicitWidth: 4
                                width: implicitWidth
                                height: slider.availableHeight
                                radius: 2
                                color: Theme.border

                                Rectangle {
                                    width: parent.width
                                    height: {
                                        var normalized = (slider.visualPosition - 0) / (1 - 0);
                                        return normalized * parent.height;
                                    }
                                    anchors.bottom: parent.bottom
                                    color: parent.parent.parent.parent.color
                                    radius: 2
                                }
                            }
                        }
                    }

                    // Value readout + keyframe
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: slider.value.toFixed(2)
                            color: Theme.foreground
                            font.pixelSize: 9
                            font.family: "Monospace"
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            id: kfBtn
                            visible: keyframeEnabled
                            width: 14; height: 14
                            text: "\u25C6"
                            flat: true
                            font.pixelSize: 8
                            contentItem: Text {
                                text: parent.text
                                color: hasKF ? Theme.accent : Theme.mutedForeground
                                font.pixelSize: 8
                            }
                            background: Rectangle {
                                color: "transparent"
                            }
                        }
                    }
                }
            }

            // Automation lane (right side)
            Rectangle {
                visible: showAutomation
                Layout.preferredWidth: 40
                Layout.fillHeight: true
                color: Theme.background
                radius: 4
                border.color: Theme.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 2

                    Text {
                        text: "A"
                        color: Theme.mutedForeground
                        font.pixelSize: 8
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Theme.input
                        radius: 2

                        Rectangle {
                            width: parent.width
                            height: parent.height * clamp((value - from) / (to - from), 0, 1)
                            anchors.bottom: parent.bottom
                            color: parent.parent.parent.parent.color
                            opacity: 0.3
                            radius: 2
                        }

                        function clamp(v, min, max) { return Math.max(min, Math.min(max, v)); }
                    }
                }
            }
        }
    }
}
