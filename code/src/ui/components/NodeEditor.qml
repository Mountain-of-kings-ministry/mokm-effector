import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import NodeEditor

Item {
    id: root

    property var timelineModel: null
    property var selectedObject: null

    property var _target: null
    property bool _loading: false

    onSelectedObjectChanged: {
        console.log("NodeEditor: selectedObject changed:", selectedObject ? (selectedObject.name || selectedObject) : "null");
        _target = computeTarget(selectedObject);
    }

    Component.onCompleted: {
        console.log("NodeEditor: component completed");
        _target = computeTarget(selectedObject);
    }

    function computeTarget(obj) {
        if (!obj) return null;
        if (typeof obj.nodeGraphJson !== 'undefined') {
            console.log("NodeEditor: target has nodeGraphJson:", obj.name, "length:", obj.nodeGraphJson ? obj.nodeGraphJson.length : 0);
            return obj;
        }
        console.log("NodeEditor: target does NOT have nodeGraphJson:", obj ? obj.name : "null");
        return null;
    }

    readonly property var _comp: timelineModel ? timelineModel.composition : null

    function _buildSearchableItems() {
        var items = [];
        if (!_comp) return items;
        for (var li = 0; li < _comp.layerCount(); li++) {
            var tl = _comp.layerAt(li);
            items.push({ object: tl, name: tl.name, depth: 0, typeName: "Layer" });
            for (var ti = 0; ti < tl.trackCount; ti++) {
                var tr = tl.trackAt(ti);
                items.push({ object: tr, name: tr.name, depth: 1, typeName: "Track" });
                for (var si = 0; si < tr.stripCount; si++) {
                    var st = tr.stripAt(si);
                    var elName = st.element ? st.element.name : "?";
                    items.push({ object: st, name: st.name + " (" + elName + ")", depth: 2, typeName: "Strip" });
                }
            }
        }
        return items;
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

            Button {
                id: selectBtn
                text: _target ? (selectedObject ? selectedObject.name || _target.name || "Selected" : "Select\u2026") : "Select\u2026"
                height: 26
                flat: true
                onClicked: selectPopup.open()
            }

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

                Shortcut {
                    sequence: "Ctrl+Z"
                    onActivated: if (_undoManager) _undoManager.undo()
                }
                Shortcut {
                    sequence: "Ctrl+Y"
                    onActivated: if (_undoManager) _undoManager.redo()
                }
                Shortcut {
                    sequence: "Delete"
                    onActivated: {
                        if (!canvas || !_graphModel) return
                        var sel = canvas.selectedNodeIds
                        if (sel) {
                            var ids = sel.length !== undefined ? sel : [sel]
                            for (var i = 0; i < ids.length; i++)
                                _undoManager.qmlRemoveNode(ids[i])
                        }
                    }
                }
                Shortcut {
                    sequence: "Shift+A"
                    onActivated: addNodePopup.open()
                }
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
            text: "Select a layer, track, or strip to edit its node graph"
            color: Theme.mutedForeground
            font.pixelSize: 13
        }
    }

    NodeGraphPopup {
        id: addNodePopup
        graphModel: _graphModel
        undoManager: _undoManager
    }

    on_TargetChanged: {
        console.log("NodeEditor: _target changed, has nodeGraphJson:", _target ? (_target.nodeGraphJson ? true : false) : false);
        _loading = true;
        if (_target && _target.nodeGraphJson) {
            console.log("NodeEditor: deserializing graph, json length:", _target.nodeGraphJson.length);
            _graphModel.qmlDeserializeFromJson(_target.nodeGraphJson);
            console.log("NodeEditor: deserialization complete, node count:", _graphModel.qmlNodeIds().length);
        } else {
            console.log("NodeEditor: clearing graph");
            _graphModel.clear();
        }
        _loading = false;
    }

    property Timer _posTimer: Timer {
        interval: 2000
        onTriggered: doSave()
    }

    Connections {
        target: _graphModel
        function onQmlNodeAdded(nodeId) {
            console.log("NodeEditor: node added", nodeId);
            saveGraph(true);
        }
        function onQmlNodeRemoved(nodeId) {
            console.log("NodeEditor: node removed", nodeId);
            saveGraph(true);
        }
        function onQmlEdgeAdded(edgeId) {
            console.log("NodeEditor: edge added", edgeId);
            saveGraph(true);
        }
        function onQmlEdgeRemoved(edgeId) {
            console.log("NodeEditor: edge removed", edgeId);
            saveGraph(true);
        }
        function onQmlNodeDataChanged(nodeId, key) {
            saveGraph(true);
        }
        function onQmlNodePositionChanged(nodeId) {
            saveGraph(false);
        }
        function onQmlNodePortsChanged(nodeId) {
        }
    }

    function saveGraph(immediate) {
        if (!_target || _loading) return;
        if (immediate) {
            _posTimer.stop();
            doSave();
        } else {
            _posTimer.restart();
        }
    }

    function doSave() {
        if (!_target || _loading) return;
        var json = _graphModel.qmlSerializeToJson();
        console.log("NodeEditor: saving graph, json length:", json.length);
        _target.nodeGraphJson = json;
    }

    Popup {
        id: selectPopup
        x: selectBtn.x; y: 36
        width: 300; height: 400
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property var items: []
        onAboutToShow: {
            searchField.text = "";
            items = _buildSearchableItems();
            rebuildFilter();
        }

        ListModel { id: filterModel }

        function rebuildFilter() {
            filterModel.clear();
            var q = searchField.text.toLowerCase();
            for (var i = 0; i < items.length; i++) {
                var it = items[i];
                if (!q || it.name.toLowerCase().indexOf(q) >= 0)
                    filterModel.append(it);
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.background
            border.color: Theme.border

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 4; spacing: 4

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: "Search\u2026"
                    onTextChanged: selectPopup.rebuildFilter()
                }

                ListView {
                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                    model: filterModel
                    delegate: Rectangle {
                        width: ListView.view.width; height: 28
                        color: ma.containsMouse ? Theme.muted : "transparent"

                        RowLayout {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.leftMargin: 4 + model.depth * 16
                            spacing: 6

                            Text {
                                text: model.depth === 0 ? "\uD83D\uDCC1" : model.depth === 1 ? "\uD83D\uDCCB" : "\uD83C\uDF9E"
                                font.pixelSize: 10
                            }
                            Text { text: model.name; color: Theme.foreground; font.pixelSize: 11; elide: Text.ElideRight }
                            Text { text: "(" + model.typeName + ")"; color: Theme.mutedForeground; font.pixelSize: 9 }
                        }

                        MouseArea {
                            id: ma; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                selectedObject = model.object;
                                selectPopup.close();
                            }
                        }
                    }
                }
            }
        }
    }
}
