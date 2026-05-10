import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import mokm_effector

Rectangle {
    id: root
    color: Theme.background
    clip: true

    property var timelineModel: null
    property var selectedClip: null

    // Split view state
    property bool showSplitView: true

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ==================== HEADER ====================
        Rectangle {
            Layout.fillWidth: true
            height: 56
            color: Theme.secondaryHover

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Text {
                    text: selectedClip ? selectedClip.name + " • Color Grading" : "Color Grading Editor"
                    color: Theme.foreground
                    font.pixelSize: 16
                    font.bold: true
                }

                Item {
                    Layout.fillWidth: true
                }

                Switch {
                    text: "Split View"
                    checked: root.showSplitView
                    onCheckedChanged: root.showSplitView = checked
                }

                Button {
                    text: "Reset All"
                    onClicked: console.log("All color grading reset")
                }

                Button {
                    text: "Save Preset"
                    onClicked: console.log("Preset saved")
                }

                ComboBox {
                    model: ["No LUT", "Film Stock", "Cinematic Teal", "Vintage", "Blockbuster", "Custom"]
                }
            }
        }

        // ==================== MAIN CONTENT ====================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ==================== PREVIEW AREA ====================
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#111111"

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Before
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#1a1a1a"
                        visible: root.showSplitView

                        Image {
                            anchors.centerIn: parent
                            width: parent.width * 0.9
                            height: parent.height * 0.9
                            fillMode: Image.PreserveAspectFit
                            source: "qrc:/placeholders/original.jpg"
                        }
                        Text {
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.topMargin: 12
                            text: "ORIGINAL"
                            color: "#888"
                            font.pixelSize: 11
                        }
                    }

                    // After (Graded)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#1a1a1a"

                        Image {
                            anchors.centerIn: parent
                            width: parent.width * 0.9
                            height: parent.height * 0.9
                            fillMode: Image.PreserveAspectFit
                            source: "qrc:/placeholders/color-graded.jpg"
                        }
                        Text {
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.topMargin: 12
                            text: "GRADED"
                            color: Theme.accent
                            font.pixelSize: 11
                        }
                    }
                }

                // Scopes (Histogram + Waveform)
                Row {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 90
                    spacing: 1

                    Rectangle {
                        width: parent.width / 2
                        height: parent.height
                        color: Qt.alpha(Theme.secondary, 0.9)
                        Text {
                            anchors.centerIn: parent
                            text: "Histogram\n[Placeholder]"
                            color: Theme.mutedForeground
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    Rectangle {
                        width: parent.width / 2
                        height: parent.height
                        color: Qt.alpha(Theme.secondary, 0.9)
                        Text {
                            anchors.centerIn: parent
                            text: "Waveform / Vectorscope\n[Placeholder]"
                            color: Theme.mutedForeground
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }

            // ==================== CONTROLS PANEL ====================
            Rectangle {
                Layout.preferredWidth: 340
                Layout.fillHeight: true
                color: Theme.secondary
                border.color: Theme.border

                ScrollView {
                    anchors.fill: parent
                    clip: true
                    padding: 12

                    ColumnLayout {
                        width: parent.width
                        spacing: 20

                        // Basic Correction
                        GroupBox {
                            title: "Basic Correction"
                            Layout.fillWidth: true

                            GridLayout {
                                columns: 2
                                columnSpacing: 12
                                rowSpacing: 12
                                width: parent.width

                                Text {
                                    text: "Exposure"
                                    color: Theme.mutedForeground
                                }
                                Slider {
                                    Layout.fillWidth: true
                                    from: -3
                                    to: 3
                                    value: 0.2
                                }

                                Text {
                                    text: "Contrast"
                                    color: Theme.mutedForeground
                                }
                                Slider {
                                    Layout.fillWidth: true
                                    from: -50
                                    to: 50
                                    value: 12
                                }

                                Text {
                                    text: "Saturation"
                                    color: Theme.mutedForeground
                                }
                                Slider {
                                    Layout.fillWidth: true
                                    from: 0
                                    to: 200
                                    value: 115
                                }

                                Text {
                                    text: "Temperature"
                                    color: Theme.mutedForeground
                                }
                                Slider {
                                    Layout.fillWidth: true
                                    from: -100
                                    to: 100
                                    value: 8
                                }
                            }
                        }

                        // Color Wheels
                        GroupBox {
                            title: "Color Wheels"
                            Layout.fillWidth: true

                            RowLayout {
                                spacing: 10
                                Repeater {
                                    model: ["Shadows", "Midtones", "Highlights"]

                                    delegate: ColumnLayout {
                                        spacing: 6
                                        Text {
                                            text: modelData
                                            color: Theme.foreground
                                            font.pixelSize: 12
                                        }
                                        // ColorWheel {
                                        //     width: 78
                                        //     height: 78
                                        // }

                                        ColorDialog {
    id: colorDialog
    title: "Please choose a color"
    onAccepted: console.log("Selected color:", colorDialog.color)
}
                                    }
                                }
                            }
                        }

                        // Curves
                        GroupBox {
                            title: "Curves"
                            Layout.fillWidth: true
                            height: 160

                            Rectangle {
                                anchors.fill: parent
                                color: Theme.secondaryHover
                                radius: 6

                                Text {
                                    anchors.centerIn: parent
                                    text: "RGB / Luma Curves\n(Interactive - Coming Soon)"
                                    color: Theme.mutedForeground
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        // Keyframeable Parameters
                        GroupBox {
                            title: "Keyframe Parameters"
                            Layout.fillWidth: true

                            ColumnLayout {
                                spacing: 12
                                width: parent.width

                                Repeater {
                                    model: [
                                        {
                                            name: "Lift",
                                            value: 0.0
                                        },
                                        {
                                            name: "Gamma",
                                            value: 1.0
                                        },
                                        {
                                            name: "Gain",
                                            value: 1.1
                                        }
                                    ]

                                    delegate: RowLayout {
                                        Text {
                                            text: modelData.name
                                            color: Theme.mutedForeground
                                            Layout.preferredWidth: 60
                                        }
                                        Slider {
                                            Layout.fillWidth: true
                                            from: -1
                                            to: 2
                                            value: modelData.value
                                        }
                                        Button {
                                            text: "◆"
                                            flat: true
                                            onClicked: console.log("Keyframe added for", modelData.name)
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }
                    }
                }
            }
        }
    }
}
