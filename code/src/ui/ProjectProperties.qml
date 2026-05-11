import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import mokm_effector

Window {
    id: root
    width: 820
    height: 540
    visible: true
    title: qsTr("MOKM Effector")

    color: Theme.background
    flags: Qt.FramelessWindowHint
    opacity: 0

    property bool _loading: false

    NumberAnimation on opacity { from: 0; to: 1; duration: 400; easing.type: Easing.OutCubic }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.background
        border.color: "#2A2A2A"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 20

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                Rectangle {
                    width: 36; height: 36; radius: 6; color: Theme.primary
                    Text { anchors.centerIn: parent; text: "M"; color: Theme.foreground; font.bold: true; font.pixelSize: 18 }
                }
                ColumnLayout {
                    spacing: 2
                    Text { text: "MOKM Effector"; font.pixelSize: 20; font.bold: true; color: Theme.foreground }
                    Text { text: "Video Composer & Motion Graphics"; font.pixelSize: 12; color: Theme.mutedForeground }
                }
                Item { Layout.fillWidth: true }
            }

            // Main content
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 20

                // ── LEFT: Recent Projects ──
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 340
                    radius: 10
                    color: "#161616"
                    border.color: "#2C2C2C"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Text { text: "Recent Projects"; font.pixelSize: 14; font.bold: true; color: Theme.foreground }

                        ListView {
                            id: recentList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 4
                            model: _startupConfig.recentProjects
                            delegate: Rectangle {
                                width: recentList.width
                                height: 48
                                radius: 6
                                color: ma.containsMouse ? Theme.secondaryHover : "transparent"
                                border.color: ma.containsMouse ? Theme.border : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            text: {
                                                var parts = modelData.split("/");
                                                return parts[parts.length - 1].replace(".mokm", "");
                                            }
                                            color: Theme.foreground; font.pixelSize: 12; font.bold: true
                                            elide: Text.ElideRight; Layout.fillWidth: true
                                        }
                                        Text { text: modelData; color: Theme.mutedForeground; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
                                    }
                                    Button {
                                        text: "×"; flat: true; implicitWidth: 24; implicitHeight: 24
                                        onClicked: { _startupConfig.removeRecentProject(modelData); }
                                    }
                                }

                                MouseArea {
                                    id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: openProject(modelData)
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "No recent projects"
                                color: Theme.mutedForeground; font.pixelSize: 12
                                visible: recentList.count === 0
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "Open Other…"
                            onClicked: openFileDialog.open()
                        }
                    }
                }

                // ── RIGHT: Create New Project ──
                Rectangle {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    radius: 10
                    color: "#161616"
                    border.color: "#2C2C2C"

                    ScrollView {
                        anchors.fill: parent
                        clip: true
                        padding: 16

                        ColumnLayout {
                            width: parent.width
                            spacing: 14

                            Text { text: "Create New Project"; font.pixelSize: 14; font.bold: true; color: Theme.foreground }

                            // Project Name
                            ColumnLayout { spacing: 4
                                Text { text: "Project Name"; color: Theme.foreground; font.pixelSize: 12 }
                                TextField {
                                    id: nameField; Layout.fillWidth: true
                                    placeholderText: "My Project"
                                    text: "Untitled"
                                }
                            }

                            // Save Location
                            ColumnLayout { spacing: 4
                                Text { text: "Save Location"; color: Theme.foreground; font.pixelSize: 12 }
                                RowLayout { Layout.fillWidth: true; spacing: 8
                                    TextField {
                                        id: locationField; Layout.fillWidth: true
                                        placeholderText: "/home/user/projects"
                                        text: ""
                                    }
                                    Button { text: "Browse"; onClicked: folderDialog.open() }
                                }
                            }

                            // Resolution preset
                            ColumnLayout { spacing: 4
                                Text { text: "Resolution"; color: Theme.foreground; font.pixelSize: 12 }
                                ComboBox {
                                    id: resCombo; Layout.fillWidth: true
                                    model: [
                                        { label: "1920×1080 (Full HD)", w: 1920, h: 1080 },
                                        { label: "2560×1440 (2K)", w: 2560, h: 1440 },
                                        { label: "3840×2160 (4K UHD)", w: 3840, h: 2160 },
                                        { label: "Custom", w: 0, h: 0 }
                                    ]
                                    textRole: "label"
                                    onCurrentIndexChanged: {
                                        var item = model[currentIndex];
                                        if (item.w > 0) { resW.value = item.w; resH.value = item.h; }
                                    }
                                }
                                RowLayout { spacing: 8
                                    SpinBox { id: resW; from: 1; to: 7680; value: 1920; Layout.fillWidth: true }
                                    Text { text: "×"; color: Theme.mutedForeground }
                                    SpinBox { id: resH; from: 1; to: 4320; value: 1080; Layout.fillWidth: true }
                                }
                            }

                            // Frame Rate + Duration
                            RowLayout { spacing: 16
                                ColumnLayout { Layout.fillWidth: true; spacing: 4
                                    Text { text: "Frame Rate (FPS)"; color: Theme.foreground; font.pixelSize: 12 }
                                    SpinBox { id: fpsSpin; from: 1; to: 240; value: 30; editable: true; Layout.fillWidth: true }
                                }
                                ColumnLayout { Layout.fillWidth: true; spacing: 4
                                    Text { text: "Duration (seconds)"; color: Theme.foreground; font.pixelSize: 12 }
                                    SpinBox { id: durSpin; from: 1; to: 600; value: 30; editable: true; Layout.fillWidth: true }
                                }
                            }

                            // Color Space
                            ColumnLayout { spacing: 4
                                Text { text: "Color Space"; color: Theme.foreground; font.pixelSize: 12 }
                                ComboBox {
                                    id: colorCombo; Layout.fillWidth: true
                                    model: ["sRGB", "Rec.709", "DCI-P3"]
                                }
                            }

                            // Checkboxes
                            RowLayout { spacing: 16
                                CheckBox { id: gpuCheck; text: "GPU Rendering"; checked: true }
                                CheckBox { id: autoSaveCheck; text: "Auto Save"; checked: true }
                                CheckBox { id: proxyCheck; text: "Proxy Media" }
                            }

                            // Spacer
                            Item { Layout.fillHeight: true }

                            // Create button
                            Button {
                                Layout.fillWidth: true
                                text: "Create Project"
                                height: 40
                                highlighted: true
                                enabled: nameField.text.trim().length > 0
                                onClicked: createProject()
                            }
                        }
                    }
                }
            }

            // Bottom actions
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button { text: "Preferences"; onClicked: prefsDialog.open() }
                Button { text: "Quit"; onClicked: Qt.quit() }
            }
        }
    }

    // ── Dialogs ──
    FolderDialog {
        id: folderDialog
        title: "Choose Project Location"
        onAccepted: {
            if (folderDialog.selectedFolder)
                locationField.text = folderDialog.selectedFolder.toString().replace("file://", "");
        }
    }

    FileDialog {
        id: openFileDialog
        title: "Open Project"
        nameFilters: ["MOKM Project (*.mokm)", "All Files (*)"]
        onAccepted: {
            if (openFileDialog.selectedFile)
                openProject(openFileDialog.selectedFile);
        }
    }

    PreferencesDialog {
        id: prefsDialog
        project: null
    }

    // ── Functions ──
    function openProject(url) {
        if (root._loading) return;
        root._loading = true;
        _startupConfig.mode = "open";
        _startupConfig.filePath = url;
        _startupConfig.addRecentProject(url.toString().replace("file://", ""));
        loadMain();
    }

    function createProject() {
        if (root._loading) return;
        root._loading = true;
        _startupConfig.mode = "new";
        _startupConfig.projectName = nameField.text;
        _startupConfig.width = resW.value;
        _startupConfig.height = resH.value;
        _startupConfig.fps = fpsSpin.value;
        _startupConfig.duration = durSpin.value * fpsSpin.value;
        _startupConfig.gpuRendering = gpuCheck.checked;
        _startupConfig.colorSpace = colorCombo.currentText;
        loadMain();
    }

    function loadMain() {
        var comp = Qt.createComponent("Main.qml");
        function finish() {
            if (comp.status === Component.Ready) {
                var win = comp.createObject(null);
                if (win) {
                    root.visible = false;
                    win.show();
                } else {
                    console.error("Failed to create Main window:", comp.errorString());
                }
            } else {
                console.error("Failed to load Main.qml:", comp.errorString());
            }
        }
        if (comp.status === Component.Ready || comp.status === Component.Error) {
            finish();
        } else {
            comp.statusChanged.connect(finish);
        }
    }
}
