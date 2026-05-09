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

    readonly property var animProperties: ["opacity", "x", "y", "rotation", "scaleX", "scaleY"]
    readonly property var propertyColors: [
        Theme.accent,
        "#ef4444",
        "#22c55e",
        "#f59e0b",
        "#a855f7",
        "#ec4899"
    ]

    readonly property var stripColors: [
        "#3b82f6", "#8b5cf6", "#ec4899", "#ef4444", "#f59e0b",
        "#22c55e", "#14b8a6", "#06b6d4", "#6366f1", "#d946ef"
    ]

    Item {
        id: controller
        property var timelineModel: null
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            height: 28
            color: Theme.secondaryHover

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                spacing: 0

                Text {
                    Layout.preferredWidth: root.layerNameWidth
                    text: qsTr("Layers")
                    color: Theme.mutedForeground
                    font.pixelSize: 10
                    font.letterSpacing: 0.5
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

                // ── Layer names column ──
                Item {
                    id: layerNames
                    Layout.preferredWidth: root.layerNameWidth
                    Layout.fillHeight: true

                    Repeater {
                        model: controller.timelineModel?.composition?.layers ?? 0

                        delegate: Rectangle {
                            id: nameRow
                            y: index * 24
                            width: parent.width
                            height: 24
                            color: {
                                if (root.selectedLayer === modelData)
                                    return Qt.alpha(Theme.accent, 0.2)
                                if (nameMouse.containsMouse)
                                    return Theme.secondaryHover
                                return index % 2 === 0 ? Theme.secondary : Qt.alpha(Theme.secondaryHover, 0.3)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                spacing: 4

                                Rectangle {
                                    width: 10
                                    height: 10
                                    radius: 2
                                    color: modelData?.enabled ? root.stripColors[index % root.stripColors.length] : Theme.muted
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
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.layerSelected(modelData)

                                drag.target: parent
                                drag.axis: Drag.YAxis
                                drag.smoothed: false

                                property int startIndex: index
                                property real startY: 0

                                onPressed: {
                                    startIndex = index;
                                    startY = parent.y;
                                    parent.z = 10;
                                }
                                onReleased: {
                                    parent.z = 0;
                                    var comp = controller.timelineModel?.composition;
                                    if (!comp) return;
                                    var rowHeight = 24;
                                    var currentY = parent.y;
                                    var targetIndex = Math.round(currentY / rowHeight);
                                    targetIndex = Math.max(0, Math.min(targetIndex, comp.layers.length - 1));
                                    parent.y = startY;
                                    if (targetIndex !== startIndex)
                                        comp.moveLayer(startIndex, targetIndex);
                                }
                            }
                        }
                    }
                }

                // ── Time strip + diamonds area ──
                Rectangle {
                    id: stripArea
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Qt.alpha(Theme.background, 0.3)

                    Repeater {
                        model: controller.timelineModel?.composition?.layers ?? 0

                        delegate: Item {
                            id: stripRow
                            y: index * 24
                            height: 24
                            width: parent.width

                            property var layerObj: modelData

                            // ── Layer strip bar ──
                            Rectangle {
                                id: stripBar
                                x: layerObj.startFrame * root.pixelPerFrame
                                width: Math.max(4, layerObj.duration * root.pixelPerFrame)
                                height: parent.height - 4
                                y: 2
                                radius: 3
                                color: Qt.alpha(root.stripColors[index % root.stripColors.length], 0.4)
                                border.color: Qt.alpha(root.stripColors[index % root.stripColors.length], 0.7)
                                border.width: 1

                                MouseArea {
                                    id: stripDrag
                                    anchors.fill: parent
                                    cursorShape: Qt.SizeHorCursor

                                    property int dragStartFrame: 0
                                    property real dragStartX: 0

                                    onPressed: function(mouse) {
                                        dragStartFrame = layerObj.startFrame;
                                        dragStartX = mouse.x;
                                        stripBar.color = Qt.alpha(root.stripColors[index % root.stripColors.length], 0.6);
                                    }
                                    onReleased: {
                                        stripBar.color = Qt.alpha(root.stripColors[index % root.stripColors.length], 0.4);
                                    }
                                    onPositionChanged: function(mouse) {
                                        if (!(mouse.buttons & Qt.LeftButton)) return;
                                        var dx = mouse.x - dragStartX;
                                        var deltaFrames = Math.round(dx / root.pixelPerFrame);
                                        var newFrame = Math.max(0, dragStartFrame + deltaFrames);
                                        layerObj.startFrame = newFrame;
                                    }
                                }

                                // ── Duration drag handle (right edge) ──
                                MouseArea {
                                    id: durationHandle
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 20
                                    height: parent.height
                                    cursorShape: Qt.SizeHorCursor

                                    property int dragStartDuration: 0
                                    property int dragStartFrame: 0
                                    property point dragGlobalStart: Qt.point(0, 0)

                                    onPressed: function(mouse) {
                                        dragStartDuration = layerObj.duration;
                                        dragStartFrame = layerObj.startFrame;
                                        dragGlobalStart = mapToGlobal(mouse.x, mouse.y);
                                    }
                                    onPositionChanged: function(mouse) {
                                        if (!(mouse.buttons & Qt.LeftButton)) return;
                                        var currentGlobal = mapToGlobal(mouse.x, mouse.y);
                                        var dx = currentGlobal.x - dragGlobalStart.x;
                                        var deltaFrames = dx / root.pixelPerFrame;
                                        var newDuration = Math.max(1, Math.round(dragStartDuration + deltaFrames));
                                        var compDuration = controller.timelineModel?.composition?.duration ?? 150;
                                        if (dragStartFrame + newDuration > compDuration)
                                            newDuration = compDuration - dragStartFrame;
                                        if (newDuration !== layerObj.duration)
                                            layerObj.duration = newDuration;
                                    }
                                }
                            }

                            // ── Keyframe diamonds ──
                            Repeater {
                                model: root.animProperties.length
                                delegate: Item {
                                    id: kfDelegate
                                    property var propName: root.animProperties[modelData]
                                    property var frames: kfDelegate.computeFrames()

                                    function computeFrames() {
                                        if (!controller.timelineModel) return [];
                                        var _ = controller.timelineModel.keyframesStamp;
                                        return controller.timelineModel.keyframeFrames(stripRow.layerObj, propName);
                                    }

                                    Repeater {
                                        model: parent.frames
                                        delegate: Rectangle {
                                            x: modelData * root.pixelPerFrame - 3
                                            y: 4 + parent.parent.modelData * 3
                                            width: 6
                                            height: 6
                                            radius: 1
                                            color: root.propertyColors[parent.parent.modelData % root.animProperties.length]
                                        }
                                    }
                                }
                            }

                            // ── Playhead line ──
                            Rectangle {
                                x: (controller.timelineModel?.currentFrame ?? 0) * root.pixelPerFrame
                                width: 1
                                height: parent.height
                                color: Qt.alpha(Theme.accent, 0.5)
                            }

                            // ── Click to select ──
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                onClicked: root.layerSelected(layerObj)
                            }
                        }
                    }
                }
            }
        }
    }
}
