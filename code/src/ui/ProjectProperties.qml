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
        radius: 0
        color: Theme.background
        border.color: "#333333"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 32
            spacing: 24

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 20
                Rectangle {
                    width: 42; height: 42; radius: 0
                    color: Theme.primary
                    Text { anchors.centerIn: parent; text: "M"; color: "#000000"; font.pixelSize: 22; font.bold: true }
                }
                ColumnLayout {
                    spacing: 0
                    Text { text: "MOKM EFFECTOR"; font.pixelSize: 18; font.bold: true; font.letterSpacing: 1.2; color: Theme.foreground }
                    Text { text: "CREATE NEW PROJECT"; font.pixelSize: 10; font.bold: true; color: Theme.primary }
                }
                Item { Layout.fillWidth: true }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // LEFT: Recent Projects
                ColumnLayout {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 200
                    spacing: 12

                    Text { text: "RECENT WORK"; font.pixelSize: 11; font.bold: true; color: Theme.mutedForeground }

                    ListView {
                        id: recentList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 2
                        model: _startupConfig.recentProjects

                        delegate: Rectangle {
                            width: ListView.view.width; height: 45; radius: 0
                            color: ma.containsMouse ? Theme.secondary : "transparent"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 8; spacing: 10
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 0
                                    Text { text: modelData.split('/').pop().replace(".mokm", ""); color: Theme.foreground; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight }
                                    Text { text: modelData; color: Theme.mutedForeground; font.pixelSize: 9; elide: Text.ElideMiddle }
                                }
                                MouseArea {
                                    id: rmBtn; width: 20; height: 20; hoverEnabled: true
                                    onClicked: _startupConfig.removeRecentProject(modelData)
                                    Text { anchors.centerIn: parent; text: "×"; color: rmBtn.containsMouse ? Theme.error : Theme.mutedForeground; font.pixelSize: 16 }
                                }
                            }
                            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: openProject(modelData) }
                            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.2 }
                        }
                        Text { anchors.centerIn: parent; text: "Empty"; color: Theme.mutedForeground; font.pixelSize: 11; visible: recentList.count === 0 }
                    }

                    Button {
                        text: "OPEN FROM DISK..."
                        Layout.fillWidth: true
                        flat: true
                        onClicked: openFileDialog.open()
                    }
                }

                // Vertical Divider
                Rectangle { Layout.fillHeight: true; width: 1; color: Theme.border; Layout.leftMargin: 24; Layout.rightMargin: 24 }

                // RIGHT: Project Configuration
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 16

                    Text { text: "PROJECT CONFIGURATION"; font.pixelSize: 11; font.bold: true; color: Theme.mutedForeground }

                    Flickable {
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        contentHeight: formColumn.height
                        ColumnLayout {
                            id: formColumn; width: parent.width; spacing: 15

                            // Project Name
                            ColumnLayout {
                                spacing: 4; Layout.fillWidth: true
                                Text { text: "PROJECT NAME"; color: Theme.mutedForeground; font.pixelSize: 9; font.bold: true }
                                TextField {
                                    id: nameField; Layout.fillWidth: true; height: 35; text: "Untitled Project"
                                    background: Rectangle { radius: 0; color: Theme.input; border.color: parent.activeFocus ? Theme.primary : Theme.border }
                                }
                            }

                            // Save Location
                            ColumnLayout {
                                spacing: 4; Layout.fillWidth: true
                                Text { text: "SAVE LOCATION"; color: Theme.mutedForeground; font.pixelSize: 9; font.bold: true }
                                RowLayout {
                                    spacing: 0
                                    TextField {
                                        id: locationField; Layout.fillWidth: true; height: 35; placeholderText: "Select directory..."
                                        background: Rectangle { radius: 0; color: Theme.input; border.color: parent.activeFocus ? Theme.primary : Theme.border }
                                    }
                                    Button {
                                        text: "BROWSE"; height: 35; onClicked: folderDialog.open()
                                        background: Rectangle { radius: 0; color: Theme.secondary; border.color: Theme.border }
                                    }
                                }
                            }

                            // Resolution Preset
                            ColumnLayout {
                                spacing: 4; Layout.fillWidth: true
                                Text { text: "RESOLUTION PRESET"; color: Theme.mutedForeground; font.pixelSize: 9; font.bold: true }
                                ComboBox {
                                    id: resCombo; Layout.fillWidth: true; height: 35
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
                                        if (currentText === "Custom") {
                                                // Optionally clear or leave as-is for custom
                                                return;
                                            }

                                            // More flexible regex: match any numbers separated by ×, x, or × with possible spaces
                                            var match = currentText.match(/(\d+)\s*[×xX]\s*(\d+)/);

                                            if (match) {
                                                resW.text = match[1];
                                                resH.text = match[2];
                                            } else {
                                                console.warn("Could not extract resolution from:", currentText);
                                            }
                                        // var match = currentText.match(/(\d+)×(\d+)/);
                                        // if (match) { resW.text = match[1]; resH.text = match[2]; }
                                    }
                                    background: Rectangle { radius: 0; implicitHeight: 35; border.color: Theme.border; color: Theme.input }
                                    contentItem: Text {
                                        leftPadding: 10
                                        verticalAlignment: Text.AlignVCenter
                                        text: resCombo.currentText
                                        color: Theme.foreground
                                        font.pixelSize: 12
                                    }
                                    popup: Popup {
                                        y: resCombo.height + 2
                                        width: resCombo.width
                                        implicitHeight: contentItem.implicitHeight
                                        padding: 1
                                        contentItem: ListView {
                                            clip: true
                                            implicitHeight: contentHeight
                                            model: resCombo.popup.visible ? resCombo.model : null
                                            currentIndex: resCombo.highlightedIndex
                                            delegate: Rectangle {
                                                width: ListView.view.width
                                                height: 35
                                                color: mouseArea.containsMouse ? Theme.secondaryHover : Theme.secondary
                                                Text {
                                                    anchors.left: parent.left; anchors.leftMargin: 10
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: modelData
                                                    color: Theme.foreground
                                                    font.pixelSize: 12
                                                }
                                                MouseArea {
                                                    id: mouseArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: {
                                                        resCombo.currentIndex = index
                                                        resCombo.popup.close()
                                                    }
                                                }
                                            }
                                        }
                                        background: Rectangle { color: Theme.secondary; border.color: Theme.border; border.width: 1 }
                                    }
                                }
                            }

                            // Width / Height
                            RowLayout {
                                spacing: 12
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "WIDTH"; color: Theme.mutedForeground; font.pixelSize: 9; font.bold: true }
                                    TextField { id: resW; text: "1920"; height: 35; Layout.fillWidth: true; background: Rectangle { radius: 0; border.color: Theme.border; color: Theme.input } }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "HEIGHT"; color: Theme.mutedForeground; font.pixelSize: 9; font.bold: true }
                                    TextField { id: resH; text: "1080"; height: 35; Layout.fillWidth: true; background: Rectangle { radius: 0; border.color: Theme.border; color: Theme.input } }
                                }
                            }

                            // Frame Rate & Duration
                            RowLayout {
                                spacing: 20
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "FRAME RATE (FPS)"; color: Theme.mutedForeground; font.pixelSize: 9; font.bold: true }
                                    TextField { id: fpsSpin; text: "30"; height: 35; Layout.fillWidth: true; background: Rectangle { radius: 0; border.color: Theme.border; color: Theme.input } }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "DURATION (SEC)"; color: Theme.mutedForeground; font.pixelSize: 9; font.bold: true }
                                    TextField { id: durSpin; text: "60"; height: 35; Layout.fillWidth: true; background: Rectangle { radius: 0; border.color: Theme.border; color: Theme.input } }
                                }
                            }

                            // Color Space
                            ColumnLayout {
                                spacing: 4; Layout.fillWidth: true
                                Text { text: "COLOR SPACE"; color: Theme.mutedForeground; font.pixelSize: 9; font.bold: true }
                                ComboBox {
                                    id: colorCombo; Layout.fillWidth: true; height: 35
                                    model: ["sRGB", "Rec.709", "DCI-P3", "Rec.2020"]
                                    background: Rectangle { radius: 0; implicitHeight: 35; border.color: Theme.border; color: Theme.input }
                                    contentItem: Text {
                                        leftPadding: 10
                                        verticalAlignment: Text.AlignVCenter
                                        text: colorCombo.currentText
                                        color: Theme.foreground
                                        font.pixelSize: 12
                                    }
                                    popup: Popup {
                                        y: colorCombo.height + 2
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
                                                height: 35
                                                color: mouseArea.containsMouse ? Theme.secondaryHover : Theme.secondary
                                                Text {
                                                    anchors.left: parent.left; anchors.leftMargin: 10
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: modelData
                                                    color: Theme.foreground
                                                    font.pixelSize: 12
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
                                        background: Rectangle { color: Theme.secondary; border.color: Theme.border; border.width: 1 }
                                    }
                                }
                            }

                            // Options
                            RowLayout {
                                spacing: 20
                                CheckBox { id: gpuCheck; text: "GPU"; checked: true; font.pixelSize: 10 }
                                CheckBox { id: autoSaveCheck; text: "AUTO-SAVE"; checked: true; font.pixelSize: 10 }
                                CheckBox { id: proxyCheck; text: "PROXY MEDIA"; checked: false; font.pixelSize: 10 }
                            }

                            Item { Layout.fillHeight: true }

                            // Create Button
                            Button {
                                id: createBtn
                                Layout.fillWidth: true; height: 45; text: "CREATE PROJECT"
                                enabled: nameField.text.trim().length > 0
                                onClicked: createProject()
                                background: Rectangle {
                                    radius: 0
                                    color: createBtn.enabled ? (createBtn.pressed ? "#CCCCCC" : (createBtn.hovered ? "#FFFFFF" : Theme.primary)) : Theme.muted
                                }
                                contentItem: Text { text: parent.text; color: "#000000"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            }
                        }
                    }
                }
            }

            // Bottom Bar
            RowLayout {
                Layout.fillWidth: true
                Text { text: "SYSTEM STABLE | v2.4.0"; color: Theme.mutedForeground; font.pixelSize: 9; font.letterSpacing: 1 }
                Item { Layout.fillWidth: true }
                Button {
                    text: "PREFERENCES"
                    height: 36
                    flat: true
                    onClicked: prefsDialog.open()
                }
                Button {
                    text: "QUIT"
                    height: 36
                    flat: true
                    onClicked: Qt.quit()
                }
            }
        }
    }

    // Dialogs
    FolderDialog { id: folderDialog; onAccepted: locationField.text = selectedFolder.toString().replace("file://", "") }
    FileDialog { id: openFileDialog; nameFilters: ["MOKM Project (*.mokm)", "All Files (*)"]; onAccepted: openProject(selectedFile) }
    PreferencesDialog { id: prefsDialog; project: null }

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
        _startupConfig.duration = (parseInt(durSpin.text) || 60) * (parseInt(fpsSpin.text) || 30);
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
