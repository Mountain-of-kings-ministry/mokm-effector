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
    property bool animateFaders: false

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

    // Effect chain from selected track
    readonly property var _effectChain: {
        if (!selectedObject) return null;
        if (selectedObject.element !== undefined && selectedObject.track)
            return selectedObject.track.effectChain;
        if (selectedObject.strips !== undefined && selectedObject.tracks === undefined)
            return selectedObject.effectChain;
        if (selectedObject.tracks !== undefined)
            return selectedObject.tracks > 0 ? selectedObject.trackAt(0).effectChain : null;
        return null;
    }

    readonly property var _comp: timelineModel ? timelineModel.composition : null

    // ── Waveform data ──
    property var _waveformData: _target ? _target.waveformDataList : []

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

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── HEADER ──
        Rectangle {
            Layout.fillWidth: true
            height: 48
            color: Theme.secondaryHover
            border.color: Theme.border
            border.width: 0

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
                    font.pixelSize: 13
                    font.bold: true
                }

                Item { Layout.fillWidth: true }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 1; color: Theme.border
            }
        }

        // ── MAIN CONTENT ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // 1. Waveform Area
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#0a0a0a"

                Canvas {
                    id: waveform
                    anchors.fill: parent
                    anchors.margins: 10

                    onPaint: {
                        var ctx = getContext("2d");
                        if (!ctx) return;
                        ctx.clearRect(0, 0, width, height);

                        var w = width;
                        var h = height;
                        var center = h / 2;
                        var data = root._waveformData;
                        if (!data || data.length === 0) return;

                        var step = Math.max(1, Math.floor(data.length / w));

                        ctx.strokeStyle = "#4ade80";
                        ctx.lineWidth = 1.5;
                        ctx.beginPath();

                        for (var x = 0; x < w; x++) {
                            var idx = Math.floor(x * step);
                            if (idx >= data.length) break;
                            var sample = data[idx];
                            var y = center - sample * center * 0.9;
                            if (x === 0) ctx.moveTo(x, y);
                            else ctx.lineTo(x, y);
                        }
                        ctx.stroke();

                        ctx.strokeStyle = Qt.rgba(255,255,255,0.1);
                        ctx.lineWidth = 1;
                        ctx.beginPath();
                        ctx.moveTo(0, center);
                        ctx.lineTo(w, center);
                        ctx.stroke();
                    }

                    Connections {
                        target: root
                        function on_WaveformDataChanged() { waveform.requestPaint(); }
                    }
                }

                Rectangle {
                    x: 10 + (timelineModel?.currentFrame ?? 0) * pixelPerFrame
                    width: 2; height: parent.height; color: Theme.accent; z: 10
                    visible: x >= 10 && x <= parent.width - 10
                }
            }

            // 2. Faders + Plugin Rack (SplitView)
            SplitView {
                Layout.fillWidth: true
                Layout.preferredHeight: 280
                orientation: Qt.Horizontal

                handle: Rectangle {
                    implicitWidth: 2
                    color: SplitHandle.pressed ? Theme.accent : (SplitHandle.hovered ? Theme.input : Theme.border)
                }

                FaderSection {
                    SplitView.preferredWidth: 280
                    SplitView.minimumWidth: 200
                    timelineModel: root.timelineModel
                    target: _target
                    animateFaders: root.animateFaders
                    onShowAutomationChanged: {}
                    onAnimateFadersChanged: {
                        root.animateFaders = animateFaders;
                    }
                }

                PluginRack {
                    id: pluginRack
                    SplitView.fillWidth: true
                    SplitView.minimumWidth: 200
                    timelineModel: root.timelineModel
                    effectChain: root._effectChain
                }
            }
        }
    }

    Popup {
        id: selectPopup
        x: selectBtn.x; y: 48
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
