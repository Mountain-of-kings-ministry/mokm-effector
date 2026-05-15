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

    // ── Tool System ──
    property string currentTool: "select"
    property bool snapEnabled: true
    property string globalTransition: "fade"

    property var _clipboard: []
    property var _dragState: ({}) // reusable drag state object
    property var _selectedLayers: []

    function snapFrame(v) {
        if (!snapEnabled)
            return Math.round(v);

        var snapped = Math.round(v);
        var bestSnap = snapped;
        var bestDist = 6; // 6px snap threshold

        // Snap to playhead
        if (root.timelineModel) {
            var playheadFrame = root.timelineModel.currentFrame;
            var playheadSnap = snapPixel(Math.round(playheadFrame));
            if (Math.abs(playheadSnap - v) < bestDist) {
                bestSnap = playheadFrame;
                bestDist = Math.abs(playheadSnap - v);
            }
        }

        // Snap to strip edges in all tracks
        if (root.timelineModel && root.timelineModel.composition) {
            var comp = root.timelineModel.composition;
            for (var li = 0; li < comp.layerCount(); li++) {
                var tl = comp.layerAt(li);
                if (!tl) continue;
                for (var ti = 0; ti < tl.trackCount; ti++) {
                    var tr = tl.trackAt(ti);
                    if (!tr) continue;
                    for (var si = 0; si < tr.stripCount; si++) {
                        var st = tr.stripAt(si);
                        if (!st) continue;
                        var s = st.startFrame;
                        var e = s + st.duration;
                        // Snap to start
                        var d = snapPixel(s) - v;
                        if (Math.abs(d) < bestDist) { bestSnap = s; bestDist = Math.abs(d); }
                        // Snap to end
                        d = snapPixel(e) - v;
                        if (Math.abs(d) < bestDist) { bestSnap = e; bestDist = Math.abs(d); }
                    }
                }
            }
        }

        return bestSnap;
    }

    function snapPixel(frame) {
        return frame * root.pixelPerFrame;
    }

    function toolName(t) {
        var names = {
            "select": "Select",
            "move": "Move",
            "trimLeft": "Trim Left",
            "trimRight": "Trim Right",
            "blade": "Blade",
            "transition": "Transition"
        };
        return names[t] || t;
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
            _clipboard = [{ strip: root.selectedObject, track: root.selectedObject.track }];
        }

        function cutSelected() {
            if (!root.selectedObject || !_isStrip(root.selectedObject))
                return;
            copySelected();
            root.selectedObject.deleteStrip();
            root.selectedObject = null;
            _selectedLayers = [];
        }

        function pasteClips() {
            if (_clipboard.length === 0)
                return;
            var entry = _clipboard[0];
            if (!entry || !entry.strip || !entry.track)
                return;
            var src = entry.strip;
            var track = entry.track;
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

    function splitStripAt(strip, frame) {
        if (!strip || !strip.track)
            return null;
        var start = strip.startFrame;
        var end = start + strip.duration;
        if (frame <= start || frame >= end)
            return null;
        var track = strip.track;
        var newStrip = strip.clone(track);
        newStrip.startFrame = frame;
        newStrip.duration = end - frame;
        strip.duration = frame - start;
        track.addStrip(newStrip);
        return newStrip;
    }

    function splitAtPlayheadForLayer(layer) {
        if (!layer)
            return;
        var playhead = root.timelineModel ? root.timelineModel.currentFrame : 0;
        for (var ti = 0; ti < layer.trackCount; ti++) {
            var track = layer.trackAt(ti);
            if (!track) continue;
            var stripsToSplit = [];
            for (var si = 0; si < track.stripCount; si++) {
                stripsToSplit.push(track.stripAt(si));
            }
            for (var si = 0; si < stripsToSplit.length; si++) {
                var st = stripsToSplit[si];
                if (playhead > st.startFrame && playhead < st.startFrame + st.duration)
                    splitStripAt(st, playhead);
            }
        }
    }

    function splitBySelection() {
        var playhead = root.timelineModel ? root.timelineModel.currentFrame : 0;
        var toSplit = [];
        for (var i = 0; i < _selectedLayers.length; i++) {
            var obj = _selectedLayers[i];
            if (_isStrip(obj) && obj.track)
                toSplit.push(obj);
        }
        if (toSplit.length === 0)
            return;
        // Split non-adjacent strips within same track first
        for (var i = 0; i < toSplit.length; i++) {
            var st = toSplit[i];
            if (playhead > st.startFrame && playhead < st.startFrame + st.duration)
                splitStripAt(st, playhead);
        }
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

    function rippleDeleteSelected() {
        if (!root.selectedObject || !_isStrip(root.selectedObject))
            return;
        var strip = root.selectedObject;
        var track = strip.track;
        if (!track) return;
        var removedStart = strip.startFrame;
        var removedDuration = strip.duration;
        strip.deleteStrip();
        // Shift following strips left by removed duration
        for (var i = 0; i < track.stripCount; i++) {
            var s = track.stripAt(i);
            if (s && s.startFrame >= removedStart + removedDuration)
                s.startFrame = s.startFrame - removedDuration;
        }
        root.selectedObject = null;
        _selectedLayers = [];
    }

    // ── Track Type Creation Dialog ──
    Dialog {
        id: trackTypeDialog
        title: "New Track"
        standardButtons: Dialog.Cancel
        modal: true
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        property var _targetLayer: null

        ColumnLayout {
            spacing: 8
            Button {
                text: "Video Track"
                icon.source: "qrc:/icons/outline/video.svg"
                Layout.fillWidth: true
                onClicked: {
                    createNewTrack(trackTypeDialog._targetLayer, Track.Video);
                    trackTypeDialog.close();
                }
            }
            Button {
                text: "Audio Track"
                icon.source: "qrc:/icons/outline/volume.svg"
                Layout.fillWidth: true
                onClicked: {
                    createNewTrack(trackTypeDialog._targetLayer, Track.Audio);
                    trackTypeDialog.close();
                }
            }
            Button {
                text: "Image Track"
                icon.source: "qrc:/icons/outline/photo.svg"
                Layout.fillWidth: true
                onClicked: {
                    createNewTrack(trackTypeDialog._targetLayer, Track.Image);
                    trackTypeDialog.close();
                }
            }
        }
    }

    function _trackTypeName(type) {
        if (type === Track.Audio) return "Audio";
        if (type === Track.Image) return "Image";
        return "Video";
    }

    function createNewTrack(timelineLayer, trackType) {
        if (!timelineLayer) return;
        trackTypeDialog._targetLayer = null;
        var track = Qt.createQmlObject('import mokm_effector; Track {}', timelineLayer, "dynamicTrack");
        track.name = _trackTypeName(trackType) + " " + (timelineLayer.trackCount + 1);
        track.trackType = trackType;
        timelineLayer.addTrack(track);
        if (timelineLayer.composition)
            timelineLayer.composition.rebuildFlatLayers();
    }
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
        } else if (event.key === Qt.Key_S && !(event.modifiers & Qt.ControlModifier)) {
            // S = Toggle snap (not Ctrl+S, which is split)
            snapEnabled = !snapEnabled;
            event.accepted = true;
        } else if (event.key === Qt.Key_S && (event.modifiers & Qt.ControlModifier)) {
            // Split at playhead: Ctrl+S
            splitAtPlayhead();
            event.accepted = true;
        } else if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
            rippleDeleteSelected();
            event.accepted = true;
        } else if (event.key === Qt.Key_V && !(event.modifiers & Qt.ControlModifier)) {
            currentTool = "select";
            event.accepted = true;
        } else if (event.key === Qt.Key_M && !(event.modifiers & Qt.ControlModifier)) {
            currentTool = "move";
            event.accepted = true;
        } else if (event.key === Qt.Key_T && !(event.modifiers & Qt.ControlModifier)) {
            // Cycle trim modes: off → trimLeft → trimRight → off
            if (currentTool === "trimLeft") currentTool = "trimRight";
            else if (currentTool === "trimRight") currentTool = "select";
            else currentTool = "trimLeft";
            event.accepted = true;
        } else if (event.key === Qt.Key_B && !(event.modifiers & Qt.ControlModifier)) {
            currentTool = "blade";
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            currentTool = "select";
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
                        // Create first track with dialog
                        trackTypeDialog._targetLayer = tl;
                        trackTypeDialog.open();
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
                                color: {
                                    if (root.selectedObject === modelData)
                                        return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25);
                                    if (modelData && modelData.locked)
                                        return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15);
                                    if (modelData && !modelData.visible)
                                        return Theme.secondary;
                                    return Theme.secondaryHover;
                                }

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
                                    onClicked: root.select(modelData)
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
                                        trackTypeDialog._targetLayer = layerColumn.layerModel;
                                        trackTypeDialog.open();
                                    }
                                }
                                MenuSeparator {}
                                MenuItem {
                                    text: "Cut Through Layer"
                                    onTriggered: root.splitAtPlayheadForLayer(layerColumn.layerModel)
                                }
                                MenuSeparator {}
                                MenuItem {
                                    text: "Toggle Visibility"
                                    checkable: true
                                    checked: layerColumn.layerModel ? layerColumn.layerModel.visible : true
                                    onTriggered: {
                                        if (layerColumn.layerModel)
                                            layerColumn.layerModel.visible = !layerColumn.layerModel.visible;
                                    }
                                }
                                MenuItem {
                                    text: "Toggle Lock"
                                    checkable: true
                                    checked: layerColumn.layerModel ? layerColumn.layerModel.locked : false
                                    onTriggered: {
                                        if (layerColumn.layerModel)
                                            layerColumn.layerModel.locked = !layerColumn.layerModel.locked;
                                    }
                                }
                                MenuSeparator {}
                                MenuItem {
                                    text: "Move Up"
                                    enabled: !!(layerColumn.layerModel && layerColumn.layerModel.composition)
                                    onTriggered: {
                                        if (layerColumn.layerModel && layerColumn.layerModel.composition) {
                                            var comp = layerColumn.layerModel.composition;
                                            var idx = comp.layerIndex(layerColumn.layerModel);
                                            if (idx > 0)
                                                comp.moveLayer(idx, idx - 1);
                                        }
                                    }
                                }
                                MenuItem {
                                    text: "Move Down"
                                    enabled: !!(layerColumn.layerModel && layerColumn.layerModel.composition)
                                    onTriggered: {
                                        if (layerColumn.layerModel && layerColumn.layerModel.composition) {
                                            var comp = layerColumn.layerModel.composition;
                                            var idx = comp.layerIndex(layerColumn.layerModel);
                                            if (idx < comp.layerCount() - 1)
                                                comp.moveLayer(idx, idx + 1);
                                        }
                                    }
                                }
                                MenuSeparator {}
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
                            color: {
                                if (root.selectedObject === modelData)
                                    return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15);
                                if (trackObj && trackObj.locked)
                                    return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1);
                                if (trackObj && !trackObj.enabled)
                                    return Theme.secondary;
                                return (index % 2 === 0 ? Theme.secondary : Qt.rgba(Theme.secondaryHover.r, Theme.secondaryHover.g, Theme.secondaryHover.b, 0.3));
                            }

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
                                    anchors.leftMargin: 8
                                    spacing: 4
                                    Image {
                                        source: trackObj && trackObj.trackType === Track.Audio ? "qrc:/icons/outline/volume.svg"
                                              : trackObj && trackObj.trackType === Track.Image ? "qrc:/icons/outline/photo.svg"
                                              : "qrc:/icons/outline/video.svg"
                                        sourceSize.width: 14
                                        sourceSize.height: 14
                                    }
                                    Text {
                                        text: modelData ? modelData.name : ""
                                        color: Theme.foreground
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton
                                    onClicked: root.select(trackObj)
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.RightButton
                                    onClicked: trackMenu.popup()
                                }

                                Menu {
                                    id: trackMenu
                                    MenuItem {
                                        text: "Select All Strips"
                                        onTriggered: {
                                            var t = trackObj;
                                            if (!t) return;
                                            _selectedLayers = [];
                                            for (var i = 0; i < t.stripCount; i++)
                                                _selectedLayers.push(t.stripAt(i));
                                            if (_selectedLayers.length > 0)
                                                root.selectedObject = _selectedLayers[0];
                                        }
                                    }
                                    MenuSeparator {}
                                    MenuItem {
                                        text: "Toggle Enabled"
                                        checkable: true
                                        checked: trackObj ? trackObj.enabled : true
                                        onTriggered: {
                                            if (trackObj)
                                                trackObj.enabled = !trackObj.enabled;
                                        }
                                    }
                                    MenuItem {
                                        text: "Toggle Lock"
                                        checkable: true
                                        checked: trackObj ? trackObj.locked : false
                                        onTriggered: {
                                            if (trackObj)
                                                trackObj.locked = !trackObj.locked;
                                        }
                                    }
                                    MenuSeparator {}
                                    MenuItem {
                                        text: "Rename Track"
                                        onTriggered: renameItem(trackObj)
                                    }
                                    MenuItem {
                                        text: "Delete Track"
                                        onTriggered: trackObj.deleteTrack()
                                    }
                                    MenuSeparator {}
                                    MenuItem {
                                        text: "Move Track Up"
                                        enabled: !!(trackObj && trackObj.layer && trackObj.layer.trackIndex && trackObj.layer.trackIndex(trackObj) > 0)
                                        onTriggered: {
                                            if (trackObj && trackObj.layer) {
                                                var tl = trackObj.layer;
                                                var idx = tl.trackIndex(trackObj);
                                                if (idx > 0)
                                                    tl.moveTrack(idx, idx - 1);
                                            }
                                        }
                                    }
                                    MenuItem {
                                        text: "Move Track Down"
                                        enabled: !!(trackObj && trackObj.layer && trackObj.layer.trackIndex && trackObj.layer.trackIndex(trackObj) < trackObj.layer.trackCount - 1)
                                        onTriggered: {
                                            if (trackObj && trackObj.layer) {
                                                var tl = trackObj.layer;
                                                var idx = tl.trackIndex(trackObj);
                                                if (idx < tl.trackCount - 1)
                                                    tl.moveTrack(idx, idx + 1);
                                            }
                                        }
                                    }
                                    MenuItem {
                                        text: "Move to Next Layer"
                                        enabled: !!(trackObj && trackObj.layer && trackObj.layer.composition)
                                        onTriggered: {
                                            if (!trackObj || !trackObj.layer) return;
                                            var curLayer = trackObj.layer;
                                            var comp = curLayer.composition;
                                            var layerIdx = comp.layerIndex(curLayer);
                                            if (layerIdx < comp.layerCount() - 1) {
                                                var nextLayer = comp.layerAt(layerIdx + 1);
                                                if (nextLayer) {
                                                    curLayer.removeTrack(trackObj);
                                                    nextLayer.addTrack(trackObj);
                                                }
                                            }
                                        }
                                    }
                                    MenuItem {
                                        text: "Move to Previous Layer"
                                        enabled: !!(trackObj && trackObj.layer && trackObj.layer.composition)
                                        onTriggered: {
                                            if (!trackObj || !trackObj.layer) return;
                                            var curLayer = trackObj.layer;
                                            var comp = curLayer.composition;
                                            var layerIdx = comp.layerIndex(curLayer);
                                            if (layerIdx > 0) {
                                                var prevLayer = comp.layerAt(layerIdx - 1);
                                                if (prevLayer) {
                                                    curLayer.removeTrack(trackObj);
                                                    prevLayer.addTrack(trackObj);
                                                }
                                            }
                                        }
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
                                        color: {
                                            var c = Qt.color(root.stripColors[index % root.stripColors.length]);
                                            return Qt.rgba(c.r, c.g, c.b, 0.7);
                                        }
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

                                        // ── Transition In Overlay ──
                                        Rectangle {
                                            anchors.left: parent.left
                                            height: parent.height
                                            width: stripObj.transitionInDuration * root.pixelPerFrame
                                            color: Qt.rgba(1, 1, 1, 0.15)
                                            visible: width > 0
                                            Rectangle {
                                                anchors.right: parent.right; width: 1; height: parent.height; color: Qt.rgba(1,1,1,0.3)
                                            }
                                        }

                                        // ── Transition Out Overlay ──
                                        Rectangle {
                                            anchors.right: parent.right
                                            height: parent.height
                                            width: stripObj.transitionOutDuration * root.pixelPerFrame
                                            color: Qt.rgba(1, 1, 1, 0.15)
                                            visible: width > 0
                                            Rectangle {
                                                anchors.left: parent.left; width: 1; height: parent.height; color: Qt.rgba(1,1,1,0.3)
                                            }
                                        }

                                        // ── Transition In Handle ──
                                        Rectangle {
                                            id: transInHandle
                                            anchors.left: parent.left
                                            anchors.leftMargin: stripObj.transitionInDuration * root.pixelPerFrame - 4
                                            y: -2; width: 8; height: 8; radius: 4
                                            color: Theme.accent; border.color: "white"; border.width: 1
                                            visible: root.currentTool === "transition"
                                            z: 5
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.SizeHorCursor; drag.target: parent; drag.axis: Drag.XAxis
                                                onPositionChanged: {
                                                    if (drag.active) {
                                                        var frames = Math.round(parent.x / tlRoot.pixelPerFrame);
                                                        stripObj.transitionInDuration = Math.max(0, Math.min(frames, stripObj.duration - stripObj.transitionOutDuration));
                                                        stripObj.transitionIn = tlRoot.globalTransition;
                                                    }
                                                }
                                            }
                                        }

                                        // ── Transition Out Handle ──
                                        Rectangle {
                                            id: transOutHandle
                                            anchors.right: parent.right
                                            anchors.rightMargin: stripObj.transitionOutDuration * tlRoot.pixelPerFrame - 4
                                            y: -2; width: 8; height: 8; radius: 4
                                            color: Theme.accent; border.color: "white"; border.width: 1
                                            visible: tlRoot.currentTool === "transition"
                                            z: 5
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.SizeHorCursor; drag.target: parent; drag.axis: Drag.XAxis
                                                onPositionChanged: {
                                                    if (drag.active) {
                                                        var frames = Math.round((stripRect.width - (parent.x + parent.width)) / tlRoot.pixelPerFrame);
                                                        stripObj.transitionOutDuration = Math.max(0, Math.min(frames, stripObj.duration - stripObj.transitionInDuration));
                                                        stripObj.transitionOut = tlRoot.globalTransition;
                                                    }
                                                }
                                            }
                                        }

                                        // Waveform overlay for audio strips
                                        Canvas {
                                            id: waveformCanvas
                                            anchors.fill: parent
                                            anchors.margins: 2
                                            visible: stripObj && stripObj.element && stripObj.element.waveformDataList ? stripObj.element.waveformDataList.length > 0 : false
                                            onPaint: {
                                                var ctx = getContext("2d");
                                                if (!ctx) return;
                                                ctx.clearRect(0, 0, width, height);
                                                if (!stripObj || !stripObj.element) return;
                                                var data = stripObj.element.waveformDataList;
                                                if (!data || data.length === 0) return;
                                                ctx.fillStyle = Qt.rgba(1, 1, 1, 0.2);
                                                var midY = height / 2;
                                                var xStep = width / data.length;
                                                for (var i = 0; i < data.length; i++) {
                                                    var x = i * xStep;
                                                    var h = Math.abs(data[i]) * (midY - 1);
                                                    ctx.fillRect(x, midY - h, Math.max(1, xStep + 0.5), Math.max(1, h * 2));
                                                }
                                            }
                                            onWidthChanged: requestPaint()
                                            onHeightChanged: requestPaint()
                                        }

                                        // ── Move Drag ──
                                        MouseArea {
                                            id: stripDragArea
                                            anchors.fill: parent
                                            anchors.leftMargin: root.currentTool === "trimLeft" ? 0 : 8
                                            anchors.rightMargin: root.currentTool === "trimRight" ? 0 : 8
                                            acceptedButtons: Qt.LeftButton
                                            cursorShape: {
                                                if (root.currentTool === "blade") return Qt.IBeamCursor;
                                                if (root.currentTool === "trimLeft" || root.currentTool === "trimRight") return Qt.SizeHorCursor;
                                                return pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor;
                                            }
                                            drag.target: (root.currentTool === "select" || root.currentTool === "move") ? stripRect : null
                                            drag.axis: Drag.XAxis
                                            drag.minimumX: 0

                                            property real _pressX: 0
                                            property int _pressFrame: 0

                                            onPressed: function (mouse) {
                                                if (root.currentTool === "blade") {
                                                    // Split at click position
                                                    var clickFrame = Math.round((stripRect.x + mouse.x) / root.pixelPerFrame);
                                                    var stripStart = stripObj.startFrame;
                                                    var stripEnd = stripStart + stripObj.duration;
                                                    if (clickFrame > stripStart && clickFrame < stripEnd && stripObj.track) {
                                                        var track = stripObj.track;
                                                        var newStrip = stripObj.clone(track);
                                                        newStrip.startFrame = clickFrame;
                                                        newStrip.duration = stripEnd - clickFrame;
                                                        stripObj.duration = clickFrame - stripStart;
                                                        track.addStrip(newStrip);
                                                    }
                                                    return;
                                                }

                                                if (root.currentTool === "trimLeft") {
                                                    _pressX = mouse.x;
                                                    _pressFrame = stripObj.startFrame;
                                                    return;
                                                }

                                                if (root.currentTool === "trimRight") {
                                                    _pressX = mouse.x;
                                                    _pressFrame = stripObj.duration;
                                                    return;
                                                }

                                                // select/move
                                                stripRect.Drag.active = true;
                                                stripRect.Drag.keys = ["strip"];
                                                root.select(stripObj);
                                            }

                                            onPositionChanged: function (mouse) {
                                                if (!(mouse.buttons & Qt.LeftButton)) return;

                                                if (root.currentTool === "trimLeft") {
                                                    var dx = mouse.x - _pressX;
                                                    var deltaFrames = Math.round(dx / root.pixelPerFrame);
                                                    var oldStart = stripObj.startFrame;
                                                    var oldDuration = stripObj.duration;
                                                    var newStart = Math.max(0, _pressFrame + deltaFrames);
                                                    var newDuration = Math.max(5, oldDuration - (newStart - oldStart));
                                                    if (newDuration < 5) {
                                                        newDuration = 5;
                                                        newStart = oldStart + oldDuration - 5;
                                                    }
                                                    stripObj.startFrame = newStart;
                                                    stripObj.duration = newDuration;
                                                    stripRect.x = newStart * root.pixelPerFrame;
                                                    stripRect.width = newDuration * root.pixelPerFrame;
                                                    return;
                                                }

                                                if (root.currentTool === "trimRight") {
                                                    var dx2 = mouse.x - _pressX;
                                                    var newDuration = Math.max(5, Math.round(_pressFrame + dx2 / root.pixelPerFrame));
                                                    stripObj.duration = newDuration;
                                                    stripRect.width = Math.max(50, newDuration * root.pixelPerFrame);
                                                    return;
                                                }
                                            }

                                            onReleased: function (mouse) {
                                                if (root.currentTool === "trimLeft" || root.currentTool === "trimRight") {
                                                    var snapped = root.snapFrame(stripObj.startFrame);
                                                    var durSnapped = root.snapFrame(stripObj.startFrame + stripObj.duration);
                                                    var finalStart = snapped;
                                                    var finalDuration = Math.max(5, durSnapped - snapped);
                                                    
                                                    // Check resize collision
                                                    if (!trackObj.canPlaceStrip(stripObj, finalStart, finalDuration)) {
                                                        // If collision, we don't snap/resize to overlap
                                                        // For simplicity, we just revert or let it overlap for now if resizing?
                                                        // Professional behavior: push others or prevent. Let's prevent for now.
                                                        stripRect.x = stripObj.startFrame * root.pixelPerFrame;
                                                        stripRect.width = stripObj.duration * root.pixelPerFrame;
                                                    } else {
                                                        stripObj.startFrame = finalStart;
                                                        stripObj.duration = finalDuration;
                                                        stripRect.x = finalStart * root.pixelPerFrame;
                                                        stripRect.width = finalDuration * root.pixelPerFrame;
                                                    }
                                                    root.select(stripObj);
                                                    return;
                                                }

                                                if (root.currentTool !== "select" && root.currentTool !== "move")
                                                    return;

                                                stripRect.Drag.active = false;
                                                var newStart = root.snapFrame(Math.max(0, stripRect.x / root.pixelPerFrame));
                                                
                                                // ── Collision Avoidance ──
                                                if (!trackObj.canPlaceStrip(stripObj, newStart, stripObj.duration)) {
                                                    // Collision! Find/Create new track above
                                                    var tl = trackObj.layer;
                                                    var curIdx = tl.trackIndex(trackObj);
                                                    var newTrack = null;
                                                    
                                                    // Try track above first
                                                    if (curIdx > 0) {
                                                        var above = tl.trackAt(curIdx - 1);
                                                        if (above && above.trackType === trackObj.trackType && above.canPlaceStrip(stripObj, newStart, stripObj.duration)) {
                                                            newTrack = above;
                                                        }
                                                    }
                                                    
                                                    if (!newTrack) {
                                                        // Insert new track
                                                        newTrack = tl.insertTrack(curIdx, trackObj.trackType);
                                                        newTrack.name = trackObj.name + " (Overlap)";
                                                    }
                                                    
                                                    stripObj.startFrame = newStart;
                                                    stripObj.moveToTrack(newTrack);
                                                } else {
                                                    stripObj.startFrame = newStart;
                                                    stripRect.x = newStart * root.pixelPerFrame;
                                                }
                                            }
                                        }

                                        // ── Right Resize Handle ──
                                        MouseArea {
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            width: 10
                                            cursorShape: Qt.SizeHorCursor
                                            acceptedButtons: Qt.LeftButton

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
                                                acceptedButtons: Qt.LeftButton

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
                                            z: 2
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
                                    MenuItem {
                                        text: "Split by Selection"
                                        onTriggered: splitBySelection()
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
                                                root.selectedObject = null;
                                                _selectedLayers = [];
                                            }
                                        }
                                        MenuItem {
                                            text: "Ripple Delete"
                                            onTriggered: {
                                                root.selectedObject = stripObj;
                                                rippleDeleteSelected();
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