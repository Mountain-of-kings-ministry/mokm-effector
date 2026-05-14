import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Popup {
    id: root
    width: 480
    height: 520
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property var timelineModel: null
    signal pluginSelected(string name, string pluginId, string format)
    signal pluginsSelected(var plugins) // list of {name, pluginId, format}

    onAboutToShow: {
        searchField.text = "";
        rebuildFilter();
        gatherPlugins();
    }

    property var _clapPlugins: []
    property var _vst3Plugins: []
    property var _selectedPlugins: ({})
    property var selectedPluginIds: ({})

    function gatherPlugins() {
        _clapPlugins = [];
        _vst3Plugins = [];

        if (typeof _audioPluginManager !== "undefined" && _audioPluginManager) {
            var apm = _audioPluginManager;
            for (var i = 0; i < apm.availablePlugins.length; i++) {
                var p = apm.availablePlugins[i];
                var entry = {
                    name: p.name,
                    pluginId: p.pluginId,
                    format: p.format,
                    vendor: p.vendor
                };
                if (p.format === "CLAP")
                    _clapPlugins.push(entry);
                else if (p.format === "VST3")
                    _vst3Plugins.push(entry);
            }
        }

        rebuildFilter();
    }

    property string _currentTab: "CLAP"

    Rectangle {
        anchors.fill: parent
        color: Theme.background
        border.color: Theme.border

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            // Title + search
            Text {
                text: "Plugin Manager"
                color: Theme.foreground
                font.pixelSize: 14
                font.bold: true
            }

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: qsTr("Search plugins\u2026")
                color: Theme.foreground
                placeholderTextColor: Theme.mutedForeground
                background: Rectangle {
                    color: Theme.input
                    radius: 4
                    border.color: Theme.border
                }
                onTextChanged: rebuildFilter()
            }

            // Tab bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: ["CLAP", "VST3"]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        color: _currentTab === modelData ? Theme.accent : Theme.secondary
                        radius: 4

                        Text {
                            anchors.centerIn: parent
                            text: modelData + (modelData === "CLAP" ? " (" + _clapPlugins.length + ")" : " (" + _vst3Plugins.length + ")")
                            color: _currentTab === modelData ? "#fff" : Theme.foreground
                            font.pixelSize: 11
                            font.bold: _currentTab === modelData
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _currentTab = modelData;
                                rebuildFilter();
                            }
                        }
                    }
                }
            }

            // Plugin list
            ListView {
                id: pluginList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: ListModel { id: filterModel }

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 32
                    color: (selectedPluginIds[model.pluginId] || model._selected)
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                        : (ma.containsMouse ? Theme.secondaryHover : "transparent")

                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: 8
                        anchors.right: parent.right; anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: model._selected ? "\u25C9" : "\u25CB"
                            color: Theme.accent
                            font.pixelSize: 14
                        }

                        Text {
                            text: model.name
                            color: Theme.foreground
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 40
                            height: 18
                            radius: 3
                            color: model.format === "CLAP" ? Qt.rgba(Qt.color("#22c55e").r, Qt.color("#22c55e").g, Qt.color("#22c55e").b, 0.2) : Qt.rgba(Qt.color("#3b82f6").r, Qt.color("#3b82f6").g, Qt.color("#3b82f6").b, 0.2)
                            Text {
                                anchors.centerIn: parent
                                text: model.format
                                color: model.format === "CLAP" ? "#22c55e" : "#3b82f6"
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            var id = model.pluginId;
                            var temp = selectedPluginIds;
                            if (temp[id]) {
                                delete temp[id];
                            } else {
                                temp[id] = {
                                    name: model.name,
                                    pluginId: model.pluginId,
                                    format: model.format
                                };
                            }
                            selectedPluginIds = ({}); // Clear to break binding
                            selectedPluginIds = temp; // Re-assign to trigger
                            filterModel.setProperty(index, "_selected", !!selectedPluginIds[id]);
                        }
                    }
                }
            }

            function getSelectedList() {
                var list = [];
                for (var id in selectedPluginIds)
                    list.push(selectedPluginIds[id]);
                return list;
            }

            // Bottom buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    text: "Clear"
                    flat: true
                    onClicked: {
                        selectedPluginIds = ({});
                        for (var i = 0; i < filterModel.count; i++)
                            filterModel.setProperty(i, "_selected", false);
                    }
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "Cancel"
                    flat: true
                    onClicked: root.close()
                }

                Button {
                    text: "Add Selected (" + Object.keys(selectedPluginIds).length + ")"
                    enabled: Object.keys(selectedPluginIds).length > 0
                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? "#fff" : Theme.mutedForeground
                        font.pixelSize: 12
                    }
                    background: Rectangle {
                        color: parent.enabled ? Theme.accent : Theme.secondary
                        radius: 4
                    }
                    onClicked: {
                        root.pluginsSelected(getSelectedList());
                        root.close();
                    }
                }
            }
        }
    }

    function rebuildFilter() {
        filterModel.clear();
        var source = _currentTab === "CLAP" ? _clapPlugins : _vst3Plugins;
        var q = searchField.text.toLowerCase();

        for (var i = 0; i < source.length; i++) {
            var p = source[i];
            if (!q || p.name.toLowerCase().indexOf(q) >= 0) {
                filterModel.append({
                    name: p.name,
                    pluginId: p.pluginId,
                    format: p.format,
                    _selected: !!selectedPluginIds[p.pluginId]
                });
            }
        }
    }
}
