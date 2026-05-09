import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root
    color: Theme.secondary
    clip: true

    property Composition composition: null

    signal createRectLayer
    signal createCircleLayer
    signal createTriangleLayer
    signal createTextLayer
    signal layerSelected(var layer)

    property var _selected: null

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            height: 32
            color: Theme.secondaryHover

            Text {
                anchors.centerIn: parent
                text: qsTr("Project")
                color: Theme.mutedForeground
                font.pixelSize: 11
                font.letterSpacing: 0.5
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    height: 22
                    color: "transparent"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 12
                        text: qsTr("Compositions")
                        color: Theme.mutedForeground
                        font.pixelSize: 10
                        font.letterSpacing: 0.5
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 24
                    color: Qt.alpha(Theme.secondaryHover, 0.5)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 20
                        text: root.composition?.name ?? ""
                        color: Theme.foreground
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                Repeater {
                    model: root.composition?.layers ?? 0

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 22
                        color: {
                            if (root._selected === modelData) return Theme.primary
                            if (layerMouse.containsMouse) return Theme.secondaryHover
                            return index % 2 === 0 ? "transparent" : Qt.alpha(Theme.secondaryHover, 0.15)
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 28
                            spacing: 6

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 2
                                color: modelData?.enabled ?? false ? Theme.foreground : Theme.muted
                            }

                            Text {
                                text: modelData?.name ?? ""
                                color: root._selected === modelData ? Theme.background : Theme.foreground
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: layerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root._selected = modelData
                                root.layerSelected(modelData)
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onPressed: function(m) { contextMenu.popup(m.x, m.y) }
    }

    Menu {
        id: contextMenu
        MenuItem { text: qsTr("Add Rectangle"); onTriggered: root.createRectLayer() }
        MenuItem { text: qsTr("Add Circle"); onTriggered: root.createCircleLayer() }
        MenuItem { text: qsTr("Add Triangle"); onTriggered: root.createTriangleLayer() }
        MenuSeparator {}
        MenuItem { text: qsTr("Add Text"); onTriggered: root.createTextLayer() }
    }
}
