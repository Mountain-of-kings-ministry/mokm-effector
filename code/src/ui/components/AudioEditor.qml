import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root
    color: Theme.background
    clip: true

    property var timelineModel: null
    property var selectedObject: null
    property real pixelPerFrame: 8

    // ── Target resolution ──
    readonly property var _target: {
        if (!selectedObject) return null;
        if (selectedObject.element !== undefined)
            return selectedObject.element; // Strip → AudioLayer
        if (selectedObject.strips !== undefined && selectedObject.tracks === undefined)
            return selectedObject; // Track
        if (selectedObject.tracks !== undefined)
            return selectedObject; // TimelineLayer
        return selectedObject;
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

    // ── Waveform data ──
    property var _waveformData: []

    function _loadWaveform() {
        if (!_target || !_target.waveformData) {
            _waveformData = [];
            return;
        }
        _waveformData = _target.waveformData;
    }

    on_TargetChanged: _loadWaveform()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── HEADER ──
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: Theme.secondaryHover

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Button {
                    id: selectBtn
                    text: _target ? (selectedObject ? selectedObject.name || _target.name || "Selected" : "Select\u2026") : "Select\u2026"
                    height: 26
                    flat: true
                    onClicked: selectPopup.open()
                }

                Text {
                    text: _target ? (_target.name || "Audio") : "No Target Selected"
                    color: Theme.foreground
                    font.pixelSize: 14
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "Render"
                    highlighted: true
                }
            }
        }

        // ── Main content ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                color: Theme.secondary

                // Waveform
                Canvas {
                    id: waveform
                    anchors.fill: parent
                    anchors.bottomMargin: 140

                    onPaint: {
                        var ctx = getContext("2d");
                        if (!ctx) return;
                        ctx.clearRect(0, 0, width, height);

                        var w = width;
                        var h = height;
                        var center = h / 2;
                        var data = root._waveformData;
                        if (data.length === 0) return;

                        var step = Math.max(1, Math.floor(data.length / w));

                        ctx.strokeStyle = "#67e8f9";
                        ctx.lineWidth = 1.8;
                        ctx.beginPath();

                        for (var x = 0; x < w; x++) {
                            var idx = Math.floor(x * step);
                            if (idx >= data.length) break;
                            var sample = data[idx];
                            var y = center - sample * center * 0.85;
                            if (x === 0) ctx.moveTo(x, y);
                            else ctx.lineTo(x, y);
                        }
                        ctx.stroke();

                        ctx.strokeStyle = Qt.rgba(255,255,255,0.08);
                        ctx.lineWidth = 1;
                        ctx.beginPath();
                        ctx.moveTo(0, center);
                        ctx.lineTo(w, center);
                        ctx.stroke();
                    }
                }

                // Playhead
                Rectangle {
                    x: (timelineModel?.currentFrame ?? 0) * pixelPerFrame
                    width: 3; height: parent.height; color: Theme.accent; z: 100
                }
            }

            // Automation lanes
            Column {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 140

                AutomationLane { width: parent.width; height: 46; label: "Volume"; color: "#c084fc"; unit: "dB"
                    property real val: root._target ? root._target.volume || 0 : 0
                }
                AutomationLane { width: parent.width; height: 46; label: "Pan"; color: "#fb923c"; unit: "%"
                    property real val: root._target ? (root._target.pan !== undefined ? root._target.pan : 0) : 0
                }
                AutomationLane { width: parent.width; height: 48; label: "Output"; color: "#4ade80"
                    property real val: root._target ? 1.0 : 0
                }
            }
        }
    }

    // ── Select Popup ──
    Popup {
        id: selectPopup
        x: selectBtn.x; y: 52
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

    // ── Automation Lane component ──
    component AutomationLane: Rectangle {
        color: Theme.secondaryHover
        border.color: Theme.border; border.width: 1

        property string label: "Parameter"
        property color laneColor: "#a78bfa"
        property string unit: ""

        RowLayout {
            anchors.fill: parent; anchors.margins: 8; spacing: 12
            Text { text: parent.parent.label; color: Theme.foreground; font.pixelSize: 12; Layout.preferredWidth: 110 }

            Canvas {
                Layout.fillWidth: true; Layout.fillHeight: true
                onPaint: {
                    var ctx = getContext("2d");
                    if (!ctx) return;
                    ctx.clearRect(0, 0, width, height);
                    ctx.strokeStyle = parent.parent.laneColor;
                    ctx.lineWidth = 2.5;
                    ctx.beginPath();
                    for (var i = 0; i < width; i += 8) {
                        var y = height * (1 - (0.5 + Math.sin(i * 0.02) * 0.2));
                        if (i === 0) ctx.moveTo(i, y);
                        else ctx.lineTo(i, y);
                    }
                    ctx.stroke();
                }
            }

            Text {
                text: "0.0"; color: Theme.mutedForeground; font.pixelSize: 11; Layout.preferredWidth: 50
            }
        }
    }
}
