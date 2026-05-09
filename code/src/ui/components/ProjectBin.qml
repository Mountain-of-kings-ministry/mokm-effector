import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root
    color: Theme.secondary
    clip: true

    property Composition composition: null
    property Project project: null

    signal createRectLayer
    signal createCircleLayer
    signal createTriangleLayer
    signal createTextLayer
    signal layerSelected(var layer)
    signal addAssetToTrack(var asset)
    signal addAssetToNewTrack(var asset)

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
                        text: qsTr("Assets")
                        color: Theme.mutedForeground
                        font.pixelSize: 10
                        font.letterSpacing: 0.5
                    }
                }

                Repeater {
                    model: root.project && root.project.assets ? root.project.assets : 0

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 22
                        color: {
                            if (root._selected === modelData) return Theme.selected
                            if (assetMouse.containsMouse) return Theme.secondaryHover
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
                                color: root._selected === modelData ? "#ffffff" : Theme.foreground
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: assetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.LeftButton) {
                                    root._selected = modelData
                                    root.layerSelected(modelData)
                                }
                            }
                            onPressed: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    root._selected = modelData
                                    root.layerSelected(modelData)
                                    assetContextMenu.asset = modelData
                                    assetContextMenu.popup(assetMouse, mouse.x, mouse.y)
                                }
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
        onPressed: function(m) {
            if (!root.project) return;
            contextMenu.popup(m.x, m.y);
        }
    }

    Menu {
        id: contextMenu
        MenuItem { text: qsTr("Add Rectangle"); onTriggered: root.createRectLayer() }
        MenuItem { text: qsTr("Add Circle"); onTriggered: root.createCircleLayer() }
        MenuItem { text: qsTr("Add Triangle"); onTriggered: root.createTriangleLayer() }
        MenuSeparator {}
        MenuItem { text: qsTr("Add Text"); onTriggered: root.createTextLayer() }
    }

    Menu {
        id: assetContextMenu
        property var asset: null

        MenuItem {
            text: qsTr("Add to Track")
            enabled: root.composition !== null && assetContextMenu.asset !== null
            Menu {
                id: trackSubmenu
                Instantiator {
                    model: root.composition && root.composition.tracks ? root.composition.tracks : 0
                    delegate: MenuItem {
                        text: modelData?.name ?? "Track " + (index + 1)
                        onTriggered: {
                            if (assetContextMenu.asset && root.composition) {
                                var track = modelData;
                                var clip = assetContextMenu.asset.clone(track);
                                clip.startFrame = 0;
                                clip.duration = 90;
                                track.addClip(clip);
                                if (root.project) root.project.captureSnapshot();
                            }
                        }
                    }
                    onObjectAdded: (index, obj) => trackSubmenu.insertItem(index, obj)
                    onObjectRemoved: (index, obj) => trackSubmenu.removeItem(obj)
                }
                MenuSeparator {}
                MenuItem {
                    text: qsTr("+ New Track")
                    onTriggered: {
                        if (assetContextMenu.asset && root.composition) {
                            var track = root.composition.addTrack();
                            var clip = assetContextMenu.asset.clone(track);
                            clip.startFrame = 0;
                            clip.duration = 90;
                            track.addClip(clip);
                            if (root.project) root.project.captureSnapshot();
                        }
                    }
                }
            }
        }

        MenuSeparator {}

        MenuItem {
            text: qsTr("Delete Asset")
            onTriggered: {
                if (assetContextMenu.asset && root.project) {
                    root.project.removeAsset(assetContextMenu.asset);
                    if (root._selected === assetContextMenu.asset)
                        root._selected = null;
                    if (root.project) root.project.captureSnapshot();
                }
            }
        }
    }
}
