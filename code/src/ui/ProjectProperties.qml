import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls
import mokm_effector

Window {
    id: root
    width: 860
    height: 580
    visible: true
    title: qsTr("MOKM Effector - New Project")
    color: Theme.background
    flags: Qt.FramelessWindowHint


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
            anchors.margins: 28
            spacing: 24

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Rectangle {
                    width: 42; height: 42; radius: 8
                    color: Theme.primary
                    Text {
                        anchors.centerIn: parent
                        text: "M"
                        color: Theme.foreground
                        font.pixelSize: 22
                        font.bold: true
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "MOKM Effector"
                        font.pixelSize: 22
                        font.bold: true
                        color: Theme.foreground
                    }
                    Text {
                        text: "Create New Project"
                        font.pixelSize: 13
                        color: Theme.mutedForeground
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // Main Content
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 24

                // LEFT: Recent Projects
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 360
                    Layout.minimumWidth: 300
                    Layout.maximumWidth: 420
                    radius: 12
                    color: Theme.secondary
                    border.color: Theme.border

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 16
                        clip: true

                        Text {
                            text: "Recent Projects"
                            font.pixelSize: 15
                            font.bold: true
                            color: Theme.foreground
                        }

                        ListView {
                            id: recentList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 6
                            model: _startupConfig.recentProjects

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 52
                                radius: 8
                                color: ma.containsMouse ? Theme.secondaryHover : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text {
                                            text: {
                                                var parts = modelData.split("/")
                                                return parts[parts.length - 1].replace(".mokm", "")
                                            }
                                            color: Theme.foreground
                                            font.pixelSize: 13
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: modelData
                                            color: Theme.mutedForeground
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: rmBtn
                                        width: 28; height: 28
                                        hoverEnabled: true
                                        onClicked: _startupConfig.removeRecentProject(modelData)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "×"
                                            color: rmBtn.containsMouse ? Theme.error : Theme.mutedForeground
                                            font.pixelSize: 16
                                        }
                                    }
                                }

                                MouseArea {
                                    id: ma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: openProject(modelData)
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "No recent projects yet"
                                color: Theme.mutedForeground
                                font.pixelSize: 13
                                visible: recentList.count === 0
                            }
                        }

                        Button {
                            text: "Open Other Project..."
                            Layout.fillWidth: true
                            height: 38
                            onClicked: openFileDialog.open()
                        }
                    }
                }

                // RIGHT: Create New Project Form
                Rectangle {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.minimumWidth: 350
                    radius: 12
                    color: Theme.secondary
                    border.color: Theme.border

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 20
                        clip: true
                        contentHeight: formColumn.height

                        ColumnLayout {
                            id: formColumn
                            width: parent.width
                            spacing: 18

                            Text {
                                text: "Project Settings"
                                font.pixelSize: 15
                                font.bold: true
                                color: Theme.foreground
                            }

                            // Project Name
                            ColumnLayout {
                                spacing: 6
                                Text { text: "Project Name"; color: Theme.foreground; font.pixelSize: 13 }
                                TextField {
                                    id: nameField
                                    Layout.fillWidth: true
                                    height: 42
                                    text: "Untitled Project"
                                    font.pixelSize: 13
                                    color: Theme.foreground
                                    background: Rectangle {
                                        radius: 8
                                        color: Theme.input
                                        border.color: Theme.border
                                    }
                                }
                            }

                            // Save Location
                            ColumnLayout {
                                spacing: 6
                                Text { text: "Save Location"; color: Theme.foreground; font.pixelSize: 13 }
                                RowLayout {
                                    spacing: 10
                                    TextField {
                                        id: locationField
                                        Layout.fillWidth: true
                                        height: 42
                                        placeholderText: "~/Projects"
                                        font.pixelSize: 13
                                        color: Theme.foreground
                                        background: Rectangle {
                                            radius: 8
                                            color: Theme.input
                                            border.color: Theme.border
                                        }
                                    }
                                    Button {
                                        text: "Browse"
                                        height: 42
                                        onClicked: folderDialog.open()
                                    }
                                }
                            }

                            // Resolution
                            ColumnLayout {
                                spacing: 6
                                Text { text: "Resolution Preset"; color: Theme.foreground; font.pixelSize: 13 }

                                ComboBox {
                                    id: resCombo
                                    Layout.fillWidth: true
                                    height: 42
                                    font.pixelSize: 13
                                    model: [
                                        "Instagram Square (1080×1080)",
                                        "Instagram Portrait (1080×1350)",
                                        "Instagram Story / TikTok (1080×1920)",
                                        "YouTube Thumbnail (1280×720)",
                                        "Full HD (1920×1080)",
                                        "Vertical Full HD (1080×1920)",
                                        "2K QHD (2560×1440)",
                                        "UltraWide (3440×1440)",
                                        "4K UHD (3840×2160)",
                                        "iPhone 15 Pro Max (1290×2796)",
                                        "Android Portrait (1080×2400)",
                                        "A4 Portrait (2480×3508)",
                                        "A4 Landscape (3508×2480)",
                                        "Poster (5000×7000)",
                                        "Custom"
                                    ]

                                    onCurrentIndexChanged: {
                                        var match = resCombo.currentText.match(/(\d+)×(\d+)/);
                                        if (match) {
                                            resW.text = match[1];
                                            resH.text = match[2];
                                        }
                                    }
                                }

                                RowLayout {
                                    spacing: 12
                                    TextField {
                                        id: resW
                                        Layout.fillWidth: true
                                        height: 42
                                        text: "1920"
                                        horizontalAlignment: TextInput.AlignHCenter
                                        validator: IntValidator { bottom: 1; top: 7680 }
                                        background: Rectangle { radius: 8; color: Theme.input; border.color: Theme.border }
                                    }
                                    Text { text: "×"; color: Theme.mutedForeground; font.pixelSize: 18; Layout.alignment: Qt.AlignVCenter }
                                    TextField {
                                        id: resH
                                        Layout.fillWidth: true
                                        height: 42
                                        text: "1080"
                                        horizontalAlignment: TextInput.AlignHCenter
                                        validator: IntValidator { bottom: 1; top: 4320 }
                                        background: Rectangle { radius: 8; color: Theme.input; border.color: Theme.border }
                                    }
                                }
                            }

                            // Frame Rate & Duration
                            RowLayout {
                                spacing: 20
                                ColumnLayout {
                                    spacing: 6
                                    Text { text: "Frame Rate (FPS)"; color: Theme.foreground; font.pixelSize: 13 }
                                    TextField {
                                        id: fpsSpin
                                        Layout.fillWidth: true
                                        height: 42
                                        text: "30"
                                        horizontalAlignment: TextInput.AlignHCenter
                                        validator: IntValidator { bottom: 1; top: 240 }
                                        background: Rectangle { radius: 8; color: Theme.input; border.color: Theme.border }
                                    }
                                }
                                ColumnLayout {
                                    spacing: 6
                                    Text { text: "Duration (seconds)"; color: Theme.foreground; font.pixelSize: 13 }
                                    TextField {
                                        id: durSpin
                                        Layout.fillWidth: true
                                        height: 42
                                        text: "60"
                                        horizontalAlignment: TextInput.AlignHCenter
                                        validator: IntValidator { bottom: 1; top: 1800 }
                                        background: Rectangle { radius: 8; color: Theme.input; border.color: Theme.border }
                                    }
                                }
                            }

                            // Color Space
                            ColumnLayout {
                                spacing: 6
                                Text {
                                    text: "Color Space";
                                    color: Theme.foreground;
                                    font.pixelSize: 13
                                }

                                ComboBox {
                                    id: colorCombo
                                    Layout.fillWidth: true
                                    height: 42
                                    font.pixelSize: 13
                                    model: ["sRGB", "Rec.709", "DCI-P3", "Rec.2020"]

                                    background: Rectangle {
                                        radius: 8
                                        color: Theme.input
                                        border.color: Theme.border
                                    }

                                    contentItem: Text {
                                        leftPadding: 12
                                        verticalAlignment: Text.AlignVCenter
                                        text: colorCombo.currentText
                                        color: Theme.foreground
                                        font: colorCombo.font
                                    }

                                    popup: Popup {
                                        y: colorCombo.height + 4
                                        width: colorCombo.width
                                        implicitHeight: contentItem.implicitHeight
                                        padding: 1

                                        contentItem: ListView {
                                            clip: true
                                            implicitHeight: contentHeight
                                            model: colorCombo.popup.visible ? colorCombo.model : null
                                            currentIndex: colorCombo.highlightedIndex

                                            delegate: Rectangle {
                                                width: ListView.view.width
                                                height: 38
                                                color: mouseArea.containsMouse ? Theme.secondaryHover : Theme.secondary

                                                Text {
                                                    anchors.left: parent.left
                                                    anchors.leftMargin: 12
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: modelData
                                                    color: Theme.foreground
                                                }

                                                MouseArea {
                                                    id: mouseArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: {
                                                        colorCombo.currentIndex = index
                                                        colorCombo.popup.close()
                                                    }
                                                }
                                            }
                                        }

                                        background: Rectangle {
                                            color: Theme.secondary
                                            border.color: Theme.border
                                            radius: 8
                                        }
                                    }
                                }
                            }

                            // Options
                            RowLayout {
                                spacing: 24
                                CheckBox { id: gpuCheck; text: "GPU Accelerated Rendering"; checked: true }
                                CheckBox { id: autoSaveCheck; text: "Enable Auto Save"; checked: true }
                                CheckBox { id: proxyCheck; text: "Create Proxy Media"; checked: false }
                            }

                            Item { Layout.fillHeight: true }

                            // Create Button
                            Button {
                                Layout.fillWidth: true
                                height: 48
                                text: "Create Project"
                                font.pixelSize: 14
                                font.bold: true
                                enabled: nameField.text.trim().length > 0

                                background: Rectangle {
                                    radius: 10
                                    color: parent.enabled ?
                                           (parent.down ? Theme.primaryHover : Theme.primary) :
                                           Theme.muted
                                }

                                contentItem: Text {
                                    text: parent.text
                                    color: parent.enabled ? Theme.foreground : Theme.mutedForeground
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font: parent.font
                                }

                                onClicked: createProject()
                            }
                        }
                    }
                }
            }

            // Bottom Bar
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }

                Button {
                    text: "Preferences"
                    height: 36
                    onClicked: prefsDialog.open()
                }
                Button {
                    text: "Quit"
                    height: 36
                    onClicked: Qt.quit()
                }
            }
        }
    }

    // Dialogs
    FolderDialog {
        id: folderDialog
        onAccepted: locationField.text = selectedFolder.toString().replace("file://", "")
    }

    FileDialog {
        id: openFileDialog
        nameFilters: ["MOKM Project (*.mokm)", "All Files (*)"]
        onAccepted: openProject(selectedFile)
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
        _startupConfig.width = parseInt(resW.text) || 1920;
        _startupConfig.height = parseInt(resH.text) || 1080;
        _startupConfig.fps = parseInt(fpsSpin.text) || 30;
        _startupConfig.duration = (parseInt(durSpin.text) || 30) * (parseInt(fpsSpin.text) || 30);
        _startupConfig.gpuRendering = true; // simplified
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
            } else if (comp.status === Component.Error) {
                console.error("Failed to load Main.qml:", comp.errorString());
            } else {
                comp.statusChanged.connect(finish);
            }
        }
        if (comp.status === Component.Ready || comp.status === Component.Error) {
            finish();
        } else {
            comp.statusChanged.connect(finish);
        }
    }
}
