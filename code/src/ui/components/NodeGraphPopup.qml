import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root

    property var graphModel: null
    property var undoManager: null

    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    width: 320
    height: 420

    background: Rectangle {
        color: Theme.secondary
        radius: 8
        border.color: Theme.border
        border.width: 1
    }

    onOpened: {
        searchField.text = ""
        nodeList.model = buildFilteredModel("")
        searchField.forceActiveFocus()
        searchField.selectAll()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        TextField {
            id: searchField
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.topMargin: 8
            height: 32
            placeholderText: "Search nodes..."
            color: Theme.foreground
            font.pixelSize: 13
            selectByMouse: true

            background: Rectangle {
                color: Theme.background
                radius: 4
                border.color: searchField.activeFocus ? Theme.accent : Theme.border
                border.width: 1
            }

            onTextChanged: nodeList.model = buildFilteredModel(text)
        }

        ListView {
            id: nodeList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            Layout.bottomMargin: 4
            clip: true
            spacing: 0

            section.property: "category"
            section.delegate: Rectangle {
                width: ListView.view.width
                height: 24
                color: Theme.muted

                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: section
                    color: Theme.mutedForeground
                    font.pixelSize: 10
                    font.bold: true
                }
            }

            delegate: Item {
                width: ListView.view.width - 8
                height: 28

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    radius: 4
                    color: mouseArea.containsMouse ? Theme.secondaryHover : "transparent"

                    RowLayout {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 2
                            color: modelData.color || Theme.accent
                        }

                        Text {
                            text: modelData.name || modelData.type || ""
                            color: Theme.foreground
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            var nodeId
                            if (undoManager)
                                nodeId = undoManager.qmlAddNode(modelData.type, 200 + Math.random() * 400, 200 + Math.random() * 300)
                            else if (graphModel)
                                nodeId = graphModel.qmlAddNode(modelData.type, 200 + Math.random() * 400, 200 + Math.random() * 300)
                            close()
                        }
                    }
                }
            }
        }
    }

    function buildFilteredModel(filterText) {
        var result = []
        if (!graphModel) return result

        var categories = graphModel.qmlCategories()
        var lowerFilter = filterText.toLowerCase()

        for (var ci = 0; ci < categories.length; ci++) {
            var cat = categories[ci]
            var types = graphModel.qmlNodesInCategory(cat.id)

            for (var ti = 0; ti < types.length; ti++) {
                var type = types[ti]
                if (filterText && type.toLowerCase().indexOf(lowerFilter) < 0)
                    continue

                var name = type.split("/").pop()
                name = name.charAt(0).toUpperCase() + name.slice(1)

                result.push({
                    type: type,
                    name: name,
                    category: cat.displayName,
                    color: cat.color
                })
            }
        }

        return result
    }
}
