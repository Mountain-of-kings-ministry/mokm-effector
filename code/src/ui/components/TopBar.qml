import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects

Item {
    id: topBar
    width: parent.width
    height: 30

    property Window window
    property bool canUndo: false
    property bool canRedo: false

    signal newFileRequested
    signal openFileRequested
    signal saveFileRequested
    signal saveAsRequested
    signal undoRequested
    signal redoRequested
    signal createRectLayer
    signal createCircleLayer
    signal createTriangleLayer
    signal createTextLayer
    signal deleteSelectedLayer
    signal exportVideoRequested
    signal exportImageSequenceRequested
    signal preferencesRequested

    Rectangle {
        anchors.fill: parent
        color: Theme.background
        border.color: Theme.border
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 4
            spacing: 8

            Row {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                MenuBarButton {
                    text: qsTr("File")
                    menu: Menu {
                        MenuItem {
                            text: qsTr("New")
                            Menu {
                                MenuItem { text: qsTr("Rectangle"); onTriggered: topBar.createRectLayer() }
                                MenuItem { text: qsTr("Circle"); onTriggered: topBar.createCircleLayer() }
                                MenuItem { text: qsTr("Triangle"); onTriggered: topBar.createTriangleLayer() }
                                MenuSeparator {}
                                MenuItem { text: qsTr("Text"); onTriggered: topBar.createTextLayer() }
                            }
                        }
                        MenuItem { text: qsTr("Open..."); onTriggered: topBar.openFileRequested() }
                        MenuSeparator {}
                        MenuItem { text: qsTr("Save"); onTriggered: topBar.saveFileRequested() }
                        MenuItem { text: qsTr("Save As..."); onTriggered: topBar.saveAsRequested() }
                        MenuSeparator {}
                        MenuItem { text: qsTr("Import") }
                        MenuItem { text: qsTr("Export Animation..."); onTriggered: topBar.exportVideoRequested() }
                        MenuItem { text: qsTr("Export Image Sequence..."); onTriggered: topBar.exportImageSequenceRequested() }
                        MenuSeparator {}
                        MenuItem { text: qsTr("Preferences"); onTriggered: topBar.preferencesRequested() }
                        MenuSeparator {}
                        MenuItem { text: qsTr("Quit"); onTriggered: Qt.quit() }
                    }
                }

                MenuBarButton {
                    text: qsTr("Edit")
                    menu: Menu {
                        MenuItem { text: qsTr("Undo"); enabled: topBar.canUndo; onTriggered: topBar.undoRequested() }
                        MenuItem { text: qsTr("Redo"); enabled: topBar.canRedo; onTriggered: topBar.redoRequested() }
                        MenuSeparator {}
                        MenuItem { text: qsTr("Cut") }
                        MenuItem { text: qsTr("Copy") }
                        MenuItem { text: qsTr("Paste") }
                        MenuSeparator {}
                        MenuItem { text: qsTr("Duplicate") }
                        MenuItem { text: qsTr("Delete"); onTriggered: topBar.deleteSelectedLayer() }
                    }
                }

                MenuBarButton {
                    text: qsTr("View")
                    menu: Menu {
                        MenuItem { text: qsTr("Fullscreen") }
                        MenuItem { text: qsTr("Reset Layout") }
                        MenuSeparator {}
                        MenuItem { text: qsTr("Show Toolbar"); checkable: true; checked: true }
                        MenuItem { text: qsTr("Show Sidebar"); checkable: true; checked: true }
                    }
                }

                MenuBarButton {
                    text: qsTr("Help")
                    menu: Menu {
                        MenuItem { text: qsTr("Documentation") }
                        MenuItem { text: qsTr("Keyboard Shortcuts") }
                        MenuSeparator {}
                        MenuItem { text: qsTr("About MOKM Effector") }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.centerIn: parent
                    text: qsTr("Untitled")
                    color: Theme.mutedForeground
                    font.pixelSize: 13
                    elide: Text.ElideMiddle
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    property int pressX: 0
                    property int pressY: 0
                    onPressed: function(m) { pressX = m.x; pressY = m.y }
                    onPositionChanged: function(m) {
                        if ((m.buttons & Qt.LeftButton) && topBar.window) {
                            topBar.window.setX(topBar.window.x + m.x - pressX)
                            topBar.window.setY(topBar.window.y + m.y - pressY)
                        }
                    }
                }
            }

            Row {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                WindowButton {
                    source: "qrc:/icons/outline/minus.svg"
                    onClicked: { if (topBar.window) topBar.window.showMinimized() }
                }

                WindowButton {
                    id: maxBtn
                    source: "qrc:/icons/outline/maximize.svg"
                    onClicked: {
                        if (!topBar.window) return
                        if (topBar.window.visibility === Window.Maximized) {
                            topBar.window.showNormal()
                            maxBtn.source = "qrc:/icons/outline/maximize.svg"
                        } else {
                            topBar.window.showMaximized()
                            maxBtn.source = "qrc:/icons/outline/minimize.svg"
                        }
                    }
                }

                WindowButton {
                    source: "qrc:/icons/outline/x.svg"
                    hoverColor: "#e81123"
                    onClicked: { if (topBar.window) topBar.window.close() }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onPressed: function(m) { if (m.button === Qt.RightButton) contextMenu.popup(m.x, m.y) }
        }

        Menu {
            id: contextMenu
            MenuItem { text: qsTr("New File"); onTriggered: topBar.newFileRequested() }
            MenuItem { text: qsTr("Open File"); onTriggered: topBar.openFileRequested() }
            MenuSeparator {}
            MenuItem { text: qsTr("Save"); onTriggered: topBar.saveFileRequested() }
            MenuSeparator {}
            MenuItem { text: qsTr("Export Animation..."); onTriggered: topBar.exportVideoRequested() }
            MenuItem { text: qsTr("Export Image Sequence..."); onTriggered: topBar.exportImageSequenceRequested() }
            MenuSeparator {}
            MenuItem { text: qsTr("Undo"); enabled: topBar.canUndo; onTriggered: topBar.undoRequested() }
            MenuItem { text: qsTr("Redo"); enabled: topBar.canRedo; onTriggered: topBar.redoRequested() }
            MenuSeparator {}
            MenuItem { text: qsTr("Preferences"); onTriggered: topBar.preferencesRequested() }
        }
    }

    component MenuBarButton: Item {
        id: root
        property alias text: label.text
        property Menu menu
        width: label.implicitWidth + 16
        height: 28

        Rectangle {
            anchors.fill: parent
            radius: 4
            color: mouseArea.containsMouse ? Qt.lighter(Theme.primary, 1.2) : "transparent"
            border.color: mouseArea.containsMouse ? Theme.accent : "transparent"
            border.width: 1
        }

        Text {
            id: label
            anchors.centerIn: parent
            color: Theme.foreground
            font.pixelSize: 13
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (root.menu)
                    root.menu.popup(root, 0, root.height)
            }
        }
    }

    component WindowButton: Rectangle {
        id: btn
        implicitWidth: 30
        implicitHeight: 28
        color: mouseArea.containsMouse ? (hoverColor || Theme.secondaryHover) : "transparent"
        radius: 4

        property string source: ""
        property color hoverColor: Theme.secondaryHover
        property color iconColor: Theme.foreground
        signal clicked

        Image {
            id: iconImg
            anchors.centerIn: parent
            width: 14
            height: 14
            source: btn.source
            sourceSize.width: 24
            sourceSize.height: 24
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: btn.iconColor
                brightness: 1.0
                contrast: 1.0
                saturation: 0.0
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: { if (hoverColor === "#e81123") btn.iconColor = "#ffffff" }
            onExited: { btn.iconColor = Theme.foreground }
            onClicked: btn.clicked()
        }
    }
}
