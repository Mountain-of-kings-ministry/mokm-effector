import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root
    color: Theme.secondary
    clip: true

    property var selectedObject: null
    property var timelineModel: null

    // ── Type detection helpers ──
    function _isLayer(obj) { return obj && (obj.deleteLayer !== undefined || obj.tracks !== undefined); }
    function _isTrack(obj) { return obj && (obj.deleteTrack !== undefined || (obj.strips !== undefined && obj.tracks === undefined)); }
    function _isStrip(obj) { return obj && (obj.deleteStrip !== undefined || obj.element !== undefined); }
    function _isNodeStrip(obj) { return obj && obj.nodeGraph !== undefined; }
    function _isRawElement(obj) { return obj && obj.opacity !== undefined && !_isLayer(obj) && !_isTrack(obj) && !_isStrip(obj); }

    function updateProperty(propName, val) {
        var obj = root.selectedObject;
        if (!obj) return;
        if (obj.element) {
            obj.element[propName] = val;
            if (root.timelineModel && root.timelineModel.autoKeyframeEnabled) {
                root.timelineModel.addKeyframe(obj.element, propName, root.timelineModel.currentFrame, val);
            }
        } else if (obj[propName] !== undefined) {
            obj[propName] = val;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            height: 32
            color: Theme.secondaryHover

            Text {
                Layout.alignment: Qt.AlignCenter
                text: qsTr("Properties")
                color: Theme.mutedForeground
                font.pixelSize: 11
                font.letterSpacing: 0.5
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            padding: 8

            ColumnLayout {
                width: parent.width - 16
                spacing: 8

                Text {
                    text: qsTr("Nothing selected")
                    color: Theme.mutedForeground
                    font.pixelSize: 12
                    visible: !root.selectedObject
                }

                // ==================== NODESTRIP PROPERTIES ====================
                ColumnLayout {
                    visible: root.selectedObject != null && _isNodeStrip(root.selectedObject)
                    spacing: 6

                    Text {
                        text: qsTr("NodeStrip Properties")
                        color: Theme.mutedForeground
                        font.pixelSize: 10
                        font.bold: true
                    }

                    EditablePropertyRow {
                        label: "Name"
                        value: root.selectedObject?.name ?? ""
                        onEditingFinished: function(v) { if (root.selectedObject) root.selectedObject.name = v }
                    }

                    EditablePropertyRow {
                        label: "Start Frame"
                        value: root.selectedObject?.startFrame != null ? String(root.selectedObject.startFrame) : "0"
                        onEditingFinished: function(v) { if (root.selectedObject) root.selectedObject.startFrame = parseInt(v) || 0 }
                    }

                    EditablePropertyRow {
                        label: "Duration"
                        value: root.selectedObject?.duration != null ? String(root.selectedObject.duration) : "90"
                        onEditingFinished: function(v) { if (root.selectedObject) root.selectedObject.duration = parseInt(v) || 1 }
                    }

                    Text {
                        text: qsTr("Node Graph: " + (root.selectedObject && root.selectedObject.nodeGraph ? root.selectedObject.nodeGraph.nodeCount + " nodes" : "empty"))
                        color: Theme.mutedForeground
                        font.pixelSize: 10
                    }

                    // ==================== SELECTED NODE PARAMETERS ====================
                    ColumnLayout {
                        id: nodeParamsSection
                        visible: root.selectedObject != null && root.selectedObject.nodeGraph != null
                                 && root.selectedObject.nodeGraph.selectedNodeId >= 0
                        spacing: 4

                        Text {
                            text: qsTr("Selected Node Parameters")
                            color: Theme.mutedForeground
                            font.pixelSize: 10
                            font.bold: true
                            visible: nodeParamsSection.visible
                        }

                        Repeater {
                            id: paramRepeater
                            model: nodeParamsSection.visible ? root.selectedObject.nodeGraph.nodeParameterNames(
                                root.selectedObject.nodeGraph.selectedNodeId) : []

                            EditablePropertyRow {
                                required property string modelData
                                label: modelData
                                value: {
                                    if (!root.selectedObject || !root.selectedObject.nodeGraph) return "";
                                    var val = root.selectedObject.nodeGraph.nodeParameter(
                                        root.selectedObject.nodeGraph.selectedNodeId, modelData);
                                    if (val === undefined || val === null) return "";
                                    if (typeof val === "number") return val.toFixed(typeof val === "number" && Number.isInteger(val) ? 0 : 2);
                                    return String(val);
                                }
                                onEditingFinished: function(v) {
                                    if (root.selectedObject && root.selectedObject.nodeGraph) {
                                        var nid = root.selectedObject.nodeGraph.selectedNodeId;
                                        var old = root.selectedObject.nodeGraph.nodeParameter(nid, modelData);
                                        var newVal = v;
                                        if (typeof old === "number") newVal = parseFloat(v) || 0;
                                        root.selectedObject.nodeGraph.setNodeParameter(nid, modelData, newVal);
                                    }
                                }
                            }
                        }
                    }

                    Button {
                        text: "Cook Node Graph"
                        Layout.fillWidth: true
                        onClicked: {
                            if (root.selectedObject && root.selectedObject.cook)
                                root.selectedObject.cook();
                        }
                    }

                    // Element properties (backward compat)
                    Text {
                        text: qsTr("Element Properties")
                        color: Theme.mutedForeground
                        font.pixelSize: 10
                        font.bold: true
                        visible: root.selectedObject != null && root.selectedObject.element != null
                    }

                    EditablePropertyRow {
                        propName: "opacity"
                        label: "Opacity"
                        value: root.selectedObject != null && root.selectedObject.element != null ? (root.selectedObject.element.opacity * 100).toFixed(0) : "100"
                        suffix: "%"
                        visible: root.selectedObject != null && root.selectedObject.element != null
                        onEditingFinished: function(v) {
                            var val = Math.max(0, Math.min(1, parseFloat(v) / 100 || 0));
                            root.updateProperty("opacity", val);
                        }
                    }

                    EditablePropertyRow {
                        propName: "x"
                        label: "Position X"
                        value: root.selectedObject != null && root.selectedObject.element != null ? root.selectedObject.element.x.toFixed(1) : "0"
                        visible: root.selectedObject != null && root.selectedObject.element != null
                        onEditingFinished: function(v) { root.updateProperty("x", parseFloat(v) || 0) }
                    }

                    EditablePropertyRow {
                        propName: "y"
                        label: "Position Y"
                        value: root.selectedObject != null && root.selectedObject.element != null ? root.selectedObject.element.y.toFixed(1) : "0"
                        visible: root.selectedObject != null && root.selectedObject.element != null
                        onEditingFinished: function(v) { root.updateProperty("y", parseFloat(v) || 0) }
                    }

                    EditablePropertyRow {
                        propName: "rotation"
                        label: "Rotation"
                        value: root.selectedObject != null && root.selectedObject.element != null ? root.selectedObject.element.rotation.toFixed(1) : "0"
                        suffix: "°"
                        visible: root.selectedObject != null && root.selectedObject.element != null
                        onEditingFinished: function(v) { root.updateProperty("rotation", parseFloat(v) || 0) }
                    }

                    EditablePropertyRow {
                        propName: "scaleX"
                        label: "Scale X"
                        value: root.selectedObject != null && root.selectedObject.element != null ? root.selectedObject.element.scaleX.toFixed(2) : "1"
                        visible: root.selectedObject != null && root.selectedObject.element != null
                        onEditingFinished: function(v) { root.updateProperty("scaleX", parseFloat(v) || 0) }
                    }

                    EditablePropertyRow {
                        propName: "scaleY"
                        label: "Scale Y"
                        value: root.selectedObject != null && root.selectedObject.element != null ? root.selectedObject.element.scaleY.toFixed(2) : "1"
                        visible: root.selectedObject != null && root.selectedObject.element != null
                        onEditingFinished: function(v) { root.updateProperty("scaleY", parseFloat(v) || 0) }
                    }
                }

                // ==================== TIMELINE LAYER PROPERTIES ====================
                ColumnLayout {
                    visible: root.selectedObject != null && _isLayer(root.selectedObject)
                    spacing: 6

                    Text {
                        text: qsTr("Layer Properties")
                        color: Theme.mutedForeground
                        font.pixelSize: 10
                        font.bold: true
                    }

                    EditablePropertyRow {
                        label: "Name"
                        value: root.selectedObject?.name ?? ""
                        onEditingFinished: function(v) { if (root.selectedObject) root.selectedObject.name = v }
                    }

                    BoolPropertyRow {
                        label: "Visible"
                        checked: root.selectedObject?.visible != null ? root.selectedObject.visible : true
                        onToggled: function(v) { if (root.selectedObject) root.selectedObject.visible = v }
                    }

                    BoolPropertyRow {
                        label: "Mute"
                        checked: root.selectedObject?.mute != null ? root.selectedObject.mute : false
                        onToggled: function(v) { if (root.selectedObject) root.selectedObject.mute = v }
                    }

                    BoolPropertyRow {
                        label: "Solo"
                        checked: root.selectedObject?.solo != null ? root.selectedObject.solo : false
                        onToggled: function(v) { if (root.selectedObject) root.selectedObject.solo = v }
                    }

                    SliderPropertyRow {
                        label: "Opacity"
                        value: root.selectedObject?.opacity != null ? root.selectedObject.opacity : 1.0
                        from: 0; to: 1; stepSize: 0.01
                        onChanged: function(v) { if (root.selectedObject) root.selectedObject.opacity = v }
                    }

                    EditablePropertyRow {
                        label: "Offset X"
                        value: root.selectedObject?.offsetX?.toFixed(1) ?? "0"
                        onEditingFinished: function(v) { if (root.selectedObject) root.selectedObject.offsetX = parseFloat(v) || 0 }
                    }

                    EditablePropertyRow {
                        label: "Offset Y"
                        value: root.selectedObject?.offsetY?.toFixed(1) ?? "0"
                        onEditingFinished: function(v) { if (root.selectedObject) root.selectedObject.offsetY = parseFloat(v) || 0 }
                    }

                    EditablePropertyRow {
                        label: "Rotation"
                        value: root.selectedObject?.rotation?.toFixed(1) ?? "0"
                        suffix: "°"
                        onEditingFinished: function(v) { if (root.selectedObject) root.selectedObject.rotation = parseFloat(v) || 0 }
                    }

                    EditablePropertyRow {
                        label: "Scale X"
                        value: root.selectedObject?.scaleX?.toFixed(2) ?? "1"
                        onEditingFinished: function(v) { if (root.selectedObject) root.selectedObject.scaleX = parseFloat(v) || 0 }
                    }

                    EditablePropertyRow {
                        label: "Scale Y"
                        value: root.selectedObject?.scaleY?.toFixed(2) ?? "1"
                        onEditingFinished: function(v) { if (root.selectedObject) root.selectedObject.scaleY = parseFloat(v) || 0 }
                    }

                    EditablePropertyRow {
                        label: "Anchor X"
                        value: root.selectedObject?.anchorX?.toFixed(1) ?? "0"
                        onEditingFinished: function(v) { if (root.selectedObject) root.selectedObject.anchorX = parseFloat(v) || 0 }
                    }

                    EditablePropertyRow {
                        label: "Anchor Y"
                        value: root.selectedObject?.anchorY?.toFixed(1) ?? "0"
                        onEditingFinished: function(v) { if (root.selectedObject) root.selectedObject.anchorY = parseFloat(v) || 0 }
                    }
                }

                // ==================== TRACK PROPERTIES ====================
                ColumnLayout {
                    visible: root.selectedObject != null && _isTrack(root.selectedObject)
                    spacing: 6

                    Text {
                        text: qsTr("Track Properties")
                        color: Theme.mutedForeground
                        font.pixelSize: 10
                        font.bold: true
                    }

                    EditablePropertyRow {
                        label: "Name"
                        value: root.selectedObject?.name ?? ""
                        onEditingFinished: function(v) { if (root.selectedObject) root.selectedObject.name = v }
                    }

                    BoolPropertyRow {
                        label: "Enabled"
                        checked: root.selectedObject?.enabled != null ? root.selectedObject.enabled : true
                        onToggled: function(v) { if (root.selectedObject) root.selectedObject.enabled = v }
                    }

                    BoolPropertyRow {
                        label: "Mute"
                        checked: root.selectedObject?.mute != null ? root.selectedObject.mute : false
                        onToggled: function(v) { if (root.selectedObject) root.selectedObject.mute = v }
                    }

                    BoolPropertyRow {
                        label: "Solo"
                        checked: root.selectedObject?.solo != null ? root.selectedObject.solo : false
                        onToggled: function(v) { if (root.selectedObject) root.selectedObject.solo = v }
                    }

                    SliderPropertyRow {
                        label: "Opacity"
                        value: root.selectedObject?.opacity != null ? root.selectedObject.opacity : 1.0
                        from: 0; to: 1; stepSize: 0.01
                        onChanged: function(v) { if (root.selectedObject) root.selectedObject.opacity = v }
                    }

                    SliderPropertyRow {
                        label: "Pan"
                        value: root.selectedObject?.pan != null ? root.selectedObject.pan : 0.0
                        from: -1; to: 1; stepSize: 0.01
                        onChanged: function(v) { if (root.selectedObject) root.selectedObject.pan = v }
                    }

                    BoolPropertyRow {
                        label: "Collapsed"
                        checked: root.selectedObject?.collapsed != null ? root.selectedObject.collapsed : false
                        onToggled: function(v) { if (root.selectedObject) root.selectedObject.collapsed = v }
                    }

                    BoolPropertyRow {
                        label: "Locked"
                        checked: root.selectedObject?.locked != null ? root.selectedObject.locked : false
                        onToggled: function(v) { if (root.selectedObject) root.selectedObject.locked = v }
                    }

                    EditablePropertyRow {
                        label: "Priority"
                        value: root.selectedObject?.priority != null ? String(root.selectedObject.priority) : "0"
                        onEditingFinished: function(v) { if (root.selectedObject) root.selectedObject.priority = parseInt(v) || 0 }
                    }

                    BoolPropertyRow {
                        label: "Looping"
                        checked: root.selectedObject?.looping != null ? root.selectedObject.looping : false
                        onToggled: function(v) { if (root.selectedObject) root.selectedObject.looping = v }
                    }

                    EditablePropertyRow {
                        label: "Loop Count"
                        value: root.selectedObject?.loopCount != null ? String(root.selectedObject.loopCount) : "1"
                        onEditingFinished: function(v) { if (root.selectedObject) root.selectedObject.loopCount = Math.max(1, parseInt(v) || 1) }
                    }
                }

                // ==================== STRIP PROPERTIES ====================
                ColumnLayout {
                    visible: root.selectedObject != null && _isStrip(root.selectedObject)
                    spacing: 6

                    Text {
                        text: qsTr("Strip Properties")
                        color: Theme.mutedForeground
                        font.pixelSize: 10
                        font.bold: true
                    }

                    EditablePropertyRow {
                        label: "Name"
                        value: root.selectedObject?.name ?? ""
                        onEditingFinished: function(v) { if (root.selectedObject) root.selectedObject.name = v }
                    }

                    EditablePropertyRow {
                        label: "Start Frame"
                        value: root.selectedObject?.startFrame != null ? String(root.selectedObject.startFrame) : "0"
                        onEditingFinished: function(v) { if (root.selectedObject) root.selectedObject.startFrame = parseInt(v) || 0 }
                    }

                    EditablePropertyRow {
                        label: "Duration"
                        value: root.selectedObject?.duration != null ? String(root.selectedObject.duration) : "90"
                        onEditingFinished: function(v) { if (root.selectedObject) root.selectedObject.duration = parseInt(v) || 1 }
                    }

                    // Element (visual) properties
                    Text {
                        text: qsTr("Element Properties")
                        color: Theme.mutedForeground
                        font.pixelSize: 10
                        font.bold: true
                        visible: root.selectedObject != null && root.selectedObject.element != null
                    }

                    EditablePropertyRow {
                        propName: "opacity"
                        label: "Opacity"
                        value: root.selectedObject != null && root.selectedObject.element != null ? (root.selectedObject.element.opacity * 100).toFixed(0) : "100"
                        suffix: "%"
                        visible: root.selectedObject != null && root.selectedObject.element != null
                        onEditingFinished: function(v) {
                            var val = Math.max(0, Math.min(1, parseFloat(v) / 100 || 0));
                            root.updateProperty("opacity", val);
                        }
                    }

                    EditablePropertyRow {
                        propName: "x"
                        label: "Position X"
                        value: root.selectedObject != null && root.selectedObject.element != null ? root.selectedObject.element.x.toFixed(1) : "0"
                        visible: root.selectedObject != null && root.selectedObject.element != null
                        onEditingFinished: function(v) { root.updateProperty("x", parseFloat(v) || 0) }
                    }

                    EditablePropertyRow {
                        propName: "y"
                        label: "Position Y"
                        value: root.selectedObject != null && root.selectedObject.element != null ? root.selectedObject.element.y.toFixed(1) : "0"
                        visible: root.selectedObject != null && root.selectedObject.element != null
                        onEditingFinished: function(v) { root.updateProperty("y", parseFloat(v) || 0) }
                    }

                    EditablePropertyRow {
                        propName: "rotation"
                        label: "Rotation"
                        value: root.selectedObject != null && root.selectedObject.element != null ? root.selectedObject.element.rotation.toFixed(1) : "0"
                        suffix: "°"
                        visible: root.selectedObject != null && root.selectedObject.element != null
                        onEditingFinished: function(v) { root.updateProperty("rotation", parseFloat(v) || 0) }
                    }

                    EditablePropertyRow {
                        propName: "scaleX"
                        label: "Scale X"
                        value: root.selectedObject != null && root.selectedObject.element != null ? root.selectedObject.element.scaleX.toFixed(2) : "1"
                        visible: root.selectedObject != null && root.selectedObject.element != null
                        onEditingFinished: function(v) { root.updateProperty("scaleX", parseFloat(v) || 0) }
                    }

                    EditablePropertyRow {
                        propName: "scaleY"
                        label: "Scale Y"
                        value: root.selectedObject != null && root.selectedObject.element != null ? root.selectedObject.element.scaleY.toFixed(2) : "1"
                        visible: root.selectedObject != null && root.selectedObject.element != null
                        onEditingFinished: function(v) { root.updateProperty("scaleY", parseFloat(v) || 0) }
                    }
                }

                // ==================== LEGACY: RAW VISUAL ELEMENT PROPERTIES ====================
                ColumnLayout {
                    visible: root.selectedObject != null && _isRawElement(root.selectedObject)
                    spacing: 6

                    Text {
                        text: qsTr("Element Properties")
                        color: Theme.mutedForeground
                        font.pixelSize: 10
                        font.bold: true
                    }

                    EditablePropertyRow {
                        label: "Name"
                        value: root.selectedObject?.name ?? ""
                        onEditingFinished: function(v) { if (root.selectedObject) root.selectedObject.name = v }
                    }

                    EditablePropertyRow {
                        propName: "opacity"
                        label: "Opacity"
                        value: root.selectedObject ? (root.selectedObject.opacity * 100).toFixed(0) : "100"
                        suffix: "%"
                        onEditingFinished: function(v) {
                            var val = Math.max(0, Math.min(1, parseFloat(v) / 100 || 0));
                            root.updateProperty("opacity", val);
                        }
                    }

                    EditablePropertyRow {
                        propName: "x"
                        label: "Position X"
                        value: root.selectedObject?.x?.toFixed(1) ?? "0"
                        onEditingFinished: function(v) { root.updateProperty("x", parseFloat(v) || 0) }
                    }

                    EditablePropertyRow {
                        propName: "y"
                        label: "Position Y"
                        value: root.selectedObject?.y?.toFixed(1) ?? "0"
                        onEditingFinished: function(v) { root.updateProperty("y", parseFloat(v) || 0) }
                    }

                    EditablePropertyRow {
                        propName: "rotation"
                        label: "Rotation"
                        value: root.selectedObject?.rotation?.toFixed(1) ?? "0"
                        suffix: "°"
                        onEditingFinished: function(v) { root.updateProperty("rotation", parseFloat(v) || 0) }
                    }

                    EditablePropertyRow {
                        propName: "scaleX"
                        label: "Scale X"
                        value: root.selectedObject?.scaleX?.toFixed(2) ?? "1"
                        onEditingFinished: function(v) { root.updateProperty("scaleX", parseFloat(v) || 0) }
                    }

                    EditablePropertyRow {
                        propName: "scaleY"
                        label: "Scale Y"
                        value: root.selectedObject?.scaleY?.toFixed(2) ?? "1"
                        onEditingFinished: function(v) { root.updateProperty("scaleY", parseFloat(v) || 0) }
                    }
                }
            }
        }
    }

    component BoolPropertyRow : RowLayout {
        id: boolRow
        property string label: ""
        property bool checked: false
        signal toggled(bool value)

        spacing: 4
        Layout.fillWidth: true

        Text {
            text: boolRow.label
            color: Theme.mutedForeground
            font.pixelSize: 11
            Layout.preferredWidth: 70
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            width: 36
            height: 18
            radius: 9
            color: boolRow.checked ? Theme.accent : Theme.muted
            Behavior on color { ColorAnimation { duration: 100 } }

            Rectangle {
                x: boolRow.checked ? parent.width - width - 2 : 2
                y: 2
                width: 14
                height: 14
                radius: 7
                color: "#ffffff"
                Behavior on x { NumberAnimation { duration: 100 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    boolRow.checked = !boolRow.checked;
                    boolRow.toggled(boolRow.checked);
                }
            }
        }
    }

    component SliderPropertyRow : RowLayout {
        id: sliderRow
        property string label: ""
        property real value: 0
        property real from: 0
        property real to: 1
        property real stepSize: 0.01
        signal changed(real value)

        spacing: 4
        Layout.fillWidth: true

        Text {
            text: sliderRow.label
            color: Theme.mutedForeground
            font.pixelSize: 11
            Layout.preferredWidth: 70
        }

        Slider {
            Layout.fillWidth: true
            from: sliderRow.from
            to: sliderRow.to
            stepSize: sliderRow.stepSize
            value: sliderRow.value
            onMoved: sliderRow.changed(value)
            onPressedChanged: if (!pressed && value !== sliderRow.value) sliderRow.changed(value)
        }

        Text {
            text: sliderRow.value.toFixed(2)
            color: Theme.foreground
            font.pixelSize: 11
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
        }
    }

    component EditablePropertyRow : RowLayout {
        id: rowRoot
        property string propName: ""
        property string label: ""
        property string value: ""
        property string suffix: ""
        signal editingFinished(string value)

        spacing: 4
        Layout.fillWidth: true

        // ── Keyframe Button ──
        Rectangle {
            width: 8
            height: 8
            radius: 1
            rotation: 45
            visible: rowRoot.propName !== "" && root.selectedObject != null && root.selectedObject.element != null
            color: {
                if (!root.timelineModel || !root.selectedObject || !root.selectedObject.element || rowRoot.propName === "") return Theme.muted;
                var _ = root.timelineModel.keyframesStamp;
                return root.timelineModel.hasKeyframe(root.selectedObject.element, rowRoot.propName, root.timelineModel.currentFrame) ? Theme.accent : Theme.muted;
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!root.timelineModel || !root.selectedObject || !root.selectedObject.element || rowRoot.propName === "") return;
                    var pName = rowRoot.propName;
                    var frame = root.timelineModel.currentFrame;
                    if (root.timelineModel.hasKeyframe(root.selectedObject.element, pName, frame)) {
                        root.timelineModel.removeKeyframe(root.selectedObject.element, pName, frame);
                    } else {
                        var val = root.selectedObject.element[pName];
                        root.timelineModel.addKeyframe(root.selectedObject.element, pName, frame, val);
                    }
                }
            }
        }

        Text {
            text: rowRoot.label
            color: Theme.mutedForeground
            font.pixelSize: 11
            Layout.preferredWidth: rowRoot.propName !== "" ? 58 : 70
        }

        Rectangle {
            Layout.fillWidth: true
            height: 22
            color: Theme.input
            radius: 3
            border.color: field.activeFocus ? Theme.accent : Theme.border

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 2

                TextInput {
                    id: field
                    Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                    text: rowRoot.value
                    color: Theme.foreground
                    font.pixelSize: 11
                    selectByMouse: true

                    onEditingFinished: rowRoot.editingFinished(text)

                    onActiveFocusChanged: {
                        if (!activeFocus) rowRoot.editingFinished(text)
                    }
                }

                Text {
                    text: rowRoot.suffix
                    color: Theme.mutedForeground
                    font.pixelSize: 11
                    visible: rowRoot.suffix.length > 0
                }
            }
        }
    }
}
