import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "project_settings"
import "preferences"
import "proxy_manager"
import "plugin_manager"
import "keyboard_shortcuts"
import QtQuick.Dialogs
import Mokm.Core 1.0
import Mokm.Database 1.0
import untitled

ApplicationWindow {
    id: mainWindow
    width: 1440
    height: 800
    visible: true
    title: ProjectManager.projectName + (ProjectManager.isDirty ? " *" : "") + " - MOKM Effector"
    color: Theme.surface

    Component.onCompleted: {
        console.log("MOKM Effector Workspace Loaded");
    }

    menuBar: MenuBar {
        id: mainMenuBar
        background: Rectangle { color: Theme.base; border.color: Theme.border; border.width: 1 }

        Menu {
            title: "File"
            Action { text: "New Project"; shortcut: "Ctrl+N"; onTriggered: ProjectManager.createNewProject("Untitled") }
            Action { text: "Open Project..."; shortcut: "Ctrl+O"; onTriggered: openProjectDialog.open() }
            MenuSeparator {}
            Action { text: "Save"; shortcut: "Ctrl+S"; onTriggered: ProjectManager.saveProject() }
            Action { text: "Save As..."; shortcut: "Ctrl+Shift+S"; onTriggered: saveAsProjectDialog.open() }
            MenuSeparator {}
            Action { text: "Exit"; onTriggered: Qt.quit() }
        }
        Menu {
            title: "Edit"
            Action { text: "Undo"; shortcut: "Ctrl+Z"; enabled: UndoManager.canUndo; onTriggered: UndoManager.undo() }
            Action { text: "Redo"; shortcut: "Ctrl+Y"; enabled: UndoManager.canRedo; onTriggered: UndoManager.redo() }
        }
        Menu {
            title: "Composition"
            Action { text: "New Composition"; shortcut: "Ctrl+N" }
            Action { text: "Composition Settings"; shortcut: "Ctrl+K" }
            MenuSeparator {}
            Action { text: "Render Queue"; shortcut: "Ctrl+M" }
        }
        Menu {
            title: "Window"
            Action { text: "Project Bin"; checkable: true; checked: true }
            Action { text: "Inspector"; checkable: true; checked: true }
            Action { text: "Timeline"; checkable: true; checked: true }
            MenuSeparator {}
            Action { text: "Reset Workspace Layout" }
        }
        Menu {
            title: "Help"
            Action { text: "About MOKM Effector" }
            Action { text: "Documentation" }
        }
    }

    // Main Workspace Layout
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Left Tool Sidebar (Consistent with Web)
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 44
                color: Theme.base
                border.color: Theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 8

                    Repeater {
                        model: [
                            { icon: "mouse-pointer-2.svg", name: "Select", active: true },
                            { icon: "hand.svg", name: "Pan" },
                            { icon: "box.svg", name: "3D View" },
                            { icon: "network.svg", name: "Nodes" },
                            { icon: "layers.svg", name: "Layers" },
                            { icon: "zap.svg", name: "Render" }
                        ]
                        delegate: ToolButton {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            ToolTip.visible: hovered
                            ToolTip.text: modelData.name
                            background: Rectangle {
                                color: modelData.active ? Theme.primary : "transparent"
                                opacity: modelData.active ? 0.2 : 1
                                radius: Theme.radius
                            }
                            icon.source: "icons/outline/" + modelData.icon
                            icon.color: modelData.active ? Theme.primary : Theme.textSecondary
                            icon.width: 20
                            icon.height: 20
                        }
                    }

                    Item { Layout.fillHeight: true }

                    ToolButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        ToolTip.visible: hovered
                        ToolTip.text: "Settings"
                        icon.source: "icons/outline/settings.svg"
                        icon.color: Theme.textSecondary
                        onClicked: menu.open()
                        
                        Menu {
                            id: menu
                            y: -height
                            MenuItem { text: "Project Settings"; onClicked: projectSettingsModal.open() }
                            MenuItem { text: "Preferences"; onClicked: preferencesModal.open() }
                            MenuItem { text: "Proxy Dashboard"; onClicked: proxyDashboard.open() }
                            MenuItem { text: "Plugin Manager"; onClicked: pluginManagerModal.open() }
                            MenuItem { text: "Keyboard Shortcuts"; onClicked: shortcutMapperModal.open() }
                        }
                    }
                }
            }

            // Central Split Panels
            SplitView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: Qt.Horizontal

                // Project Bin (Left Panel)
                Rectangle {
                    SplitView.preferredWidth: 260
                    SplitView.minimumWidth: 200
                    color: Theme.surface
                    border.color: Theme.border

                    Loader {
                        anchors.fill: parent
                        source: "media_bin/MediaBinWorkspace.qml"
                    }
                }

                // Main Center View (Canvas & Timeline)
                SplitView {
                    orientation: Qt.Vertical
                    SplitView.fillWidth: true

                    // Viewport / Canvas
                    Rectangle {
                        SplitView.fillHeight: true
                        color: Theme.base
                        
                        // Workspace Grid Overlay
                        Canvas {
                            anchors.fill: parent
                            opacity: 0.05
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.strokeStyle = Theme.textSecondary;
                                ctx.lineWidth = 1;
                                for(var x=0; x<width; x+=40) {
                                    ctx.beginPath(); ctx.moveTo(x,0); ctx.lineTo(x,height); ctx.stroke();
                                }
                                for(var y=0; y<height; y+=40) {
                                    ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(width,y); ctx.stroke();
                                }
                            }
                        }

                        Loader {
                            id: workspaceLoader
                            anchors.fill: parent
                            source: "node_editor/NodeEditorWorkspace.qml"
                        }
                        
                        // Viewport Controls (Consistent with Web)
                        Row {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottomMargin: 12
                            spacing: 1
                            Rectangle {
                                width: 120; height: 28; radius: 6; color: Theme.base; opacity: 0.8
                                border.color: Theme.border; border.width: 1
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 4
                                    Text { text: "100%"; font: Theme.monoFont; color: Theme.textSecondary; Layout.alignment: Qt.AlignCenter }
                                }
                            }
                        }
                    }

                    // Timeline (Bottom Panel)
                    Rectangle {
                        SplitView.preferredHeight: 240
                        SplitView.minimumHeight: 120
                        color: Theme.surface
                        border.color: Theme.border

                        Loader {
                            anchors.fill: parent
                            source: "timeline/TimelineWorkspace.qml"
                        }
                    }
                }

                // Attribute Inspector (Right Panel)
                Rectangle {
                    SplitView.preferredWidth: 300
                    SplitView.minimumWidth: 240
                    color: Theme.surface
                    border.color: Theme.border

                    Loader {
                        anchors.fill: parent
                        source: "attribute_inspector/AttributeInspector.qml"
                    }
                }
            }
        }

        // Status Bar (Consistent with Web)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            color: Theme.base
            border.color: Theme.border

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                
                Text {
                    text: "Ready"
                    font: Theme.monoFont
                    color: Theme.textSecondary
                }
                
                Text {
                    text: "| Composition: Main_Render | Frame: 0 / 240"
                    font: Theme.monoFont
                    color: Theme.textSecondary
                    opacity: 0.6
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: "Engine: ThorVG | Render: Vulkan | Memory: 42MB"
                    font: Theme.monoFont
                    color: Theme.textSecondary
                }
            }
        }
    }

    // Dialogs & Modals
    PreferencesModal { id: preferencesModal }
    ProjectSettingsModal { id: projectSettingsModal }
    ProxyDashboard { id: proxyDashboard }
    PluginManagerModal { id: pluginManagerModal }
    ShortcutMapper { id: shortcutMapperModal }

    MessageDialog {
        id: recoveryDialog
        title: "Crash Recovery"
        text: "An unsaved project was found. Would you like to recover it?"
        buttons: MessageDialog.Yes | MessageDialog.No
        onAccepted: ProjectManager.loadProject("")
    }

    FileDialog {
        id: openProjectDialog
        title: "Open Project"
        nameFilters: ["MOKM Project Files (*.mokm)"]
        onAccepted: ProjectManager.loadProject(selectedFile)
    }

    FileDialog {
        id: saveAsProjectDialog
        title: "Save Project As"
        fileMode: FileDialog.SaveFile
        nameFilters: ["MOKM Project Files (*.mokm)"]
        onAccepted: ProjectManager.saveProjectAs(selectedFile)
    }
}
