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

    menuBar: MenuBar {
        id: mainMenuBar
        background: Rectangle { color: Theme.base; border.color: Theme.border; border.width: 1 }

        Menu {
            title: "File"
            Action { text: "New Project"; onTriggered: ProjectManager.createNewProject("Untitled") }
            Action { text: "Open Project..."; onTriggered: openProjectDialog.open() }
            MenuSeparator {}
            Action { text: "Save"; onTriggered: ProjectManager.saveProject() }
            Action { text: "Exit"; onTriggered: Qt.quit() }
        }
        Menu {
            title: "Edit"
            Action { text: "Undo"; enabled: UndoManager.canUndo; onTriggered: UndoManager.undo() }
            Action { text: "Redo"; enabled: UndoManager.canRedo; onTriggered: UndoManager.redo() }
        }
        Menu {
            title: "Composition"
            Action { text: "New Composition" }
            Action { text: "Render Settings" }
        }
        Menu {
            title: "Window"
            Action { text: "Project Bin"; checkable: true; checked: true }
            Action { text: "Inspector"; checkable: true; checked: true }
            Action { text: "Timeline"; checkable: true; checked: true }
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

            // Left Tool Sidebar
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
                            { icon: "mouse-pointer-2.svg", active: true },
                            { icon: "hand.svg" },
                            { icon: "box.svg" },
                            { icon: "network.svg" },
                            { icon: "layers.svg" },
                            { icon: "zap.svg" }
                        ]
                        delegate: ToolButton {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
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
                        icon.source: "icons/outline/settings.svg"
                        icon.color: Theme.textSecondary
                        onClicked: preferencesModal.open()
                    }
                }
            }

            // Central Panels
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
                            opacity: 0.1
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
                            source: "node_editor/NodeEditorWorkspace.qml" // Default view
                        }
                    }

                    // Timeline (Bottom Panel)
                    Rectangle {
                        SplitView.preferredHeight: 240
                        SplitView.minimumHeight: 100
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

        // Status Bar
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

    FileDialog {
        id: openProjectDialog
        title: "Open Project"
        nameFilters: ["MOKM Project Files (*.mokm)"]
        onAccepted: ProjectManager.loadProject(selectedFile)
    }
}
