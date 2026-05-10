import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root
    color: Theme.background
    clip: true

    property var nodeGraph: null
    property var selectedStrip: null

    function _detectType(obj) {
        if (!obj)
            return "none";
        if (obj.nodeGraph !== undefined)
            return "nodeStrip";
        if (obj.deleteStrip)
            return "strip";
        if (obj.deleteTrack)
            return "track";
        if (obj.deleteLayer)
            return "layer";
        if (obj.tracks !== undefined)
            return "layer";
        if (obj.strips !== undefined)
            return "track";
        if (obj.element !== undefined)
            return "strip";
        return "unknown";
    }

    onSelectedStripChanged: {
        var t = _detectType(selectedStrip);
        if (t === "nodeStrip" && selectedStrip.nodeGraph) {
            root.nodeGraph = selectedStrip.nodeGraph;
        } else if (t === "strip" && selectedStrip.element) {
            root.nodeGraph = null;
        } else {
            root.nodeGraph = null;
        }
    }

    // Top toolbar
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 42
        z: 10
        color: Theme.secondary
        border.color: Theme.border

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 12
            spacing: 12

            Button {
                text: "Rectangle"
                visible: root.nodeGraph !== null
                height: 28
                flat: true
                onClicked: {
                    if (root.nodeGraph)
                        root.nodeGraph.addNode("Rectangle");
                }
            }
            Button {
                text: "Ellipse"
                visible: root.nodeGraph !== null
                height: 28
                flat: true
                onClicked: {
                    if (root.nodeGraph)
                        root.nodeGraph.addNode("Ellipse");
                }
            }
            Button {
                text: "Circle"
                visible: root.nodeGraph !== null
                height: 28
                flat: true
                onClicked: {
                    if (root.nodeGraph)
                        root.nodeGraph.addNode("Circle");
                }
            }
            Button {
                text: "Triangle"
                visible: root.nodeGraph !== null
                height: 28
                flat: true
                onClicked: {
                    if (root.nodeGraph)
                        root.nodeGraph.addNode("Triangle");
                }
            }
            Button {
                text: "Text"
                visible: root.nodeGraph !== null
                height: 28
                flat: true
                onClicked: {
                    if (root.nodeGraph)
                        root.nodeGraph.addNode("Text");
                }
            }
            Button {
                text: "Cook"
                visible: root.nodeGraph !== null
                height: 28
                flat: true
                onClicked: {
                    if (root.selectedStrip && root.selectedStrip.cook)
                        root.selectedStrip.cook();
                }
            }
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: root.nodeGraph ? ("Nodes: " + root.nodeGraph.nodeCount) : "No Graph Selected"
            color: Theme.mutedForeground
            font.pixelSize: 10
        }
    }

    // Content area
    Item {
        anchors.top: parent.top
        anchors.topMargin: 42
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        // NodeGraphView — active when a nodeGraph is set
        NodeGraphView {
            id: graphView
            anchors.fill: parent
            nodeGraph: root.nodeGraph
            visible: root.nodeGraph !== null
            interactive: true
        }

        // Placeholder — shown when no nodeGraph is selected
        Rectangle {
            anchors.fill: parent
            visible: root.nodeGraph === null
            color: Theme.background

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.strokeStyle = Theme.border;
                    ctx.lineWidth = 1;
                    var gs = 24;
                    for (var x = 0; x < width; x += gs) {
                        ctx.beginPath();
                        ctx.moveTo(x, 0);
                        ctx.lineTo(x, height);
                        ctx.stroke();
                    }
                    for (var y = 0; y < height; y += gs) {
                        ctx.beginPath();
                        ctx.moveTo(0, y);
                        ctx.lineTo(width, y);
                        ctx.stroke();
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: qsTr("Select a NodeStrip to edit its node graph")
                color: Theme.mutedForeground
                font.pixelSize: 13
            }
        }
    }
}
