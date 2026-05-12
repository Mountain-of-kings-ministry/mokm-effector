import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import NodeEditor

Item {
    id: root

    property var selectedObject: null

    readonly property var _target: {
        if (!selectedObject) return null;
        if (selectedObject.element !== undefined) return selectedObject.element;
        if (selectedObject.nodeGraphJson !== undefined) return selectedObject;
        return null;
    }

    Rectangle {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 36
        color: Theme.background
        border.color: Theme.border

        RowLayout {
            anchors.fill: parent
            anchors.margins: 6

            Text {
                text: _target ? (_target.name || "Node Graph") : "No Selection"
                color: Theme.foreground
                font.pixelSize: 13
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Fit"
                height: 26
                flat: true
                visible: canvas.zoom > 0
                onClicked: canvas.fitToView()
            }

            Text {
                text: Math.round(canvas.zoom * 100) + "%"
                color: Theme.mutedForeground
                font.pixelSize: 11
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter
            }

            Button {
                text: "+"
                height: 26
                flat: true
                visible: _target !== null
                onClicked: addNodePopup.open()
            }
        }
    }

    NodeCanvas {
        id: canvas
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        graphModel: _graphModel
        undoManager: _undoManager
        visible: _target !== null
    }

    Rectangle {
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: _target === null
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
            text: "Select a strip to edit its node graph"
            color: Theme.mutedForeground
            font.pixelSize: 13
        }
    }

    AddNodePopup {
        id: addNodePopup
        graphModel: _graphModel
        undoManager: _undoManager
    }

    on_TargetChanged: {
        if (_target && _target.nodeGraphJson) {
            _graphModel.qmlDeserializeFromJson(_target.nodeGraphJson);
        } else {
            _graphModel.clear();
        }
    }

    Connections {
        target: _graphModel
        function onQmlNodeAdded(nodeId) { saveGraph(); }
        function onQmlNodeRemoved(nodeId) { saveGraph(); }
        function onQmlEdgeAdded(edgeId) { saveGraph(); }
        function onQmlEdgeRemoved(edgeId) { saveGraph(); }
        function onQmlNodeDataChanged(nodeId, key) { saveGraph(); }
        function onQmlNodePositionChanged(nodeId) { saveGraph(); }
    }

    function saveGraph() {
        if (!_target) return;
        var json = _graphModel.qmlSerializeToJson();
        _target.nodeGraphJson = json;
    }
}
