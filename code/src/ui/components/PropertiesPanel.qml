import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root
    color: Theme.secondary
    clip: true

    property QtObject currentLayer: null

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
                        label: "Opacity"
                        value: root.currentLayer ? (root.currentLayer.opacity * 100).toFixed(0) : "100"
                        suffix: "%"
                        onEditingFinished: function(v) {
                            if (root.currentLayer) root.currentLayer.opacity = Math.max(0, Math.min(1, parseFloat(v) / 100 || 0))
                        }
                    }

                    EditablePropertyRow {
                        label: "Position X"
                        value: root.currentLayer?.x.toFixed(1) ?? "0"
                        onEditingFinished: function(v) { if (root.currentLayer) root.currentLayer.x = parseFloat(v) || 0 }
                    }

                    EditablePropertyRow {
                        label: "Position Y"
                        value: root.currentLayer?.y.toFixed(1) ?? "0"
                        onEditingFinished: function(v) { if (root.currentLayer) root.currentLayer.y = parseFloat(v) || 0 }
                    }

                    EditablePropertyRow {
                        label: "Rotation"
                        value: root.currentLayer?.rotation.toFixed(1) ?? "0"
                        suffix: "°"
                        onEditingFinished: function(v) { if (root.currentLayer) root.currentLayer.rotation = parseFloat(v) || 0 }
                    }

                    EditablePropertyRow {
                        label: "Scale X"
                        value: root.currentLayer?.scaleX.toFixed(2) ?? "1"
                        onEditingFinished: function(v) { if (root.currentLayer) root.currentLayer.scaleX = parseFloat(v) || 0 }
                    }

                    EditablePropertyRow {
                        label: "Scale Y"
                        value: root.currentLayer?.scaleY.toFixed(2) ?? "1"
                        onEditingFinished: function(v) { if (root.currentLayer) root.currentLayer.scaleY = parseFloat(v) || 0 }
                    }
                }
            }
        }
    }

    component EditablePropertyRow : RowLayout {
        property string label: ""
        property string value: ""
        property string suffix: ""
        signal editingFinished(string value)

        spacing: 4
        Layout.fillWidth: true

        Text {
            text: parent.label
            color: Theme.mutedForeground
            font.pixelSize: 11
            Layout.preferredWidth: 70
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
                    text: parent.parent.parent.value
                    color: Theme.foreground
                    font.pixelSize: 11
                    selectByMouse: true

                    onEditingFinished: parent.parent.parent.editingFinished(text)

                    onActiveFocusChanged: {
                        if (!activeFocus) parent.parent.parent.editingFinished(text)
                    }
                }

                Text {
                    text: parent.parent.parent.suffix
                    color: Theme.mutedForeground
                    font.pixelSize: 11
                    visible: parent.parent.parent.suffix.length > 0
                }
            }
        }
    }
}
