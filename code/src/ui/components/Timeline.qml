import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root
    color: Theme.secondary
    clip: true

    property alias timelineModel: controller.timelineModel
    property var selectedLayer: null
    property var project: null
    signal layerSelected(var layer)
    signal selectionChanged(var layers)

    property real pixelPerFrame: 8
    property int layerNameWidth: 140
    property int trackHeaderHeight: 22
    property int stripRowHeight: 28

    readonly property var stripColors: ["#3b82f6", "#8b5cf6", "#ec4899", "#ef4444", "#f59e0b", "#22c55e", "#14b8a6", "#06b6d4", "#6366f1", "#d946ef"]

    property var selectedLayers: []
    property int selectionStamp: 0

    // Clipboard
    property var clipboardData: []

    onSelectedLayerChanged: {
        if (selectedLayer === null)
            selectedLayers = [];
        else if (selectedLayers.indexOf(selectedLayer) < 0)
            selectedLayers = [selectedLayer];
    }

    function selectLayer(layer, addToSelection) {
        if (!layer) return;
        if (addToSelection) {
            var idx = selectedLayers.indexOf(layer);
            if (idx >= 0)
                selectedLayers.splice(idx, 1);
            else
                selectedLayers.push(layer);
            selectedLayers = selectedLayers.slice();
        } else if (selectedLayers.indexOf(layer) >= 0) {
            // preserve multi-select
        } else {
            selectedLayers = [layer];
        }
        selectionStamp++;
        root.layerSelected(selectedLayers.length > 0 ? selectedLayers[0] : null);
        root.selectionChanged(selectedLayers);
    }

    function clearSelection() {
        selectedLayers = [];
        selectionStamp++;
        root.layerSelected(null);
        root.selectionChanged([]);
    }

    function rectsIntersect(r1, r2) {
        return !(r1.x + r1.width < r2.x || r2.x + r2.width < r1.x ||
                 r1.y + r1.height < r2.y || r2.y + r2.height < r1.y);
    }

    function snapFrame(v) { return Math.round(v); }

    function findTrackForClip(clip) {
        if (!controller.timelineModel?.composition) return null;
        var comp = controller.timelineModel.composition;
        for (var ti = 0; ti < comp.trackCount; ti++) {
            var t = comp.trackAt(ti);
            for (var ci = 0; ci < t.clipCount; ci++) {
                if (t.clipAt(ci) === clip) return t;
            }
        }
        return null;
    }

    function findClipIndex(clip) {
        var track = findTrackForClip(clip);
        if (!track) return -1;
        return track.indexOf(clip);
    }

    function copySelectedLayers() {
        clipboardData = [];
        for (var i = 0; i < selectedLayers.length; i++) {
            var layer = selectedLayers[i];
            clipboardData.push({
                json: layer.serialize(),
                startFrame: layer.startFrame,
                duration: layer.duration
            });
        }
    }

    function cutSelectedLayers() {
        copySelectedLayers();
        deleteSelectedLayers();
    }

    function pasteClips() {
        if (clipboardData.length === 0 || !controller.timelineModel?.composition) return;
        var comp = controller.timelineModel.composition;
        var targetTrack = comp.trackCount > 0 ? comp.trackAt(0) : comp.addTrack();
        var newSelection = [];
        var baseFrame = controller.timelineModel?.currentFrame ?? 0;
        for (var i = 0; i < clipboardData.length; i++) {
            var data = clipboardData[i];
            var layer = createLayerFromJson(data.json, targetTrack);
            if (layer) {
                layer.startFrame = baseFrame + i * 10;
                layer.duration = data.duration;
                targetTrack.addClip(layer);
                newSelection.push(layer);
            }
        }
        selectedLayers = newSelection;
        selectionStamp++;
        root.layerSelected(selectedLayers.length > 0 ? selectedLayers[0] : null);
        root.selectionChanged(selectedLayers);
        if (project) project.captureSnapshot();
    }

    function duplicateSelectedLayers() {
        if (selectedLayers.length === 0 || !controller.timelineModel?.composition) return;
        clipboardData = [];
        var comp = controller.timelineModel.composition;
        var newSelection = [];
        var baseFrame = (controller.timelineModel?.currentFrame ?? 0) + 10;
        for (var i = 0; i < selectedLayers.length; i++) {
            var src = selectedLayers[i];
            var track = findTrackForClip(src);
            if (!track) continue;
            var jsonStr = src.serialize();
            clipboardData.push({
                json: jsonStr,
                startFrame: src.startFrame,
                duration: src.duration
            });
            var layer = createLayerFromJson(jsonStr, track);
            if (layer) {
                layer.startFrame = src.startFrame + src.duration + 5;
                layer.duration = src.duration;
                track.addClip(layer);
                newSelection.push(layer);
            }
        }
        selectedLayers = newSelection;
        selectionStamp++;
        if (project) project.captureSnapshot();
    }

    function deleteSelectedLayers() {
        if (selectedLayers.length === 0) return;
        for (var i = selectedLayers.length - 1; i >= 0; i--) {
            var track = findTrackForClip(selectedLayers[i]);
            if (track) track.removeClip(selectedLayers[i]);
        }
        selectedLayers = [];
        selectionStamp++;
        root.layerSelected(null);
        if (project) project.captureSnapshot();
    }

    function splitAtPlayhead() {
        if (selectedLayers.length !== 1 || !controller.timelineModel) return;
        var layer = selectedLayers[0];
        var cutFrame = controller.timelineModel.currentFrame;
        if (cutFrame <= layer.startFrame || cutFrame >= layer.startFrame + layer.duration) return;
        var track = findTrackForClip(layer);
        if (!track) return;
        var jsonStr = layer.serialize();
        var newLayer = createLayerFromJson(jsonStr, track);
        if (newLayer) {
            var splitPoint = cutFrame;
            var originalEnd = layer.startFrame + layer.duration;
            layer.duration = splitPoint - layer.startFrame;
            newLayer.startFrame = splitPoint;
            newLayer.duration = originalEnd - splitPoint;
            track.addClip(newLayer);
            if (project) project.captureSnapshot();
        }
    }

    function bladeAtFrame(frame) {
        if (selectedLayers.length !== 1) return;
        var layer = selectedLayers[0];
        if (frame <= layer.startFrame || frame >= layer.startFrame + layer.duration) return;
        var track = findTrackForClip(layer);
        if (!track) return;
        var jsonStr = layer.serialize();
        var newLayer = createLayerFromJson(jsonStr, track);
        if (newLayer) {
            var originalEnd = layer.startFrame + layer.duration;
            layer.duration = frame - layer.startFrame;
            newLayer.startFrame = frame;
            newLayer.duration = originalEnd - frame;
            track.addClip(newLayer);
            if (project) project.captureSnapshot();
        }
    }

    function createLayerFromJson(jsonStr, parent) {
        // Deserialize from JSON string using the C++ serialize/deserialize mechanism
        var temp;
        var obj = JSON.parse(jsonStr);
        if (obj.type === "shape")
            temp = shapeComponent.createObject(parent, {});
        else if (obj.type === "text")
            temp = textComponent.createObject(parent, {});
        else
            return null;
        // QJsonDocument -> QJsonObject conversion happens at C++ level
        temp.deserialize(jsonStr);
        return temp;
    }

    property Component shapeComponent: ShapeLayer {}
    property Component textComponent: TextLayer {}

    function globalColorIndex(layer) {
        var comp = controller.timelineModel ? controller.timelineModel.composition : null;
        if (!comp) return 0;
        var idx = 0;
        for (var ti = 0; ti < comp.trackCount; ti++) {
            var t = comp.trackAt(ti);
            for (var ci = 0; ci < t.clipCount; ci++) {
                if (t.clipAt(ci) === layer) return idx;
                idx++;
            }
        }
        return 0;
    }

    Item {
        id: controller
        property var timelineModel: null
    }

    function debug(msg) { console.log("[Timeline]", msg); }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            height: 28
            color: Theme.secondaryHover
            RowLayout {
                anchors.fill: parent
                spacing: 0
                Item {
                    Layout.preferredWidth: root.layerNameWidth
                    Layout.fillHeight: true
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Tracks")
                        color: Theme.mutedForeground
                        font.pixelSize: 10
                    }
                }
                TimeRuler {
                    Layout.fillWidth: true
                    timelineModel: controller.timelineModel
                    pixelPerFrame: root.pixelPerFrame
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            RowLayout {
                width: parent.width
                spacing: 0

                // Track names column
                Item {
                    id: trackNamesColumn
                    Layout.preferredWidth: root.layerNameWidth
                    Layout.fillHeight: true

                    function computeTrackY(trackIndex) {
                        var comp = controller.timelineModel ? controller.timelineModel.composition : null;
                        if (!comp) return 0;
                        var y = 0;
                        for (var ti = 0; ti < trackIndex; ti++)
                            y += root.trackHeaderHeight + comp.trackAt(ti).clipCount * root.stripRowHeight;
                        return y;
                    }

                    Repeater {
                        model: controller.timelineModel && controller.timelineModel.composition ? controller.timelineModel.composition.tracks : 0
                        delegate: Rectangle {
                            y: trackNamesColumn.computeTrackY(index)
                            width: parent.width
                            height: root.trackHeaderHeight
                            color: Theme.secondaryHover

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 4
                                Text {
                                    text: modelData?.name ?? "Track"
                                    color: Theme.foreground
                                    font.pixelSize: 11
                                    font.bold: true
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 3
                                    color: Theme.muted
                                    Text {
                                        anchors.centerIn: parent
                                        text: "+"
                                        color: Theme.foreground
                                        font.pixelSize: 10
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (controller.timelineModel?.composition) {
                                                controller.timelineModel.composition.addTrack();
                                                if (root.project) root.project.captureSnapshot();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Track contents
                Rectangle {
                    id: stripArea
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Qt.alpha(Theme.background, 0.3)

                    Column {
                        id: trackColumn
                        anchors.fill: parent
                        spacing: 0

                        Repeater {
                            model: controller.timelineModel && controller.timelineModel.composition ? controller.timelineModel.composition.tracks : 0

                            delegate: Item {
                                id: trackRow
                                width: stripArea.width
                                height: root.trackHeaderHeight + root.stripRowHeight * Math.max(1, modelData && modelData.clipCount ? modelData.clipCount : 1)

                                property var trackObj: modelData

                                // Empty space fill
                                Rectangle {
                                    y: root.trackHeaderHeight
                                    width: parent.width
                                    height: parent.height - root.trackHeaderHeight
                                    color: Qt.alpha(Theme.secondaryHover, 0.08)

                                    // Right-click on empty track space
                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.RightButton
                                        onClicked: mouse => {
                                            emptyMenu.track = trackRow.trackObj;
                                            emptyMenu.popup(mouse.x, mouse.y);
                                        }
                                    }
                                }

                                // Clips
                                Repeater {
                                    model: trackRow.trackObj && trackRow.trackObj.clips ? trackRow.trackObj.clips : 0

                                    delegate: Item {
                                        id: stripRow
                                        y: root.trackHeaderHeight + index * root.stripRowHeight
                                        height: root.stripRowHeight
                                        width: stripArea.width

                                        property var layerObj: modelData
                                        property real visualStart: layerObj ? layerObj.startFrame * root.pixelPerFrame : 0
                                        property real visualDuration: layerObj ? Math.max(40, layerObj.duration * root.pixelPerFrame) : 100
                                        property bool isDragging: false
                                        property int globalIdx: root.globalColorIndex(layerObj)

                                        Connections {
                                            target: layerObj
                                            function onStartFrameChanged() {
                                                if (!stripRow.isDragging)
                                                    stripRow.visualStart = stripRow.layerObj.startFrame * root.pixelPerFrame;
                                            }
                                            function onDurationChanged() {
                                                if (!stripRow.isDragging)
                                                    stripRow.visualDuration = Math.max(40, stripRow.layerObj.duration * root.pixelPerFrame);
                                            }
                                        }

                                        Component.onCompleted: {
                                            if (!layerObj) return;
                                            visualStart = layerObj.startFrame * root.pixelPerFrame;
                                            visualDuration = Math.max(40, layerObj.duration * root.pixelPerFrame);
                                        }

                                        Rectangle {
                                            id: stripBar
                                            x: stripRow.visualStart
                                            y: 4
                                            width: stripRow.visualDuration
                                            height: 20
                                            radius: 4
                                            color: Qt.alpha(root.stripColors[stripRow.globalIdx % root.stripColors.length], 0.65)
                                            border.color: { root.selectionStamp; return root.selectedLayers.indexOf(stripRow.layerObj) >= 0 ? Theme.selected : Qt.lighter(color, 1.4); }
                                            border.width: { root.selectionStamp; return root.selectedLayers.indexOf(stripRow.layerObj) >= 0 ? 2 : 1; }
                                            z: stripRow.isDragging ? 10 : 0

                                            Rectangle {
                                                id: leftEdge
                                                width: 6
                                                height: parent.height
                                                anchors.left: parent.left
                                                color: "#ffffff"
                                                opacity: 0.35
                                                radius: 4
                                            }

                                            Rectangle {
                                                id: rightEdge
                                                width: 6
                                                height: parent.height
                                                anchors.right: parent.right
                                                color: "#ffffff"
                                                opacity: 0.25
                                                radius: 4
                                            }

                                            // LEFT HANDLE
                                            MouseArea {
                                                anchors.left: parent.left
                                                anchors.top: parent.top
                                                anchors.bottom: parent.bottom
                                                width: 12
                                                cursorShape: Qt.SizeHorCursor
                                                hoverEnabled: true
                                                preventStealing: true
                                                z: 5

                                                property real startMouseX: 0
                                                property real startVisualStart: 0
                                                property real startVisualDuration: 0

                                                onPressed: mouse => {
                                                    stripRow.isDragging = true;
                                                    startMouseX = mapToItem(stripArea, mouse.x, 0).x;
                                                    startVisualStart = stripRow.visualStart;
                                                    startVisualDuration = stripRow.visualDuration;
                                                    root.selectLayer(stripRow.layerObj, false);
                                                }
                                                onPositionChanged: mouse => {
                                                    if (!pressed) return;
                                                    let mx = mapToItem(stripArea, mouse.x, 0).x;
                                                    let dx = mx - startMouseX;
                                                    let newDur = Math.max(40, startVisualDuration - dx);
                                                    let newStart = startVisualStart + (startVisualDuration - newDur);
                                                    stripRow.visualStart = Math.max(0, newStart);
                                                    stripRow.visualDuration = newDur;
                                                }
                                                onReleased: {
                                                    stripRow.isDragging = false;
                                                    commitChanges();
                                                }
                                            }

                                            // MAIN DRAG
                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.leftMargin: 12
                                                anchors.rightMargin: 12
                                                cursorShape: dragStarted ? Qt.ClosedHandCursor : Qt.ArrowCursor
                                                preventStealing: true

                                                property real startMouseX: 0
                                                property real startVisualStart: 0
                                                property bool dragStarted: false
                                                property point pressPos: Qt.point(0,0)
                                                readonly property int dragThreshold: 4
                                                property var dragData: []

                                                onPressed: mouse => {
                                                    pressPos = Qt.point(mouse.x, mouse.y);
                                                    dragStarted = false;
                                                    dragData = [];
                                                    root.selectLayer(stripRow.layerObj, mouse.modifiers & Qt.ShiftModifier);
                                                    for (var di = 0; di < root.selectedLayers.length; di++)
                                                        dragData.push({layer: root.selectedLayers[di], initialStartFrame: root.selectedLayers[di].startFrame});
                                                }
                                                onPositionChanged: mouse => {
                                                    if (!pressed) return;
                                                    if (!dragStarted) {
                                                        if (Math.abs(mouse.x - pressPos.x) < dragThreshold && Math.abs(mouse.y - pressPos.y) < dragThreshold)
                                                            return;
                                                        dragStarted = true;
                                                        stripRow.isDragging = true;
                                                        startMouseX = mapToItem(stripArea, mouse.x, 0).x;
                                                        startVisualStart = stripRow.visualStart;
                                                    }
                                                    let mx = mapToItem(stripArea, mouse.x, 0).x;
                                                    let frameDelta = (mx - startMouseX) / root.pixelPerFrame;
                                                    for (var di = 0; di < dragData.length; di++) {
                                                        var d = dragData[di];
                                                        var newFrame = Math.max(0, Math.round(d.initialStartFrame + frameDelta));
                                                        if (d.layer === stripRow.layerObj) {
                                                            stripRow.visualStart = newFrame * root.pixelPerFrame;
                                                        } else {
                                                            d.layer.startFrame = newFrame;
                                                        }
                                                    }
                                                }
                                                onReleased: {
                                                    if (dragStarted) {
                                                        stripRow.isDragging = false;
                                                        if (layerObj) {
                                                            layerObj.startFrame = root.snapFrame(stripRow.visualStart / root.pixelPerFrame);
                                                            layerObj.duration = root.snapFrame(stripRow.visualDuration / root.pixelPerFrame);
                                                        }
                                                    }
                                                    dragStarted = false;
                                                    dragData = [];
                                                }
                                            }

                                            // RIGHT HANDLE
                                            MouseArea {
                                                anchors.right: parent.right
                                                anchors.top: parent.top
                                                anchors.bottom: parent.bottom
                                                width: 12
                                                cursorShape: Qt.SizeHorCursor
                                                hoverEnabled: true
                                                preventStealing: true
                                                z: 5

                                                property real startMouseX: 0
                                                property real startVisualDuration: 0

                                                onPressed: mouse => {
                                                    stripRow.isDragging = true;
                                                    startMouseX = mapToItem(stripArea, mouse.x, 0).x;
                                                    startVisualDuration = stripRow.visualDuration;
                                                    root.selectLayer(stripRow.layerObj, false);
                                                }
                                                onPositionChanged: mouse => {
                                                    if (!pressed) return;
                                                    let mx = mapToItem(stripArea, mouse.x, 0).x;
                                                    let dx = mx - startMouseX;
                                                    stripRow.visualDuration = Math.max(40, startVisualDuration + dx);
                                                }
                                                onReleased: {
                                                    stripRow.isDragging = false;
                                                    commitChanges();
                                                }
                                            }

                                            // Context menu area on strip
                                            MouseArea {
                                                anchors.fill: parent
                                                acceptedButtons: Qt.RightButton
                                                preventStealing: false
                                                z: 6
                                                onClicked: mouse => {
                                                    root.selectLayer(stripRow.layerObj, mouse.modifiers & Qt.ShiftModifier);
                                                    stripContextMenu.stripLayer = stripRow.layerObj;
                                                    stripContextMenu.popup(mouse.x, mouse.y);
                                                }
                                            }
                                        }

                                        // Label
                                        Text {
                                            x: stripRow.visualStart + 6
                                            y: 5
                                            text: stripRow.layerObj?.name ?? ""
                                            color: "#ffffff"
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                            width: stripRow.visualDuration - 12
                                            clip: true
                                        }

                                        function commitChanges() {
                                            if (!layerObj) return;
                                            layerObj.startFrame = root.snapFrame(visualStart / root.pixelPerFrame);
                                            layerObj.duration = root.snapFrame(visualDuration / root.pixelPerFrame);
                                        }
                                    }
                                }

                                // Track drop area for inter-track moves
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton
                                    z: -1
                                }
                            }
                        }
                    }

                    // ── Global playhead ──
                    Rectangle {
                        x: (controller.timelineModel ? controller.timelineModel.currentFrame : 0) * root.pixelPerFrame
                        width: 2
                        height: parent.height
                        color: Theme.accent
                        z: 50
                    }

                    // ── Box select / empty-area deselect ──
                    MouseArea {
                        anchors.fill: parent
                        z: 100
                        acceptedButtons: Qt.LeftButton
                        preventStealing: false

                        property point startPos: Qt.point(0,0)
                        property bool selecting: false

                        Rectangle {
                            id: boxSelector
                            visible: parent.selecting
                            x: Math.min(parent.startPos.x, parent.mouseX)
                            y: Math.min(parent.startPos.y, parent.mouseY)
                            width: Math.abs(parent.mouseX - parent.startPos.x)
                            height: Math.abs(parent.mouseY - parent.startPos.y)
                            color: Qt.alpha(Theme.selected, 0.12)
                            border.color: Theme.selected
                            border.width: 1
                            z: 1000
                        }

                        function getClipY(trackIndex, clipIndex) {
                            var comp = controller.timelineModel ? controller.timelineModel.composition : null;
                            if (!comp) return 0;
                            var y = 0;
                            for (var ti = 0; ti < trackIndex; ti++) {
                                y += root.trackHeaderHeight;
                                y += comp.trackAt(ti).clipCount * root.stripRowHeight;
                            }
                            y += root.trackHeaderHeight;
                            y += clipIndex * root.stripRowHeight;
                            return y;
                        }

                        function hitTestStripBars(mx, my) {
                            var comp = controller.timelineModel ? controller.timelineModel.composition : null;
                            if (!comp) return false;
                            for (var ti = 0; ti < comp.trackCount; ti++) {
                                var track = comp.trackAt(ti);
                                for (var ci = 0; ci < track.clipCount; ci++) {
                                    var layer = track.clipAt(ci);
                                    if (!layer) continue;
                                    var barX = layer.startFrame * root.pixelPerFrame;
                                    var barY = getClipY(ti, ci) + 4;
                                    if (mx >= barX && mx <= barX + layer.duration * root.pixelPerFrame &&
                                        my >= barY && my <= barY + 20)
                                        return true;
                                }
                            }
                            return false;
                        }

                        onPressed: mouse => {
                            if (hitTestStripBars(mouse.x, mouse.y)) {
                                mouse.accepted = false;
                                return;
                            }
                            startPos = Qt.point(mouse.x, mouse.y);
                            selecting = false;
                        }

                        onPositionChanged: mouse => {
                            if (!pressed) return;
                            if (!selecting && (Math.abs(mouse.x - startPos.x) > 3 || Math.abs(mouse.y - startPos.y) > 3))
                                selecting = true;
                        }

                        onReleased: mouse => {
                            if (selecting) {
                                var selRect = Qt.rect(
                                    Math.min(startPos.x, mouse.x),
                                    Math.min(startPos.y, mouse.y),
                                    Math.abs(mouse.x - startPos.x),
                                    Math.abs(mouse.y - startPos.y)
                                );
                                selectedLayers = [];
                                var comp = controller.timelineModel?.composition;
                                if (comp) {
                                    for (var ti = 0; ti < comp.trackCount; ti++) {
                                        var track = comp.trackAt(ti);
                                        for (var ci = 0; ci < track.clipCount; ci++) {
                                            var layer = track.clipAt(ci);
                                            if (!layer) continue;
                                            var stripY = getClipY(ti, ci);
                                            var stripX = layer.startFrame * root.pixelPerFrame;
                                            if (root.rectsIntersect(selRect, Qt.rect(stripX, stripY, layer.duration * root.pixelPerFrame, root.stripRowHeight)))
                                                selectedLayers.push(layer);
                                        }
                                    }
                                }
                                selectedLayers = selectedLayers.slice();
                                selectionStamp++;
                                root.layerSelected(selectedLayers.length > 0 ? selectedLayers[0] : null);
                                root.selectionChanged(selectedLayers);
                            } else if (!mouse.modifiers) {
                                root.clearSelection();
                            }
                            selecting = false;
                        }
                    }
                }
            }
        }
    }

    // ── Strip Context Menu ──
    Menu {
        id: stripContextMenu
        property var stripLayer: null

        MenuItem {
            text: qsTr("Cut")
            onTriggered: {
                if (stripContextMenu.stripLayer) {
                    root.selectLayer(stripContextMenu.stripLayer, false);
                    root.cutSelectedLayers();
                }
            }
        }
        MenuItem {
            text: qsTr("Copy")
            onTriggered: {
                if (stripContextMenu.stripLayer) {
                    root.selectLayer(stripContextMenu.stripLayer, false);
                    root.copySelectedLayers();
                }
            }
        }
        MenuItem {
            text: qsTr("Paste")
            enabled: root.clipboardData.length > 0
            onTriggered: root.pasteClips()
        }
        MenuItem {
            text: qsTr("Duplicate")
            onTriggered: {
                if (stripContextMenu.stripLayer) {
                    root.selectLayer(stripContextMenu.stripLayer, false);
                    root.duplicateSelectedLayers();
                }
            }
        }
        MenuSeparator {}
        MenuItem {
            text: qsTr("Split At Playhead")
            onTriggered: {
                if (stripContextMenu.stripLayer) {
                    root.selectLayer(stripContextMenu.stripLayer, false);
                    root.splitAtPlayhead();
                }
            }
        }
        MenuItem {
            text: qsTr("Clear Selection")
            onTriggered: root.clearSelection()
        }
        MenuSeparator {}
                MenuItem {
                    text: qsTr("Move to Track")
                    enabled: stripContextMenu.stripLayer !== null
                    Menu {
                        id: moveTrackMenu
                        Instantiator {
                            model: controller.timelineModel && controller.timelineModel.composition ? controller.timelineModel.composition.tracks : 0
                    delegate: MenuItem {
                        text: modelData?.name ?? "Track " + (index + 1)
                        enabled: modelData !== root.findTrackForClip(stripContextMenu.stripLayer)
                        onTriggered: {
                            var layer = stripContextMenu.stripLayer;
                            var srcTrack = root.findTrackForClip(layer);
                            if (srcTrack && modelData && modelData !== srcTrack) {
                                // Remove from source, add to target
                                srcTrack.removeClip(layer);
                                modelData.addClip(layer);
                                if (root.project) root.project.captureSnapshot();
                            }
                        }
                    }
                    onObjectAdded: (idx, obj) => moveTrackMenu.insertItem(idx, obj)
                    onObjectRemoved: (idx, obj) => moveTrackMenu.removeItem(obj)
                }
                MenuSeparator {}
                MenuItem {
                    text: qsTr("+ New Track")
                    onTriggered: {
                        var layer = stripContextMenu.stripLayer;
                        var srcTrack = root.findTrackForClip(layer);
                        if (srcTrack && controller.timelineModel?.composition) {
                            var newTrack = controller.timelineModel.composition.addTrack();
                            srcTrack.removeClip(layer);
                            newTrack.addClip(layer);
                            if (root.project) root.project.captureSnapshot();
                        }
                    }
                }
            }
        }
        MenuSeparator {}
        MenuItem {
            text: qsTr("Delete")
            onTriggered: {
                if (stripContextMenu.stripLayer) {
                    root.selectLayer(stripContextMenu.stripLayer, false);
                    root.deleteSelectedLayers();
                }
            }
        }
    }

    // ── Empty track area menu ──
    Menu {
        id: emptyMenu
        property var track: null
        MenuItem { text: qsTr("Paste"); enabled: root.clipboardData.length > 0; onTriggered: root.pasteClips() }
        MenuSeparator {}
        MenuItem {
            text: qsTr("Add Track")
            onTriggered: {
                if (controller.timelineModel?.composition) {
                    controller.timelineModel.composition.addTrack();
                    if (root.project) root.project.captureSnapshot();
                }
            }
        }
    }

    // Keyboard shortcuts
    Item {
        anchors.fill: parent
        focus: true
        Keys.onDeletePressed: root.deleteSelectedLayers()
        Keys.onEscapePressed: root.clearSelection()
        Keys.onShortcutOverride: event.accepted = true
    }
}
