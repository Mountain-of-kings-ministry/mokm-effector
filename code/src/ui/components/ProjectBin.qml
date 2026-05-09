import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: binRoot
    color: Theme.secondary
    clip: true

    // Robust root reference for delegates
    readonly property var bin: binRoot

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
            id: binScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                id: binContent
                width: binScrollView.availableWidth
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
                    model: bin.project && bin.project.assets ? bin.project.assets : 0

                    delegate: Rectangle {
                        id: assetDelegate
                        Layout.fillWidth: true
                        height: 22
                        color: {
                            if (bin._selected === modelData) return Theme.selected
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
                                color: bin._selected === modelData ? "#ffffff" : Theme.foreground
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
                                    bin._selected = modelData
                                    bin.layerSelected(modelData)
                                }
                            }
                            onPressed: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    bin._selected = modelData
                                    bin.layerSelected(modelData)
                                    assetContextMenu.asset = modelData
                                    assetContextMenu.popup(assetMouse, mouse.x, mouse.y)
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 50

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onPressed: function(m) {
                            if (!bin.project) return;
                            contextMenu.popup(m.x, m.y);
                        }
                    }
                }
            }
        }
    }

    Menu {
        id: contextMenu
        MenuItem { text: qsTr("Add Rectangle"); onTriggered: bin.createRectLayer() }
        MenuItem { text: qsTr("Add Circle"); onTriggered: bin.createCircleLayer() }
        MenuItem { text: qsTr("Add Triangle"); onTriggered: bin.createTriangleLayer() }
        MenuSeparator {}
        MenuItem { text: qsTr("Add Text"); onTriggered: bin.createTextLayer() }
    }

    Menu {
        id: assetContextMenu
        property var asset: null

        MenuItem {
            text: qsTr("Add to Track")
            enabled: bin.composition !== null && assetContextMenu.asset !== null
            Menu {
                id: trackSubmenu
                Instantiator {
                    model: bin.composition && bin.composition.tracks ? bin.composition.tracks : 0
                    delegate: MenuItem {
                        text: modelData?.name ?? "Track " + (index + 1)
                        onTriggered: {
                            if (assetContextMenu.asset && bin.composition) {
                                var track = modelData;
                                var clip = assetContextMenu.asset.clone(track);
                                clip.startFrame = 0;
                                clip.duration = 90;
                                track.addClip(clip);
                                if (bin.project) bin.project.captureSnapshot();
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
                        if (assetContextMenu.asset && bin.composition) {
                            var track = bin.composition.addTrack();
                            var clip = assetContextMenu.asset.clone(track);
                            clip.startFrame = 0;
                            clip.duration = 90;
                            track.addClip(clip);
                            if (bin.project) bin.project.captureSnapshot();
                        }
                    }
                }
            }
        }

        MenuSeparator {}

        MenuItem {
            text: qsTr("Delete Asset")
            onTriggered: {
                if (assetContextMenu.asset && bin.project) {
                    bin.project.removeAsset(assetContextMenu.asset);
                    if (bin._selected === assetContextMenu.asset)
                        bin._selected = null;
                    if (bin.project) bin.project.captureSnapshot();
                }
            }
        }
    }
}
