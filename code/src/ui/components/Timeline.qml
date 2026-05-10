import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root
    color: Theme.secondary
    clip: true

    property var timelineModel: null
    property var selectedObject: null
    signal objectSelected(var obj)
    signal elementSelected(var elementLayer)

    property real pixelPerFrame: 8
    property int layerNameWidth: 140
    property int rowHeight: 34

    readonly property var stripColors: ["#3b82f6", "#8b5cf6", "#ec4899", "#ef4444", "#f59e0b", "#22c55e", "#14b8a6", "#06b6d4", "#6366f1", "#d946ef"]

    // ── Selection state ──
    property var _selectedLayers: []
    property var _clipboard: []

    function snapFrame(v) {
        return Math.round(v);
    }

    // ── RENAME DIALOG ──
    Dialog {
        id: renameDialog
        title: "Rename"
        standardButtons: Dialog.Ok | Dialog.Cancel

        property var targetObject: null

        onAccepted: {
            if (targetObject && nameField.text.trim() !== "")
                targetObject.name = nameField.text.trim();
        }

        ColumnLayout {
            anchors.fill: parent
            TextField {
                id: nameField
                Layout.fillWidth: true
                placeholderText: "Enter new name"
                selectByMouse: true
            }
        }
    }

    function renameItem(obj, defaultName) {
        renameDialog.targetObject = obj;
        nameField.text = obj ? (obj.name || defaultName || "Item") : (defaultName || "Item");
        renameDialog.open();
    }

    // ── Selection helpers ──
    function select(obj) {
        root.selectedObject = obj;
        _selectedLayers = obj ? [obj] : [];
        root.objectSelected(obj);
        if (obj && obj.element)
            root.elementSelected(obj.element);
    }

    function _isLayer(obj) {
        return obj && (obj.deleteLayer !== undefined || obj.tracks !== undefined);
    }
    function _isTrack(obj) {
        return obj && (obj.deleteTrack !== undefined || (obj.strips !== undefined && obj.tracks === undefined));
    }
    function _isStrip(obj) {
        return obj && (obj.deleteStrip !== undefined || obj.element !== undefined);
    }

    // ── Editing operations ──
    function copySelected() {
        _clipboard = [];
        if (!root.selectedObject || !_isStrip(root.selectedObject))
            return;
        _clipboard = [root.selectedObject];
    }

    function cutSelected() {
        copySelected();
        if (root.selectedObject && root.selectedObject.deleteStrip)
            root.selectedObject.deleteStrip();
        root.selectedObject = null;
        _selectedLayers = [];
    }

    function pasteClips() {
        if (_clipboard.length === 0)
            return;
        var src = _clipboard[0];
        if (!src || !src.track)
            return;
        var track = src.track;
        var newStrip = src.clone(track);
        newStrip.startFrame = src.startFrame + 30;
        track.addStrip(newStrip);
        select(newStrip);
        if (src.element)
            root.elementSelected(src.element);
    }

    function duplicateSelected() {
        if (!root.selectedObject || !_isStrip(root.selectedObject))
            return;
        var src = root.selectedObject;
        if (!src.track)
            return;
        var track = src.track;
        var newStrip = src.clone(track);
        newStrip.startFrame = src.startFrame + src.duration + 10;
        track.addStrip(newStrip);
        select(newStrip);
        if (src.element)
            root.elementSelected(src.element);
    }

    function splitAtPlayhead() {
        if (!root.selectedObject || !_isStrip(root.selectedObject))
            return;
        var strip = root.selectedObject;
        if (!strip.track)
            return;
        var playhead = root.timelineModel ? root.timelineModel.currentFrame : 0;
        var stripStart = strip.startFrame;
        var stripEnd = stripStart + strip.duration;
        if (playhead <= stripStart || playhead >= stripEnd)
            return;

        var track = strip.track;
        var newStrip = strip.clone(track);
        newStrip.startFrame = playhead;
        newStrip.duration = stripEnd - playhead;
        strip.duration = playhead - stripStart;
        track.addStrip(newStrip);
        select(newStrip);
        if (strip.element)
            root.elementSelected(strip.element);
    }

    function deleteSelected() {
        if (!root.selectedObject)
            return;
        if (_isStrip(root.selectedObject))
            root.selectedObject.deleteStrip();
        else if (_isTrack(root.selectedObject))
            root.selectedObject.deleteTrack();
        else if (_isLayer(root.selectedObject))
            root.selectedObject.deleteLayer();
        root.selectedObject = null;
        _selectedLayers = [];
    }

    // ── Keyboard shortcuts ──
    focus: true
    Keys.onDeletePressed: deleteSelected()
    Keys.onPressed: function (event) {
        if (event.matches(StandardKey.Copy)) {
            copySelected();
            event.accepted = true;
        } else if (event.matches(StandardKey.Paste)) {
            pasteClips();
            event.accepted = true;
        } else if (event.matches(StandardKey.Cut)) {
            cutSelected();
            event.accepted = true;
        } else if (event.key === Qt.Key_D && (event.modifiers & Qt.ControlModifier)) {
            duplicateSelected();
            event.accepted = true;
        } else if (event.key === Qt.Key_S && (event.modifiers & Qt.ControlModifier)) {
            // Split at playhead: Ctrl+S
            splitAtPlayhead();
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            height: 32
            color: Theme.secondaryHover
            RowLayout {
                anchors.fill: parent
                spacing: 0

                Text {
                    Layout.preferredWidth: root.layerNameWidth
                    text: "Layers & Tracks"
                    color: Theme.mutedForeground
                    font.pixelSize: 11
                }
                TimeRuler {
                    Layout.fillWidth: true
                    timelineModel: root.timelineModel
                    pixelPerFrame: root.pixelPerFrame
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: headerMenu.popup()
            }

            Menu {
                id: headerMenu
                MenuItem {
                    text: "Add Layer"
                    onTriggered: {
                        var comp = root.timelineModel ? root.timelineModel.composition : null;
                        if (!comp)
                            return;
                        var tl = Qt.createQmlObject('import mokm_effector; TimelineLayer {}', comp, "dynamicLayer");
                        tl.name = "Layer " + (comp.layerCount() + 1);
                        tl.addTrack();
                        comp.addLayer(tl);
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollView {
                id: timelineScroll
                anchors.fill: parent
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: root.timelineModel && root.timelineModel.composition ? root.timelineModel.composition.layers : 0

                        delegate: Column {
                            id: layerColumn
                            width: parent.width
                            spacing: 1
                            property var layerModel: modelData

                            // ==================== LAYER HEADER ====================
                            Rectangle {
                                width: parent.width
                                height: root.rowHeight
                                color: root.selectedObject === modelData ? Qt.alpha(Theme.accent, 0.25) : Theme.secondaryHover

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    spacing: 6

                                    Text {
                                        text: modelData ? modelData.name : ""
                                        font.bold: true
                                        color: Theme.foreground
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.RightButton
                                    onClicked: layerMenu.popup()
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton
                                    onClicked: root.objectSelected(modelData)
                                }
                            }

                            Menu {
                                id: layerMenu
                                MenuItem {
                                    text: "Rename Layer"
                                    onTriggered: renameItem(layerColumn.layerModel)
                                }
                                MenuItem {
                                    text: "Add Track"
                                    onTriggered: {
                                        var m = layerColumn.layerModel;
                                        m.addTrack();
                                        if (m.composition)
                                            m.composition.rebuildFlatLayers();
                                    }
                                }
                                MenuItem {
                                    text: "Delete Layer"
                                    onTriggered: layerColumn.layerModel.deleteLayer()
                                }
                            }

                        // ==================== TRACKS ====================
                        Repeater {
                            model: modelData ? modelData.tracks : 0
                        delegate: Rectangle {
                            id: trackRow
                            width: parent.width
                            height: 38
                            color: root.selectedObject === modelData ? Qt.alpha(Theme.accent, 0.15) : (index % 2 === 0 ? Theme.secondary : Qt.alpha(Theme.secondaryHover, 0.3))

                            property var trackObj: null
                            property var layerObj: layerColumn.modelData
                            Component.onCompleted: trackObj = modelData

                            // Track Name Column
                            Rectangle {
                                width: root.layerNameWidth
                                height: parent.height
                                color: "transparent"
                                border.color: Theme.muted

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    Text {
                                        text: modelData ? modelData.name : ""
                                        color: Theme.foreground
                                        font.pixelSize: 11
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton
                                    onClicked: root.objectSelected(trackObj)
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.RightButton
                                    onClicked: trackMenu.popup()
                                }

                                Menu {
                                    id: trackMenu
                                    MenuItem {
                                        text: "Rename Track"
                                        onTriggered: renameItem(trackObj)
                                    }
                                    MenuItem {
                                        text: "Delete Track"
                                        onTriggered: trackObj.deleteTrack()
                                    }
                                }
                            }

                            // ==================== CONTENT AREA (Strips + Drop Zone) ====================
                            Item {
                                id: contentArea
                                anchors.left: parent.left
                                anchors.leftMargin: root.layerNameWidth
                                anchors.right: parent.right
                                height: parent.height

                                // Box select area (empty space)
                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"
                                    visible: true

                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton
                                        onClicked: {
                                            root.selectedObject = null;
                                            _selectedLayers = [];
                                            root.objectSelected(null);
                                        }
                                    }
                                }

                                // Drop Zone
                                DropArea {
                                    anchors.fill: parent
                                    keys: ["strip"]

                                    onDropped: function (drag) {
                                        if (drag.source.stripObj) {
                                            drag.source.stripObj.moveToTrack(trackObj);
                                        }
                                    }
                                }

                                // ==================== STRIPS ====================
                                Repeater {
                                    model: trackObj ? trackObj.strips : 0
                                    delegate: Rectangle {
                                        id: stripRect
                                        x: modelData.startFrame * root.pixelPerFrame
                                        y: 5
                                        width: Math.max(50, modelData.duration * root.pixelPerFrame)
                                        height: 28
                                        radius: 5
                                        color: Qt.alpha(root.stripColors[index % root.stripColors.length], 0.7)
                                        border.width: root.selectedObject === modelData ? 2.5 : 1.5
                                        border.color: root.selectedObject === modelData ? Theme.accent : Qt.lighter(color, 1.4)

                                        property var stripObj: modelData
                                        property var tlRoot: root

                                        // Visual Edges
                                        Rectangle {
                                            anchors.left: parent.left
                                            width: 6
                                            height: parent.height
                                            color: "#ffffff"
                                            opacity: 0.45
                                            radius: 5
                                        }
                                        Rectangle {
                                            anchors.right: parent.right
                                            width: 6
                                            height: parent.height
                                            color: "#ffffff"
                                            opacity: 0.3
                                            radius: 5
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: stripObj.name
                                            color: "white"
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }

                                        // ── Move Drag ──
                                        MouseArea {
                                            id: stripDragArea
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                            drag.target: stripRect
                                            drag.axis: Drag.XAxis
                                            drag.minimumX: 0

                                            onPressed: function (mouse) {
                                                stripRect.Drag.active = true;
                                                stripRect.Drag.keys = ["strip"];
                                                root.select(stripObj);
                                            }

                                            onReleased: function (mouse) {
                                                stripRect.Drag.active = false;
                                                let newStart = Math.max(0, stripRect.x / root.pixelPerFrame);
                                                stripObj.startFrame = snapFrame(newStart);
                                                stripRect.x = stripObj.startFrame * root.pixelPerFrame;
                                            }
                                        }

                                        // ── Right Resize Handle ──
                                        MouseArea {
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            width: 10
                                            cursorShape: Qt.SizeHorCursor

                                            property real startX: 0
                                            property int startDuration: 0

                                            onPressed: function (mouse) {
                                                startX = mouse.x;
                                                startDuration = stripObj.duration;
                                                root.select(stripObj);
                                            }

                                            onPositionChanged: function (mouse) {
                                                if (!(mouse.buttons & Qt.LeftButton))
                                                    return;
                                                var dx = mouse.x - startX;
                                                var newDuration = Math.max(5, Math.round(startDuration + dx / root.pixelPerFrame));
                                                stripObj.duration = newDuration;
                                                stripRect.width = Math.max(50, newDuration * root.pixelPerFrame);
                                            }

                                            onReleased: function (mouse) {
                                                stripObj.duration = Math.max(5, stripObj.duration);
                                            }
                                        }

                                        // ── Left Trim Handle ──
                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            width: 8
                                            color: root.selectedObject === stripObj ? Theme.accent : "transparent"
                                            opacity: root.selectedObject === stripObj ? 0.6 : 0.0

                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.leftMargin: -4
                                                cursorShape: Qt.SizeHorCursor

                                                property int startX: 0
                                                property int startFrame: 0
                                                property int startDuration: 0

                                                onPressed: function (mouse) {
                                                    startX = mouse.x;
                                                    startFrame = stripObj.startFrame;
                                                    startDuration = stripObj.duration;
                                                    root.select(stripObj);
                                                }

                                                onPositionChanged: function (mouse) {
                                                    if (!(mouse.buttons & Qt.LeftButton))
                                                        return;
                                                    var dx = mouse.x - startX;
                                                    var frameDelta = Math.round(dx / root.pixelPerFrame);

                                                    var newStart = Math.max(0, startFrame + frameDelta);
                                                    var newDuration = Math.max(5, startDuration - frameDelta);

                                                    if (newDuration < 5) {
                                                        newDuration = 5;
                                                        newStart = startFrame + startDuration - 5;
                                                    }

                                                    stripObj.startFrame = newStart;
                                                    stripObj.duration = newDuration;

                                                    stripRect.x = newStart * root.pixelPerFrame;
                                                    stripRect.width = newDuration * root.pixelPerFrame;
                                                }
                                            }
                                        }

                                        // Right Click
                                        MouseArea {
                                            anchors.fill: parent
                                            acceptedButtons: Qt.RightButton
                                            onClicked: function (mouse) {
                                                root.select(stripObj);
                                                stripMenu.popup();
                                            }
                                        }

                                        Menu {
                                            id: stripMenu
                                            MenuItem {
                                                text: "Edit"
                                                onTriggered: {
                                                    root.select(stripObj);
                                                }
                                            }
                                            MenuSeparator {}
                                            MenuItem {
                                                text: "Cut"
                                                onTriggered: cutSelected()
                                            }
                                            MenuItem {
                                                text: "Copy"
                                                onTriggered: copySelected()
                                            }
                                            MenuItem {
                                                text: "Duplicate"
                                                onTriggered: duplicateSelected()
                                            }
                                            MenuItem {
                                                text: "Split at Playhead"
                                                onTriggered: splitAtPlayhead()
                                            }
                                            MenuSeparator {}
                                            MenuItem {
                                                text: "Rename Strip"
                                                onTriggered: renameItem(stripObj)
                                            }
                                            MenuItem {
                                                text: "Delete Strip"
                                                onTriggered: {
                                                    stripObj.deleteStrip();
                                                    tlRoot.selectedObject = null;
                                                    _selectedLayers = [];
                                                }
                                            }
                                        }

                                        Drag.active: stripDragArea.drag.active
                                        Drag.hotSpot.x: width / 2
                                        Drag.hotSpot.y: height / 2
                                    }
                                }
                            }
                        }
                    }
                    }
                }
            }

            Rectangle {
                id: playhead
                x: root.layerNameWidth + (root.timelineModel ? root.timelineModel.currentFrame : 0) * root.pixelPerFrame
                y: 0; width: 2; height: parent.height; z: 20; color: Theme.error
                visible: root.timelineModel != null

                Rectangle {
                    width: 10; height: 14; radius: 7
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top; anchors.topMargin: -7
                    color: Theme.error
                }

                MouseArea {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 20; height: parent.height
                    cursorShape: Qt.SizeHorCursor
                    drag.target: parent; drag.axis: Drag.XAxis
                    drag.minimumX: root.layerNameWidth
                    onPositionChanged: {
                        if (drag.active && root.timelineModel) {
                            var f = Math.round((playhead.x - root.layerNameWidth) / root.pixelPerFrame);
                            root.timelineModel.currentFrame = Math.max(0, f);
                        }
                    }
                }
            }
        }
    }
}
}