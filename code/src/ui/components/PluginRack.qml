import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root
    color: Theme.secondary

    property var timelineModel: null
    property var effectChain: null   // EffectChain C++ object
    property bool autoKeyframe: timelineModel ? timelineModel.autoKeyframeEnabled : false

    signal effectAdded(string name, string pluginId, string format)
    signal effectRemoved(int index)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Plugin Rack"
                color: Theme.foreground
                font.pixelSize: 12
                font.bold: true
            }

            Text {
                text: effectChain ? "(" + effectChain.count + ")" : "(0)"
                color: Theme.mutedForeground
                font.pixelSize: 11
            }

            Item { Layout.fillWidth: true }

            Button {
                id: addBtn
                text: "+ Add"
                flat: true
                contentItem: Text {
                    text: parent.text
                    color: Theme.accent
                    font.pixelSize: 11
                }
                background: Rectangle {
                    color: "transparent"
                }
                onClicked: pluginPopup.open()
            }
        }

        // Effect list
        ListView {
            id: effectList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4

            model: effectChain ? effectChain.count : 0

            delegate: Rectangle {
                id: effectDelegate
                width: ListView.view.width
                height: expanded ? paramHeight + 36 : 36

                property bool expanded: false
                property real paramHeight: 80

                color: Theme.background
                radius: 4
                border.color: Theme.border

                DragHandler {
                    id: dragHandler
                    target: null
                    onActiveChanged: {
                        if (active) {
                            effectList.interactive = false;
                            effectDelegate.opacity = 0.5;
                        } else {
                            effectList.interactive = true;
                            effectDelegate.opacity = 1.0;
                        }
                    }
                }

                DropArea {
                    anchors.fill: parent
                    onDropped: {
                        if (effectChain && drag.sourceIndex !== index) {
                            effectChain.moveEffect(drag.sourceIndex, index);
                        }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4

                    // Header row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // Drag handle
                        Text {
                            text: "\u2630"
                            color: Theme.mutedForeground
                            font.pixelSize: 12
                            DragHandler {
                                id: effectDrag
                                target: null
                                property int sourceIndex: index
                                onActiveChanged: {
                                    if (active) {
                                        effectList.interactive = false;
                                        effectDelegate.opacity = 0.5;
                                    } else {
                                        effectList.interactive = true;
                                        effectDelegate.opacity = 1.0;
                                    }
                                }
                            }
                        }

                        // Name
                        Text {
                            text: {
                                var ef = effectChain ? effectChain.effectAt(index) : null;
                                return ef ? ef.name : "?";
                            }
                            color: Theme.foreground
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // Format badge
                        Rectangle {
                            width: 36; height: 16; radius: 3
                            color: {
                                var ef = effectChain ? effectChain.effectAt(index) : null;
                                if (!ef) return "transparent";
                                return ef.format === "CLAP" ? Qt.rgba(Qt.color("#22c55e").r, Qt.color("#22c55e").g, Qt.color("#22c55e").b, 0.2) : Qt.rgba(Qt.color("#3b82f6").r, Qt.color("#3b82f6").g, Qt.color("#3b82f6").b, 0.2);
                            }
                            Text {
                                anchors.centerIn: parent
                                text: {
                                    var ef = effectChain ? effectChain.effectAt(index) : null;
                                    return ef ? ef.format : "";
                                }
                                color: {
                                    var ef = effectChain ? effectChain.effectAt(index) : null;
                                    if (!ef) return "transparent";
                                    return ef.format === "CLAP" ? "#22c55e" : "#3b82f6";
                                }
                                font.pixelSize: 8; font.bold: true
                            }
                        }

                        // Bypass toggle
                        Rectangle {
                            width: 20; height: 20; radius: 4
                            color: {
                                var ef = effectChain ? effectChain.effectAt(index) : null;
                                return ef && !ef.bypassed ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : "transparent";
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "\u25C9"
                                color: {
                                    var ef = effectChain ? effectChain.effectAt(index) : null;
                                    return ef && !ef.bypassed ? Theme.accent : Theme.mutedForeground;
                                }
                                font.pixelSize: 10
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var ef = effectChain ? effectChain.effectAt(index) : null;
                                    if (ef) ef.bypassed = !ef.bypassed;
                                }
                                ToolTip {
                                    text: "Bypass"
                                    delay: 800; visible: parent.containsMouse
                                }
                            }
                        }

                        // Expand
                        Rectangle {
                            width: 20; height: 20; radius: 4
                            color: effectDelegate.expanded ? Qt.rgba(Theme.mutedForeground.r, Theme.mutedForeground.g, Theme.mutedForeground.b, 0.1) : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: effectDelegate.expanded ? "\u25BC" : "\u25B6"
                                color: Theme.mutedForeground
                                font.pixelSize: 8
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: effectDelegate.expanded = !effectDelegate.expanded
                            }
                        }

                        // Remove
                        Rectangle {
                            width: 20; height: 20; radius: 4
                            color: maRemove.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.2) : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "\u00D7"
                                color: Theme.mutedForeground
                                font.pixelSize: 12
                            }
                            MouseArea {
                                id: maRemove
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (effectChain) {
                                        effectChain.removeEffect(index);
                                        root.effectRemoved(index);
                                    }
                                }
                                ToolTip {
                                    text: "Remove"
                                    delay: 800; visible: parent.containsMouse
                                }
                            }
                        }
                    }

                    // Expanded parameters
                    Rectangle {
                        visible: effectDelegate.expanded
                        Layout.fillWidth: true
                        Layout.preferredHeight: paramHeight
                        color: Theme.input
                        radius: 3
                        clip: true

                        ListView {
                            anchors.fill: parent
                            anchors.margins: 4
                            model: {
                                var ef = effectChain ? effectChain.effectAt(index) : null;
                                if (!ef) return 0;
                                var params = ef.parameters;
                                if (!params) return 0;
                                // QVariantMap keys as array
                                var keys = [];
                                for (var key in params) keys.push(key);
                                return keys.length;
                            }

                            delegate: RowLayout {
                                width: ListView.view.width
                                height: 22
                                spacing: 6

                                Text {
                                    text: {
                                        var ef = effectChain ? effectChain.effectAt(index) : null;
                                        if (!ef) return "";
                                        var keys = Object.keys(ef.parameters);
                                        return keys[modelData] || ("param_" + modelData);
                                    }
                                    color: Theme.mutedForeground
                                    font.pixelSize: 9
                                    Layout.preferredWidth: 80
                                    elide: Text.ElideRight
                                }

                                Slider {
                                    id: paramSlider
                                    Layout.fillWidth: true
                                    from: 0; to: 1
                                    value: {
                                        var ef = effectChain ? effectChain.effectAt(index) : null;
                                        if (!ef) return 0;
                                        var keys = Object.keys(ef.parameters);
                                        return ef.getParameter(keys[modelData]);
                                    }
                                    onMoved: {
                                        var ef = effectChain ? effectChain.effectAt(index) : null;
                                        if (!ef) return;
                                        var keys = Object.keys(ef.parameters);
                                        var key = keys[modelData];
                                        ef.setParameter(key, value);

                                        // Auto-keyframe
                                        if (root.timelineModel && root.timelineModel.autoKeyframeEnabled)
                                            root.timelineModel.tryAutoKeyframe(ef, key, value);
                                    }

                                    background: Rectangle {
                                        x: paramSlider.leftPadding + paramSlider.availableWidth / 2 - width / 2
                                        y: paramSlider.topPadding + paramSlider.availableHeight / 2 - height / 2
                                        implicitWidth: 100; implicitHeight: 4
                                        width: paramSlider.availableWidth; height: implicitHeight
                                        radius: 2; color: Theme.border

                                        Rectangle {
                                            width: paramSlider.visualPosition * parent.width
                                            height: parent.height
                                            color: Theme.accent; radius: 2
                                        }
                                    }
                                }

                                Text {
                                    text: paramSlider.value.toFixed(2)
                                    color: Theme.foreground
                                    font.pixelSize: 9
                                    font.family: "Monospace"
                                    Layout.preferredWidth: 30
                                }
                            }
                        }
                    }
                }

                // Separator line for drag preview
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 2
                    color: Theme.border
                }
            }

            // Empty state
            Rectangle {
                visible: !effectChain || effectChain.count === 0
                width: parent.width
                height: 60
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "No effects. Click + Add to add plugins."
                    color: Theme.mutedForeground
                    font.pixelSize: 11
                }
            }
        }
    }

    PluginManagerPopup {
        id: pluginPopup
        anchors.centerIn: Overlay.overlay
        timelineModel: root.timelineModel

        onPluginsSelected: function(plugins) {
            if (!root.effectChain || typeof _audioPluginManager === "undefined") return;
            for (var i = 0; i < plugins.length; i++) {
                var p = plugins[i];
                var effect = _audioPluginManager.createInstanceById(p.pluginId, p.format, root.effectChain);
                if (effect) {
                    root.effectChain.addEffect(effect);
                    root.effectAdded(p.name, p.pluginId, p.format);
                }
            }
        }
    }
}
