import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import mokm_effector

Rectangle {
    id: root
    color: Theme.background
    clip: true

    property var timelineModel: null
    property var selectedObject: null

    // ── Target resolution ──
    readonly property var _target: {
        if (!selectedObject) return null;
        if (selectedObject.element !== undefined)
            return selectedObject.element; // Strip → its element (Layer)
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

    // Split view state
    property bool showSplitView: true

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── HEADER ──
        Rectangle {
            Layout.fillWidth: true
            height: 56
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
                    text: _target ? (_target.name || "?") + " \u2022 Color" : "Color Grading Editor"
                    color: Theme.foreground
                    font.pixelSize: 14
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Switch {
                    text: "Split View"; checked: root.showSplitView
                    onCheckedChanged: root.showSplitView = checked
                }

                Button { text: "Reset All"; onClicked: console.log("Color grading reset") }
                Button { text: "Save Preset"; onClicked: console.log("Preset saved") }

                ComboBox { model: ["No LUT", "Film Stock", "Cinematic Teal", "Vintage", "Custom"] }
            }
        }

        // ── Main content ──
        RowLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 0

            // Preview area
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true; color: "#111111"

                RowLayout {
                    anchors.fill: parent; spacing: 0

                    Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: "#1a1a1a"; visible: root.showSplitView
                        Text { anchors.centerIn: parent; text: "ORIGINAL"; color: "#888"; font.pixelSize: 11 } }
                    Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: "#1a1a1a"
                        Text { anchors.centerIn: parent; text: "GRADED"; color: Theme.accent; font.pixelSize: 11 } }
                }

                // Scopes
                Row {
                    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 90; spacing: 1
                    Rectangle { width: parent.width / 2; height: parent.height; color: Qt.alpha(Theme.secondary, 0.9)
                        Text { anchors.centerIn: parent; text: "Histogram\n[Placeholder]"; color: Theme.mutedForeground; horizontalAlignment: Text.AlignHCenter } }
                    Rectangle { width: parent.width / 2; height: parent.height; color: Qt.alpha(Theme.secondary, 0.9)
                        Text { anchors.centerIn: parent; text: "Waveform\n[Placeholder]"; color: Theme.mutedForeground; horizontalAlignment: Text.AlignHCenter } }
                }
            }

            // Controls panel
            Rectangle {
                Layout.preferredWidth: 340; Layout.fillHeight: true
                color: Theme.secondary; border.color: Theme.border

                ScrollView {
                    anchors.fill: parent; clip: true; padding: 12

                    ColumnLayout {
                        width: parent.width; spacing: 20

                        // Basic Correction
                        GroupBox {
                            title: "Basic Correction"; Layout.fillWidth: true
                            GridLayout {
                                columns: 2; columnSpacing: 12; rowSpacing: 12; width: parent.width

                                Text { text: "Exposure"; color: Theme.mutedForeground }
                                Slider { Layout.fillWidth: true; from: -3; to: 3; value: _target ? _target.contrast || 0 : 0
                                    onValueChanged: { if (_target) _target.contrast = value } }

                                Text { text: "Contrast"; color: Theme.mutedForeground }
                                Slider { Layout.fillWidth: true; from: -1; to: 1; value: _target ? _target.contrast || 0 : 0
                                    onValueChanged: { if (_target) _target.contrast = value } }

                                Text { text: "Saturation"; color: Theme.mutedForeground }
                                Slider { Layout.fillWidth: true; from: 0; to: 4; value: _target ? _target.saturation || 1 : 1; stepSize: 0.01
                                    onValueChanged: { if (_target) _target.saturation = value } }

                                Text { text: "Temperature"; color: Theme.mutedForeground }
                                Slider { Layout.fillWidth: true; from: -1; to: 1; value: 0 }
                            }
                        }

                        // Color Wheels
                        GroupBox {
                            title: "Color Wheels"; Layout.fillWidth: true
                            RowLayout {
                                spacing: 10
                                Repeater {
                                    model: ["Shadows", "Midtones", "Highlights"]
                                    delegate: ColumnLayout {
                                        spacing: 6
                                        Text { text: modelData; color: Theme.foreground; font.pixelSize: 12; Layout.alignment: Qt.AlignHCenter }

                                        Rectangle {
                                            width: 78; height: 78; radius: 39; color: Theme.input
                                            border.color: Theme.border

                                            Text { anchors.centerIn: parent; text: "Wheel"; color: Theme.mutedForeground; font.pixelSize: 9 }
                                            MouseArea { anchors.fill: parent; onClicked: colorDialog.open() }
                                        }
                                    }
                                }
                            }
                        }

                        // Lift / Gamma / Gain
                        GroupBox {
                            title: "Lift / Gamma / Gain"; Layout.fillWidth: true
                            ColumnLayout { width: parent.width; spacing: 12
                                Repeater {
                                    model: [
                                        {name: "Lift", prop: "lift", from: -1, to: 1, step: 0.01, def: 0},
                                        {name: "Gamma", prop: "gamma", from: 0.1, to: 3, step: 0.01, def: 1},
                                        {name: "Gain", prop: "gain", from: 0, to: 3, step: 0.01, def: 1}
                                    ]
                                    delegate: RowLayout {
                                        Text { text: modelData.name; color: Theme.mutedForeground; Layout.preferredWidth: 60 }
                                        Slider {
                                            Layout.fillWidth: true
                                            from: modelData.from; to: modelData.to; stepSize: modelData.step
                                            value: _target ? (_target[modelData.prop] !== undefined ? _target[modelData.prop] : modelData.def) : modelData.def
                                            onValueChanged: { if (_target) _target[modelData.prop] = value }
                                        }
                                        Button {
                                            text: "\u25C6"; flat: true
                                            onClicked: console.log("Keyframe for", modelData.name)
                                        }
                                    }
                                }
                            }
                        }

                        // Curves placeholder
                        GroupBox { title: "Curves"; Layout.fillWidth: true; Layout.preferredHeight: 120
                            Rectangle { anchors.fill: parent; color: Theme.secondaryHover; radius: 6
                                Text { anchors.centerIn: parent; text: "RGB / Luma Curves\n(Coming Soon)"; color: Theme.mutedForeground; horizontalAlignment: Text.AlignHCenter } }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }

    // ── Select Popup ──
    Popup {
        id: selectPopup
        x: selectBtn.x; y: 56
        width: 300; height: 400
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property var items: []
        onAboutToShow: { searchField.text = ""; items = _buildSearchableItems(); rebuildFilter(); }

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
            anchors.fill: parent; color: Theme.background; border.color: Theme.border
            ColumnLayout { anchors.fill: parent; anchors.margins: 4; spacing: 4
                TextField { id: searchField; Layout.fillWidth: true; placeholderText: "Search\u2026"
                    onTextChanged: selectPopup.rebuildFilter() }

                ListView { Layout.fillWidth: true; Layout.fillHeight: true; clip: true; model: filterModel
                    delegate: Rectangle { width: ListView.view.width; height: 28; color: ma.containsMouse ? Theme.muted : "transparent"
                        RowLayout {
                            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 4 + model.depth * 16; spacing: 6
                            Text { text: model.depth === 0 ? "\uD83D\uDCC1" : model.depth === 1 ? "\uD83D\uDCCB" : "\uD83C\uDF9E"; font.pixelSize: 10 }
                            Text { text: model.name; color: Theme.foreground; font.pixelSize: 11; elide: Text.ElideRight }
                            Text { text: "(" + model.typeName + ")"; color: Theme.mutedForeground; font.pixelSize: 9 }
                        }
                        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true
                            onClicked: { selectedObject = model.object; selectPopup.close(); } }
                    }
                }
            }
        }
    }

    ColorDialog { id: colorDialog; title: "Pick a color"; onAccepted: console.log("Color:", colorDialog.color) }
}
