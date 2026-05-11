import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import mokm_effector

Dialog {
    id: root
    title: qsTr("Preferences")
    modal: true
    anchors.centerIn: parent
    width: 680
    height: 460

    property var project: null

    background: Rectangle {
        color: Theme.background
        border.color: Theme.border
        border.width: 1
        radius: 8
    }

    header: Rectangle {
        color: Theme.secondary
        height: 40
        radius: 8

        Rectangle {
            height: 8; width: parent.width
            anchors.bottom: parent.bottom
            color: Theme.secondary
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            spacing: 8

            Text {
                text: root.title
                color: Theme.foreground
                font.pixelSize: 14
                font.bold: true
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        // ── Left navigation ──
        Rectangle {
            Layout.preferredWidth: 160
            Layout.fillHeight: true
            color: Theme.secondary

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 2

                Repeater {
                    model: [
                        { icon: "⚙",   label: "General" },
                        { icon: "📁",  label: "Project" },
                        { icon: "✂",   label: "Editing" },
                        { icon: "🔊",  label: "Audio" },
                        { icon: "🎬",  label: "Rendering" },
                        { icon: "🖥",  label: "System" }
                    ]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: 4
                        color: navMouse.containsMouse
                            ? Theme.secondaryHover
                            : (navList.currentIndex === index ? Theme.muted : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            spacing: 8
                            Text { text: modelData.icon; font.pixelSize: 12 }
                            Text {
                                text: modelData.label
                                color: navList.currentIndex === index ? Theme.accent : Theme.foreground
                                font.pixelSize: 12
                                font.bold: navList.currentIndex === index
                            }
                        }

                        MouseArea {
                            id: navMouse; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: navList.currentIndex = index
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // ── Separator ──
        Rectangle {
            width: 1
            Layout.fillHeight: true
            color: Theme.border
        }

        // ── Right content ──
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.background

            ScrollView {
                anchors.fill: parent
                anchors.margins: 16
                clip: true

                StackLayout {
                    id: stack
                    width: parent.width
                    currentIndex: navList.currentIndex

                    // ── Page 0: General ──
                    ColumnLayout {
                        spacing: 14
                        property string title: "General"
                        Text { text: "General Settings"; font.pixelSize: 14; font.bold: true; color: Theme.foreground }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Language"; color: Theme.mutedForeground; Layout.preferredWidth: 140 }
                            ComboBox {
                                Layout.fillWidth: true
                                model: ["en", "fr", "de", "es", "ja", "zh"]
                                currentIndex: {
                                    var idx = model.indexOf(AppSettings.language);
                                    return idx >= 0 ? idx : 0;
                                }
                                onActivated: AppSettings.language = model[currentIndex]
                            }
                        }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Theme"; color: Theme.mutedForeground; Layout.preferredWidth: 140 }
                            ComboBox {
                                Layout.fillWidth: true
                                model: ["Dark", "Light", "System"]
                                currentIndex: {
                                    var idx = model.indexOf(AppSettings.theme);
                                    return idx >= 0 ? idx : 0;
                                }
                                onActivated: AppSettings.theme = model[currentIndex]
                            }
                        }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Auto-Save Interval (min)"; color: Theme.mutedForeground; Layout.preferredWidth: 140 }
                            SpinBox {
                                from: 1; to: 60; value: AppSettings.autoSaveInterval
                                onValueChanged: AppSettings.autoSaveInterval = value
                            }
                        }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Undo Limit (steps)"; color: Theme.mutedForeground; Layout.preferredWidth: 140 }
                            SpinBox {
                                from: 5; to: 200; value: AppSettings.undoLimit
                                onValueChanged: AppSettings.undoLimit = value
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }

                    // ── Page 1: Project ──
                    ColumnLayout {
                        spacing: 14
                        Text { text: "Default Project Settings"; font.pixelSize: 14; font.bold: true; color: Theme.foreground }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Default Width"; color: Theme.mutedForeground; Layout.preferredWidth: 140 }
                            SpinBox { from: 1; to: 7680; value: AppSettings.defaultWidth; onValueChanged: AppSettings.defaultWidth = value }
                        }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Default Height"; color: Theme.mutedForeground; Layout.preferredWidth: 140 }
                            SpinBox { from: 1; to: 4320; value: AppSettings.defaultHeight; onValueChanged: AppSettings.defaultHeight = value }
                        }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Default FPS"; color: Theme.mutedForeground; Layout.preferredWidth: 140 }
                            SpinBox { from: 1; to: 240; value: AppSettings.defaultFps; onValueChanged: AppSettings.defaultFps = value; editable: true }
                        }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Default Duration (s)"; color: Theme.mutedForeground; Layout.preferredWidth: 140 }
                            SpinBox { from: 1; to: 600; value: AppSettings.defaultDuration / (AppSettings.defaultFps || 30); onValueChanged: AppSettings.defaultDuration = value * (AppSettings.defaultFps || 30) }
                        }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Color Space"; color: Theme.mutedForeground; Layout.preferredWidth: 140 }
                            ComboBox {
                                Layout.fillWidth: true
                                model: ["sRGB", "Rec.709", "DCI-P3"]
                                currentIndex: { var idx = model.indexOf(AppSettings.defaultColorSpace); return idx >= 0 ? idx : 0; }
                                onActivated: AppSettings.defaultColorSpace = model[currentIndex]
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }

                    // ── Page 2: Editing ──
                    ColumnLayout {
                        spacing: 14
                        Text { text: "Editing Preferences"; font.pixelSize: 14; font.bold: true; color: Theme.foreground }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Snap Threshold (px)"; color: Theme.mutedForeground; Layout.preferredWidth: 160 }
                            SpinBox { from: 1; to: 20; value: AppSettings.snapThreshold; onValueChanged: AppSettings.snapThreshold = value }
                        }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Timeline Scroll Speed"; color: Theme.mutedForeground; Layout.preferredWidth: 160 }
                            Slider {
                                Layout.fillWidth: true
                                from: 0.1; to: 5.0; stepSize: 0.1; value: AppSettings.timelineScrollSpeed
                                onValueChanged: AppSettings.timelineScrollSpeed = value
                            }
                        }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Default Keyframe Easing"; color: Theme.mutedForeground; Layout.preferredWidth: 160 }
                            ComboBox {
                                Layout.fillWidth: true
                                model: ["Linear", "Ease In", "Ease Out", "Ease Both"]
                                currentIndex: AppSettings.defaultKeyframeEasing
                                onActivated: AppSettings.defaultKeyframeEasing = currentIndex
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }

                    // ── Page 3: Audio ──
                    ColumnLayout {
                        spacing: 14
                        Text { text: "Audio Settings"; font.pixelSize: 14; font.bold: true; color: Theme.foreground }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Sample Rate (Hz)"; color: Theme.mutedForeground; Layout.preferredWidth: 140 }
                            ComboBox {
                                Layout.fillWidth: true
                                model: ["44100", "48000", "96000"]
                                currentIndex: { var idx = model.indexOf(String(AppSettings.audioSampleRate)); return idx >= 0 ? idx : 1; }
                                onActivated: AppSettings.audioSampleRate = parseInt(model[currentIndex])
                            }
                        }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Default Volume (%)"; color: Theme.mutedForeground; Layout.preferredWidth: 140 }
                            Slider {
                                Layout.fillWidth: true
                                from: 0; to: 100; value: AppSettings.defaultVolume * 100
                                onValueChanged: AppSettings.defaultVolume = value / 100
                            }
                        }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Audio Device"; color: Theme.mutedForeground; Layout.preferredWidth: 140 }
                            ComboBox {
                                Layout.fillWidth: true
                                model: ["Default", "System Default"]
                                currentIndex: { var idx = model.indexOf(AppSettings.audioDevice); return idx >= 0 ? idx : 0; }
                                onActivated: AppSettings.audioDevice = model[currentIndex]
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }

                    // ── Page 4: Rendering ──
                    ColumnLayout {
                        spacing: 14
                        Text { text: "Rendering & Export"; font.pixelSize: 14; font.bold: true; color: Theme.foreground }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "GPU Acceleration"; color: Theme.mutedForeground; Layout.preferredWidth: 140 }
                            Switch { checked: AppSettings.gpuAcceleration; onCheckedChanged: AppSettings.gpuAcceleration = checked }
                        }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Proxy Resolution"; color: Theme.mutedForeground; Layout.preferredWidth: 140 }
                            ComboBox {
                                Layout.fillWidth: true
                                model: ["Full", "1/2", "1/4", "1/8"]
                                currentIndex: { var idx = model.indexOf(AppSettings.proxyResolution); return idx >= 0 ? idx : 0; }
                                onActivated: AppSettings.proxyResolution = model[currentIndex]
                            }
                        }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Codec Preset"; color: Theme.mutedForeground; Layout.preferredWidth: 140 }
                            ComboBox {
                                Layout.fillWidth: true
                                model: ["ProRes", "H.264", "H.265"]
                                currentIndex: { var idx = model.indexOf(AppSettings.codecPreset); return idx >= 0 ? idx : 0; }
                                onActivated: AppSettings.codecPreset = model[currentIndex]
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }

                    // ── Page 5: System ──
                    ColumnLayout {
                        spacing: 14
                        Text { text: "System & Cache"; font.pixelSize: 14; font.bold: true; color: Theme.foreground }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Cache Location"; color: Theme.mutedForeground; Layout.preferredWidth: 100 }
                            TextField { Layout.fillWidth: true; text: AppSettings.cacheLocation; onTextChanged: AppSettings.cacheLocation = text }
                        }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Temp Files"; color: Theme.mutedForeground; Layout.preferredWidth: 100 }
                            TextField { Layout.fillWidth: true; text: AppSettings.tempLocation; onTextChanged: AppSettings.tempLocation = text }
                        }

                        RowLayout { spacing: 12; Layout.fillWidth: true
                            Text { text: "Log Level"; color: Theme.mutedForeground; Layout.preferredWidth: 100 }
                            ComboBox {
                                Layout.fillWidth: true
                                model: ["Debug", "Info", "Warning", "Error"]
                                currentIndex: { var idx = model.indexOf(AppSettings.logLevel); return idx >= 0 ? idx : 1; }
                                onActivated: AppSettings.logLevel = model[currentIndex]
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }

    // ── Left nav selection tracker ──
    Item {
        id: navList
        property int currentIndex: 0
    }

    // ── Footer ──
    footer: Rectangle {
        color: "transparent"
        height: 44

        RowLayout {
            anchors.fill: parent
            anchors.rightMargin: 16
            anchors.leftMargin: 16
            spacing: 8

            Button {
                text: "Reset All"
                onClicked: AppSettings.resetAll()
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Cancel"
                onClicked: root.close()
            }

            Button {
                text: "OK"
                highlighted: true
                onClicked: {
                    AppSettings.sync();
                    root.close();
                }
            }
        }
    }
}
