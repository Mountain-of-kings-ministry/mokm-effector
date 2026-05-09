import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root
    color: Theme.secondary
    clip: true

    property alias timelineModel: controller.timelineModel
    property var selectedLayer: null
    signal layerSelected(var layer)

    property real pixelPerFrame: 8
    property int layerNameWidth: 140

    readonly property var stripColors: ["#3b82f6", "#8b5cf6", "#ec4899", "#ef4444", "#f59e0b", "#22c55e", "#14b8a6", "#06b6d4", "#6366f1", "#d946ef"]

    Item {
        id: controller
        property var timelineModel: null
    }

    function snapFrame(v) {
        return Math.round(v);
    }
    function debug(msg) {
        console.log("[TimelineStrip]", msg);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            height: 28
            color: Theme.secondaryHover
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                Text {
                    Layout.preferredWidth: root.layerNameWidth
                    text: qsTr("Layers")
                    color: Theme.mutedForeground
                    font.pixelSize: 10
                }
                TimeRuler {
                    Layout.fillWidth: true
                    timelineModel: controller.timelineModel
                    pixelPerFrame: root.pixelPerFrame
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            RowLayout {
                width: parent.width
                spacing: 0

                // Layer Names
                Item {
                    Layout.preferredWidth: root.layerNameWidth
                    Layout.fillHeight: true
                    Repeater {
                        model: controller.timelineModel?.composition?.layers ?? 0
                        delegate: Rectangle {
                            y: index * 28
                            width: parent.width
                            height: 28
                            color: (root.selectedLayer === modelData) ? Qt.alpha(Theme.accent, 0.2) : nameMouse.containsMouse ? Theme.secondaryHover : index % 2 === 0 ? Theme.secondary : Qt.alpha(Theme.secondaryHover, 0.3)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                Rectangle {
                                    width: 10
                                    height: 10
                                    radius: 2
                                    color: root.stripColors[index % root.stripColors.length]
                                }
                                Text {
                                    text: modelData?.name ?? ""
                                    color: Theme.foreground
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            MouseArea {
                                id: nameMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.layerSelected(modelData)
                            }
                        }
                    }
                }

                // ==================== STRIP AREA ====================
                Rectangle {
                    id: stripArea
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Qt.alpha(Theme.background, 0.3)

                    Repeater {
                        model: controller.timelineModel?.composition?.layers ?? 0

                        delegate: Item {
                            id: stripRow
                            y: index * 28
                            height: 28
                            width: stripArea.width

                            property var layerObj: modelData
                            property real visualStart: 0
                            property real visualDuration: 100
                            property bool isDragging: false

                            Component.onCompleted: resetFromModel()

                            function resetFromModel() {
                                if (!layerObj)
                                    return;
                                visualStart = layerObj.startFrame * root.pixelPerFrame;
                                visualDuration = Math.max(40, layerObj.duration * root.pixelPerFrame);
                            }

                            Rectangle {
                                id: stripBar
                                x: stripRow.visualStart
                                y: 4
                                width: stripRow.visualDuration
                                height: 20
                                radius: 4
                                color: Qt.alpha(root.stripColors[index % root.stripColors.length], 0.65)
                                border.color: Qt.lighter(color, 1.4)
                                border.width: 1
                                z: stripRow.isDragging ? 10 : 0

                                // LEFT EDGE - Colored differently
                                Rectangle {
                                    id: leftEdge
                                    width: 6
                                    height: parent.height
                                    anchors.left: parent.left
                                    color: "#ffffff"
                                    opacity: 0.35
                                    radius: 4
                                }

                                // RIGHT EDGE - Colored differently
                                Rectangle {
                                    id: rightEdge
                                    width: 6
                                    height: parent.height
                                    anchors.right: parent.right
                                    color: "#ffffff"
                                    opacity: 0.25
                                    radius: 4
                                }

                                // LEFT HANDLE
                                MouseArea {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: 12
                                    cursorShape: Qt.SizeHorCursor
                                    hoverEnabled: true
                                    preventStealing: true
                                    z: 5

                                    property real startMouseX: 0
                                    property real startVisualStart: 0
                                    property real startVisualDuration: 0

                                    onPressed: mouse => {
                                        stripRow.isDragging = true;
                                        startMouseX = mapToItem(stripArea, mouse.x, 0).x;
                                        startVisualStart = stripRow.visualStart;
                                        startVisualDuration = stripRow.visualDuration;
                                        root.layerSelected(stripRow.layerObj);
                                    }

                                    onPositionChanged: mouse => {
                                        if (!pressed)
                                            return;
                                        let mx = mapToItem(stripArea, mouse.x, 0).x;
                                        let dx = mx - startMouseX;
                                        let newDur = Math.max(40, startVisualDuration - dx);
                                        let newStart = startVisualStart + (startVisualDuration - newDur);

                                        stripRow.visualStart = Math.max(0, newStart);
                                        stripRow.visualDuration = newDur;
                                    }

                                    onReleased: {
                                        stripRow.isDragging = false;
                                        commitChanges();
                                    }
                                }

                                // MAIN DRAG
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                    preventStealing: true

                                    property real startMouseX: 0
                                    property real startVisualStart: 0

                                    onPressed: mouse => {
                                        stripRow.isDragging = true;
                                        startMouseX = mapToItem(stripArea, mouse.x, 0).x;
                                        startVisualStart = stripRow.visualStart;
                                        root.layerSelected(stripRow.layerObj);
                                    }

                                    onPositionChanged: mouse => {
                                        if (!pressed)
                                            return;
                                        let mx = mapToItem(stripArea, mouse.x, 0).x;
                                        let dx = mx - startMouseX;
                                        stripRow.visualStart = Math.max(0, startVisualStart + dx);
                                    }

                                    onReleased: {
                                        stripRow.isDragging = false;
                                        commitChanges();
                                    }
                                }

                                // RIGHT HANDLE
                                MouseArea {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: 12
                                    cursorShape: Qt.SizeHorCursor
                                    hoverEnabled: true
                                    preventStealing: true
                                    z: 5

                                    property real startMouseX: 0
                                    property real startVisualDuration: 0

                                    onPressed: mouse => {
                                        stripRow.isDragging = true;
                                        startMouseX = mapToItem(stripArea, mouse.x, 0).x;
                                        startVisualDuration = stripRow.visualDuration;
                                        root.layerSelected(stripRow.layerObj);
                                    }

                                    onPositionChanged: mouse => {
                                        if (!pressed)
                                            return;
                                        let mx = mapToItem(stripArea, mouse.x, 0).x;
                                        let dx = mx - startMouseX;
                                        stripRow.visualDuration = Math.max(40, startVisualDuration + dx);
                                    }

                                    onReleased: {
                                        stripRow.isDragging = false;
                                        commitChanges();
                                    }
                                }
                            }

                            // Playhead
                            Rectangle {
                                x: (controller.timelineModel?.currentFrame ?? 0) * root.pixelPerFrame
                                width: 2
                                height: parent.height
                                color: Theme.accent
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.layerSelected(stripRow.layerObj)
                            }

                            function commitChanges() {
                                if (!layerObj)
                                    return;
                                layerObj.startFrame = snapFrame(visualStart / root.pixelPerFrame);
                                layerObj.duration = snapFrame(visualDuration / root.pixelPerFrame);
                                Qt.callLater(resetFromModel);
                            }
                        }
                    }
                }
            }
        }
    }
}
