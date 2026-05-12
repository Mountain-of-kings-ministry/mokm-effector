import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import mokm_effector

Item {
    id: root
    property var nodeGraph

    // Top toolbar: zoom controls and node count
    Rectangle {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 36
        color: (typeof Theme !== 'undefined' && Theme.headerBackground ? Theme.headerBackground : "#2b2b2b")
        border.color: (typeof Theme !== 'undefined' && Theme.border ? Theme.border : "#444444")

        RowLayout {
            anchors.fill: parent
            anchors.margins: 6

            Item {
                Layout.fillWidth: true
            }

            Text {
                id: scaleLabel
                visible: root.nodeGraph !== null
                text: graphView ? (Math.round(graphView.scale * 100) + "%") : ""
                color: Theme.mutedForeground
                font.pixelSize: 11
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter
            }

            Button {
                text: "Fit"
                visible: root.nodeGraph !== null
                height: 26
                flat: true
                onClicked: graphView.fitContent()
            }

            Text {
                Layout.rightMargin: 12
                Layout.alignment: Qt.AlignVCenter
                text: root.nodeGraph ? (root.nodeGraph.nodeCount + " nodes") : "No Graph Selected"
                color: (typeof Theme !== 'undefined' && Theme.mutedForeground ? Theme.mutedForeground : "#a0a0a0")
                font.pixelSize: 10
            }
        }
    }

    // Content area
    Item {
        anchors.top: parent.top
        anchors.topMargin: 36
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        NodeGraphView {
            id: graphView
            anchors.fill: parent
            nodeGraph: root.nodeGraph
            visible: root.nodeGraph !== null
            interactive: true
            Component.onCompleted: {
                if (graphView)
                    graphView.scale = 0.75;
            }
        }

        // Placeholder
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
