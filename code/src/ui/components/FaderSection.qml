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
                color: showAutomation ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : "transparent"
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
                color: animateFaders ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : "transparent"
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
                Layout.preferredHeight: 120
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
                Layout.preferredHeight: 120
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
        id: unitRoot
        property string label: ""
        property real from: 0
        property real to: 1
        property real value: 0.5
        property color color: Theme.accent
        property bool animateValue: false
        property bool showAutomation: true
        property bool keyframeEnabled: false

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
                    anchors.margins: 4
                    spacing: 4

                    // Value label
                    Text {
                        text: label
                        color: Theme.mutedForeground
                        font.pixelSize: 9
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 8

                        // Level meter (thin line)
                        Rectangle {
                            width: 3
                            Layout.fillHeight: true
                            color: "#1a1a1a"
                            radius: 1
                            
                            // Mock level fill
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: parent.height * (unitRoot.animateValue ? (0.2 + Math.random() * 0.4) : 0.0)
                                color: "#22c55e"
                                radius: 1
                                visible: unitRoot.animateValue
                                
                                Behavior on height {
                                    NumberAnimation { duration: 100 }
                                }
                            }
                        }

                        // Slider area
                        Slider {
                            id: slider
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            orientation: Qt.Vertical
                            from: unitRoot.from
                            to: unitRoot.to
                            value: unitRoot.value
                            stepSize: 0.01

                            onMoved: {
                                unitRoot.value = value;
                            }

                            // Custom Track
                            background: Rectangle {
                                x: slider.leftPadding + slider.availableWidth / 2 - width / 2
                                y: slider.topPadding
                                implicitWidth: 6
                                width: implicitWidth
                                height: slider.availableHeight
                                radius: 3
                                color: "#1a1a1a"

                                // Fader path indicator
                                Rectangle {
                                    width: parent.width
                                    height: (1.0 - slider.visualPosition) * parent.height
                                    anchors.bottom: parent.bottom
                                    color: unitRoot.color
                                    opacity: 0.2
                                    radius: 3
                                }
                            }

                            // Custom Handle (SVG Nub)
                            handle: Item {
                                x: slider.leftPadding + slider.availableWidth / 2 - width / 2
                                y: slider.topPadding + slider.visualPosition * (slider.availableHeight - height)
                                implicitWidth: 32
                                implicitHeight: 18
                                width: implicitWidth
                                height: implicitHeight

                                Image {
                                    anchors.fill: parent
                                    source: "qrc:/slide-nub.svg"
                                    fillMode: Image.PreserveAspectFit
                                    cache: true
                                }
                            }
                        }
                    }

                    // Numeric value
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: unitRoot.value.toFixed(2)
                        color: Theme.foreground
                        font.pixelSize: 9
                        font.family: "Monospace"
                    }
                }
            }
        }
    }
}
