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
