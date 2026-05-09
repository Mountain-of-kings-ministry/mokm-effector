import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root
    color: Theme.secondary
    clip: true

    property QtObject currentLayer: null
    property var timelineModel: null

    function updateProperty(propName, val) {
        if (!root.currentLayer) return;
        root.currentLayer[propName] = val;
        if (root.timelineModel && root.timelineModel.keyframeFrames(root.currentLayer, propName).length > 0) {
            root.timelineModel.addKeyframe(root.currentLayer, propName, root.timelineModel.currentFrame, val);
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
                    text: qsTr("No layer selected")
                    color: Theme.mutedForeground
                    font.pixelSize: 12
                    visible: !root.currentLayer
                }

                ColumnLayout {
                    visible: !!root.currentLayer
                    spacing: 6

                    EditablePropertyRow {
                        label: "Name"
                        value: root.currentLayer?.name ?? ""
                        onEditingFinished: function(v) { if (root.currentLayer) root.currentLayer.name = v }
                    }

                    EditablePropertyRow {
                        propName: "opacity"
                        label: "Opacity"
                        value: root.currentLayer ? (root.currentLayer.opacity * 100).toFixed(0) : "100"
                        suffix: "%"
                        onEditingFinished: function(v) {
                            var val = Math.max(0, Math.min(1, parseFloat(v) / 100 || 0));
                            root.updateProperty("opacity", val);
                        }
                    }

                    EditablePropertyRow {
                        propName: "x"
                        label: "Position X"
                        value: root.currentLayer?.x.toFixed(1) ?? "0"
                        onEditingFinished: function(v) { root.updateProperty("x", parseFloat(v) || 0) }
                    }

                    EditablePropertyRow {
                        propName: "y"
                        label: "Position Y"
                        value: root.currentLayer?.y.toFixed(1) ?? "0"
                        onEditingFinished: function(v) { root.updateProperty("y", parseFloat(v) || 0) }
                    }

                    EditablePropertyRow {
                        propName: "rotation"
                        label: "Rotation"
                        value: root.currentLayer?.rotation.toFixed(1) ?? "0"
                        suffix: "°"
                        onEditingFinished: function(v) { root.updateProperty("rotation", parseFloat(v) || 0) }
                    }

                    EditablePropertyRow {
                        propName: "scaleX"
                        label: "Scale X"
                        value: root.currentLayer?.scaleX.toFixed(2) ?? "1"
                        onEditingFinished: function(v) { root.updateProperty("scaleX", parseFloat(v) || 0) }
                    }

                    EditablePropertyRow {
                        propName: "scaleY"
                        label: "Scale Y"
                        value: root.currentLayer?.scaleY.toFixed(2) ?? "1"
                        onEditingFinished: function(v) { root.updateProperty("scaleY", parseFloat(v) || 0) }
                    }
                }
            }
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
            visible: rowRoot.propName !== ""
            color: {
                if (!root.timelineModel || !root.currentLayer || rowRoot.propName === "") return Theme.muted;
                var _ = root.timelineModel.keyframesStamp; // reactive dependency
                return root.timelineModel.hasKeyframe(root.currentLayer, rowRoot.propName, root.timelineModel.currentFrame) ? Theme.accent : Theme.muted;
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!root.timelineModel || !root.currentLayer || rowRoot.propName === "") return;
                    var pName = rowRoot.propName;
                    var frame = root.timelineModel.currentFrame;
                    if (root.timelineModel.hasKeyframe(root.currentLayer, pName, frame)) {
                        root.timelineModel.removeKeyframe(root.currentLayer, pName, frame);
                    } else {
                        var val = root.currentLayer[pName];
                        root.timelineModel.addKeyframe(root.currentLayer, pName, frame, val);
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
