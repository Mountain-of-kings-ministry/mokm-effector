import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: timelineControlRoot
    color: Theme.secondary
    clip: true

    property var timelineModel: null
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
        if (timelineControlRoot.selectedLayer === null)
            timelineControlRoot.selectedLayers = [];
        else if (timelineControlRoot.selectedLayers.indexOf(timelineControlRoot.selectedLayer) < 0)
            timelineControlRoot.selectedLayers = [timelineControlRoot.selectedLayer];
    }

    function selectLayer(layer, addToSelection) {
        if (!layer) return;
        if (addToSelection) {
            var idx = timelineControlRoot.selectedLayers.indexOf(layer);
            if (idx >= 0)
                timelineControlRoot.selectedLayers.splice(idx, 1);
            else
                timelineControlRoot.selectedLayers.push(layer);
            timelineControlRoot.selectedLayers = timelineControlRoot.selectedLayers.slice();
        } else if (timelineControlRoot.selectedLayers.indexOf(layer) >= 0) {
            // preserve multi-select
        } else {
            timelineControlRoot.selectedLayers = [layer];
        }
        timelineControlRoot.selectionStamp++;
        timelineControlRoot.layerSelected(timelineControlRoot.selectedLayers.length > 0 ? timelineControlRoot.selectedLayers[0] : null);
        timelineControlRoot.selectionChanged(timelineControlRoot.selectedLayers);
    }

    function clearSelection() {
        timelineControlRoot.selectedLayers = [];
        timelineControlRoot.selectionStamp++;
        timelineControlRoot.layerSelected(null);
        timelineControlRoot.selectionChanged([]);
    }

    function rectsIntersect(r1, r2) {
        return !(r1.x + r1.width < r2.x || r2.x + r2.width < r1.x ||
                 r1.y + r1.height < r2.y || r2.y + r2.height < r1.y);
    }

    function snapFrame(v) { return Math.round(v); }

    function findTrackForClip(clip) {
        if (!timelineControlRoot.timelineModel?.composition) return null;
        var comp = timelineControlRoot.timelineModel.composition;
        for (var ti = 0; ti < comp.trackCount; ti++) {
            var t = comp.trackAt(ti);
            for (var ci = 0; ci < t.clipCount; ci++) {
                if (t.clipAt(ci) === clip) return t;
            }
        }
        return null;
    }

    function copySelectedLayers() {
        timelineControlRoot.clipboardData = [];
        for (var i = 0; i < timelineControlRoot.selectedLayers.length; i++) {
            var layer = timelineControlRoot.selectedLayers[i];
            timelineControlRoot.clipboardData.push({
                json: layer.serialize(),
                startFrame: layer.startFrame,
                duration: layer.duration
            });
        }
    }

    function cutSelectedLayers() {
        timelineControlRoot.copySelectedLayers();
        timelineControlRoot.deleteSelectedLayers();
    }

    function pasteClips() {
        if (timelineControlRoot.clipboardData.length === 0 || !timelineControlRoot.timelineModel?.composition) return;
        var comp = timelineControlRoot.timelineModel.composition;
        var targetTrack = comp.trackCount > 0 ? comp.trackAt(0) : comp.addTrack();
        var newSelection = [];
        var baseFrame = timelineControlRoot.timelineModel?.currentFrame ?? 0;
        for (var i = 0; i < timelineControlRoot.clipboardData.length; i++) {
            var data = timelineControlRoot.clipboardData[i];
            var layer = timelineControlRoot.createLayerFromJson(data.json, targetTrack);
            if (layer) {
                layer.startFrame = baseFrame + i * 10;
                layer.duration = data.duration;
                targetTrack.addClip(layer);
                newSelection.push(layer);
            }
        }
        timelineControlRoot.selectedLayers = newSelection;
        timelineControlRoot.selectionStamp++;
        timelineControlRoot.layerSelected(timelineControlRoot.selectedLayers.length > 0 ? timelineControlRoot.selectedLayers[0] : null);
        timelineControlRoot.selectionChanged(timelineControlRoot.selectedLayers);
        if (timelineControlRoot.project) timelineControlRoot.project.captureSnapshot();
    }

    function duplicateSelectedLayers() {
        if (timelineControlRoot.selectedLayers.length === 0 || !timelineControlRoot.timelineModel?.composition) return;
        var comp = timelineControlRoot.timelineModel.composition;
        var newSelection = [];
        for (var i = 0; i < timelineControlRoot.selectedLayers.length; i++) {
            var src = timelineControlRoot.selectedLayers[i];
            var track = timelineControlRoot.findTrackForClip(src);
            if (!track) continue;
            var jsonStr = src.serialize();
            var layer = timelineControlRoot.createLayerFromJson(jsonStr, track);
            if (layer) {
                layer.startFrame = src.startFrame + src.duration + 5;
                layer.duration = src.duration;
                track.addClip(layer);
                newSelection.push(layer);
            }
        }
        timelineControlRoot.selectedLayers = newSelection;
        timelineControlRoot.selectionStamp++;
        if (timelineControlRoot.project) timelineControlRoot.project.captureSnapshot();
    }

    function deleteSelectedLayers() {
        if (timelineControlRoot.selectedLayers.length === 0) return;
        for (var i = timelineControlRoot.selectedLayers.length - 1; i >= 0; i--) {
            var track = timelineControlRoot.findTrackForClip(timelineControlRoot.selectedLayers[i]);
            if (track) track.removeClip(timelineControlRoot.selectedLayers[i]);
        }
        timelineControlRoot.selectedLayers = [];
        timelineControlRoot.selectionStamp++;
        timelineControlRoot.layerSelected(null);
        if (timelineControlRoot.project) timelineControlRoot.project.captureSnapshot();
    }

    function splitAtPlayhead() {
        if (timelineControlRoot.selectedLayers.length !== 1 || !timelineControlRoot.timelineModel) return;
        var layer = timelineControlRoot.selectedLayers[0];
        var cutFrame = timelineControlRoot.timelineModel.currentFrame;
        if (cutFrame <= layer.startFrame || cutFrame >= layer.startFrame + layer.duration) return;
        var track = timelineControlRoot.findTrackForClip(layer);
        if (!track) return;
        var jsonStr = layer.serialize();
        var newLayer = timelineControlRoot.createLayerFromJson(jsonStr, track);
        if (newLayer) {
            var splitPoint = cutFrame;
            var originalEnd = layer.startFrame + layer.duration;
            layer.duration = splitPoint - layer.startFrame;
            newLayer.startFrame = splitPoint;
            newLayer.duration = originalEnd - splitPoint;
            track.addClip(newLayer);
            if (timelineControlRoot.project) timelineControlRoot.project.captureSnapshot();
        }
    }

    function createLayerFromJson(jsonStr, parent) {
        var temp;
        var obj = JSON.parse(jsonStr);
        if (obj.type === "shape")
            temp = shapeComponent.createObject(parent, {});
        else if (obj.type === "text")
            temp = textComponent.createObject(parent, {});
        else
            return null;
        temp.deserialize(jsonStr);
        return temp;
    }

    property Component shapeComponent: ShapeLayer {}
    property Component textComponent: TextLayer {}

    function globalColorIndex(layer) {
        var comp = timelineControlRoot.timelineModel ? timelineControlRoot.timelineModel.composition : null;
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
                    Layout.preferredWidth: timelineControlRoot.layerNameWidth
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
                    timelineModel: timelineControlRoot.timelineModel
                    pixelPerFrame: timelineControlRoot.pixelPerFrame
                }
            }
        }

        ScrollView {
            id: timelineScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            RowLayout {
                id: timelineContent
                width: Math.max(timelineScrollView.availableWidth, (timelineControlRoot.timelineModel?.composition?.duration ?? 0) * timelineControlRoot.pixelPerFrame + timelineControlRoot.layerNameWidth)
                height: Math.max(trackColumn.implicitHeight, timelineScrollView.availableHeight)
                spacing: 0

                // Track names column
                Item {
                    id: trackNamesColumn
                    Layout.preferredWidth: timelineControlRoot.layerNameWidth
                    Layout.fillHeight: true

                    function computeTrackY(trackIndex) {
                        var comp = timelineControlRoot.timelineModel ? timelineControlRoot.timelineModel.composition : null;
                        if (!comp) return 0;
                        var y = 0;
                        for (var ti = 0; ti < trackIndex; ti++) {
                            var t = comp.trackAt(ti);
                            y += timelineControlRoot.trackHeaderHeight + Math.max(1, t.clipCount) * timelineControlRoot.stripRowHeight;
                        }
                        return y;
                    }

                    Repeater {
                        id: trackNamesRepeater
                        model: timelineControlRoot.timelineModel && timelineControlRoot.timelineModel.composition ? timelineControlRoot.timelineModel.composition.tracks : 0
                        
                        delegate: Rectangle {
                            y: trackNamesColumn.computeTrackY(index)
                            width: timelineControlRoot.layerNameWidth
                            height: timelineControlRoot.trackHeaderHeight + Math.max(1, modelData?.clipCount ?? 0) * timelineControlRoot.stripRowHeight
                            color: "transparent"

                            Rectangle {
                                width: parent.width
                                height: timelineControlRoot.trackHeaderHeight
                                color: Theme.secondaryHover
                                border.color: Theme.border
                                border.width: 1

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
                                                if (timelineControlRoot.timelineModel?.composition) {
                                                    timelineControlRoot.timelineModel.composition.addTrack();
                                                    if (timelineControlRoot.project) timelineControlRoot.project.captureSnapshot();
                                                }
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
                        width: parent.width
                        spacing: 0

                        Repeater {
                            id: trackRowsRepeater
                            model: timelineControlRoot.timelineModel && timelineControlRoot.timelineModel.composition ? timelineControlRoot.timelineModel.composition.tracks : 0

                            delegate: Item {
                                id: trackRow
                                width: stripArea.width
                                height: timelineControlRoot.trackHeaderHeight + timelineControlRoot.stripRowHeight * Math.max(1, modelData && modelData.clipCount ? modelData.clipCount : 1)

                                property var trackObj: modelData

                                Rectangle {
                                    y: timelineControlRoot.trackHeaderHeight
                                    width: parent.width
                                    height: parent.height - timelineControlRoot.trackHeaderHeight
                                    color: Qt.alpha(Theme.secondaryHover, 0.08)

                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.RightButton
                                        onClicked: mouse => {
                                            emptyMenu.track = trackRow.trackObj;
                                            emptyMenu.popup(mouse.x, mouse.y);
                                        }
                                    }
                                }
                                
                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: Theme.border
                                    opacity: 0.5
                                }

                                Repeater {
                                    id: clipsRepeater
                                    model: trackRow.trackObj && trackRow.trackObj.clips ? trackRow.trackObj.clips : 0

                                    delegate: Item {
                                        id: stripRow
                                        y: timelineControlRoot.trackHeaderHeight + index * timelineControlRoot.stripRowHeight
                                        height: timelineControlRoot.stripRowHeight
                                        width: stripArea.width

                                        property var layerObj: modelData
                                        property real visualStart: 0
                                        property real visualDuration: 100
                                        property bool isDragging: false
                                        property int globalIdx: timelineControlRoot.globalColorIndex(layerObj)

                                        Component.onCompleted: resetFromModel()
                                        
                                        function resetFromModel() {
                                            if (!layerObj) return;
                                            visualStart = layerObj.startFrame * timelineControlRoot.pixelPerFrame;
                                            visualDuration = Math.max(40, layerObj.duration * timelineControlRoot.pixelPerFrame);
                                        }

                                        Connections {
                                            target: layerObj
                                            function onStartFrameChanged() {
                                                if (!stripRow.isDragging) resetFromModel();
                                            }
                                            function onDurationChanged() {
                                                if (!stripRow.isDragging) resetFromModel();
                                            }
                                        }

                                        Rectangle {
                                            id: stripBar
                                            x: stripRow.visualStart
                                            y: 4
                                            width: stripRow.visualDuration
                                            height: 20
                                            radius: 4
                                            color: Qt.alpha(timelineControlRoot.stripColors[stripRow.globalIdx % timelineControlRoot.stripColors.length], 0.65)
                                            border.color: { timelineControlRoot.selectionStamp; return timelineControlRoot.selectedLayers.indexOf(stripRow.layerObj) >= 0 ? Theme.selected : Qt.lighter(color, 1.4); }
                                            border.width: { timelineControlRoot.selectionStamp; return timelineControlRoot.selectedLayers.indexOf(stripRow.layerObj) >= 0 ? 2 : 1; }
                                            z: stripRow.isDragging ? 10 : 0

                                            // LEFT EDGE
                                            Rectangle {
                                                id: leftEdge
                                                width: 6
                                                height: parent.height
                                                anchors.left: parent.left
                                                color: "#ffffff"
                                                opacity: 0.35
                                                radius: 4
                                            }

                                            // RIGHT EDGE
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
                                                    timelineControlRoot.selectLayer(stripRow.layerObj, false);
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
                                                    stripRow.commitChanges();
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
                                                    timelineControlRoot.selectLayer(stripRow.layerObj, false);
                                                }
                                                onPositionChanged: mouse => {
                                                    if (!pressed) return;
                                                    let mx = mapToItem(stripArea, mouse.x, 0).x;
                                                    let dx = mx - startMouseX;
                                                    stripRow.visualDuration = Math.max(40, startVisualDuration + dx);
                                                }
                                                onReleased: {
                                                    stripRow.isDragging = false;
                                                    stripRow.commitChanges();
                                                }
                                            }

                                            // MAIN DRAG / CONTEXT MENU
                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.leftMargin: 12
                                                anchors.rightMargin: 12
                                                cursorShape: dragStarted ? Qt.ClosedHandCursor : Qt.ArrowCursor
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                preventStealing: true

                                                property real startMouseX: 0
                                                property real startVisualStart: 0
                                                property bool dragStarted: false
                                                property point pressPos: Qt.point(0,0)
                                                readonly property int dragThreshold: 4
                                                property var dragData: []

                                                onPressed: mouse => {
                                                    if (mouse.button === Qt.RightButton) {
                                                        timelineControlRoot.selectLayer(stripRow.layerObj, mouse.modifiers & Qt.ShiftModifier);
                                                        stripContextMenu.stripLayer = stripRow.layerObj;
                                                        stripContextMenu.popup(mouse.x, mouse.y);
                                                        return;
                                                    }
                                                    pressPos = Qt.point(mouse.x, mouse.y);
                                                    dragStarted = false;
                                                    dragData = [];
                                                    timelineControlRoot.selectLayer(stripRow.layerObj, mouse.modifiers & Qt.ShiftModifier);
                                                    for (var di = 0; di < timelineControlRoot.selectedLayers.length; di++)
                                                        dragData.push({layer: timelineControlRoot.selectedLayers[di], initialStartFrame: timelineControlRoot.selectedLayers[di].startFrame});
                                                }
                                                onPositionChanged: mouse => {
                                                    if (!pressed || mouse.button === Qt.RightButton) return;
                                                    if (!dragStarted) {
                                                        if (Math.abs(mouse.x - pressPos.x) < dragThreshold && Math.abs(mouse.y - pressPos.y) < dragThreshold)
                                                            return;
                                                        dragStarted = true;
                                                        stripRow.isDragging = true;
                                                        startMouseX = mapToItem(stripArea, mouse.x, 0).x;
                                                        startVisualStart = stripRow.visualStart;
                                                    }
                                                    let mx = mapToItem(stripArea, mouse.x, 0).x;
                                                    let frameDelta = (mx - startMouseX) / timelineControlRoot.pixelPerFrame;
                                                    for (var di = 0; di < dragData.length; di++) {
                                                        var d = dragData[di];
                                                        var newFrame = Math.max(0, Math.round(d.initialStartFrame + frameDelta));
                                                        if (d.layer === stripRow.layerObj) {
                                                            stripRow.visualStart = newFrame * timelineControlRoot.pixelPerFrame;
                                                        } else {
                                                            d.layer.startFrame = newFrame;
                                                        }
                                                    }
                                                }
                                                onReleased: {
                                                    if (dragStarted) {
                                                        stripRow.isDragging = false;
                                                        if (layerObj) {
                                                            layerObj.startFrame = timelineControlRoot.snapFrame(stripRow.visualStart / timelineControlRoot.pixelPerFrame);
                                                            layerObj.duration = timelineControlRoot.snapFrame(stripRow.visualDuration / timelineControlRoot.pixelPerFrame);
                                                        }
                                                    }
                                                    dragStarted = false;
                                                    dragData = [];
                                                }
                                            }

                                            Text {
                                                anchors.fill: parent
                                                anchors.leftMargin: 14
                                                anchors.rightMargin: 14
                                                text: stripRow.layerObj?.name ?? ""
                                                color: "#ffffff"
                                                font.pixelSize: 10
                                                elide: Text.ElideRight
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                        }

                                        function commitChanges() {
                                            if (!layerObj) return;
                                            layerObj.startFrame = timelineControlRoot.snapFrame(visualStart / timelineControlRoot.pixelPerFrame);
                                            layerObj.duration = timelineControlRoot.snapFrame(visualDuration / timelineControlRoot.pixelPerFrame);
                                            Qt.callLater(resetFromModel);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Global playhead ──
                    Rectangle {
                        x: (timelineControlRoot.timelineModel ? timelineControlRoot.timelineModel.currentFrame : 0) * timelineControlRoot.pixelPerFrame
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
                            var comp = timelineControlRoot.timelineModel ? timelineControlRoot.timelineModel.composition : null;
                            if (!comp) return 0;
                            var y = 0;
                            for (var ti = 0; ti < trackIndex; ti++) {
                                var t = comp.trackAt(ti);
                                y += timelineControlRoot.trackHeaderHeight + Math.max(1, t.clipCount) * timelineControlRoot.stripRowHeight;
                            }
                            y += timelineControlRoot.trackHeaderHeight + clipIndex * timelineControlRoot.stripRowHeight;
                            return y;
                        }

                        function hitTestStripBars(mx, my) {
                            var comp = timelineControlRoot.timelineModel ? timelineControlRoot.timelineModel.composition : null;
                            if (!comp) return false;
                            for (var ti = 0; ti < comp.trackCount; ti++) {
                                var track = comp.trackAt(ti);
                                for (var ci = 0; ci < track.clipCount; ci++) {
                                    var layer = track.clipAt(ci);
                                    if (!layer) continue;
                                    var barX = layer.startFrame * timelineControlRoot.pixelPerFrame;
                                    var barY = getClipY(ti, ci) + 4;
                                    if (mx >= barX && mx <= barX + layer.duration * timelineControlRoot.pixelPerFrame &&
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
                                var newSelection = [];
                                var comp = timelineControlRoot.timelineModel?.composition;
                                if (comp) {
                                    for (var ti = 0; ti < comp.trackCount; ti++) {
                                        var track = comp.trackAt(ti);
                                        for (var ci = 0; ci < track.clipCount; ci++) {
                                            var layer = track.clipAt(ci);
                                            if (!layer) continue;
                                            var stripY = getClipY(ti, ci);
                                            var stripX = layer.startFrame * timelineControlRoot.pixelPerFrame;
                                            if (timelineControlRoot.rectsIntersect(selRect, Qt.rect(stripX, stripY, layer.duration * timelineControlRoot.pixelPerFrame, timelineControlRoot.stripRowHeight)))
                                                newSelection.push(layer);
                                        }
                                    }
                                }
                                timelineControlRoot.selectedLayers = newSelection;
                                timelineControlRoot.selectionStamp++;
                                timelineControlRoot.layerSelected(timelineControlRoot.selectedLayers.length > 0 ? timelineControlRoot.selectedLayers[0] : null);
                                timelineControlRoot.selectionChanged(timelineControlRoot.selectedLayers);
                            } else if (!(mouse.modifiers & Qt.ShiftModifier)) {
                                timelineControlRoot.clearSelection();
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
                    timelineControlRoot.selectLayer(stripContextMenu.stripLayer, false);
                    timelineControlRoot.cutSelectedLayers();
                }
            }
        }
        MenuItem {
            text: qsTr("Copy")
            onTriggered: {
                if (stripContextMenu.stripLayer) {
                    timelineControlRoot.selectLayer(stripContextMenu.stripLayer, false);
                    timelineControlRoot.copySelectedLayers();
                }
            }
        }
        MenuItem {
            text: qsTr("Paste")
            enabled: timelineControlRoot.clipboardData.length > 0
            onTriggered: timelineControlRoot.pasteClips()
        }
        MenuItem {
            text: qsTr("Duplicate")
            onTriggered: {
                if (stripContextMenu.stripLayer) {
                    timelineControlRoot.selectLayer(stripContextMenu.stripLayer, false);
                    timelineControlRoot.duplicateSelectedLayers();
                }
            }
        }
        MenuSeparator {}
        MenuItem {
            text: qsTr("Split At Playhead")
            onTriggered: {
                if (stripContextMenu.stripLayer) {
                    timelineControlRoot.selectLayer(stripContextMenu.stripLayer, false);
                    timelineControlRoot.splitAtPlayhead();
                }
            }
        }
        MenuItem {
            text: qsTr("Clear Selection")
            onTriggered: timelineControlRoot.clearSelection()
        }
        MenuSeparator {}
        MenuItem {
            text: qsTr("Move to Track")
            enabled: stripContextMenu.stripLayer !== null
            Menu {
                id: moveTrackMenu
                Instantiator {
                    model: timelineControlRoot.timelineModel && timelineControlRoot.timelineModel.composition ? timelineControlRoot.timelineModel.composition.tracks : 0
                    delegate: MenuItem {
                        text: modelData?.name ?? "Track " + (index + 1)
                        enabled: modelData !== timelineControlRoot.findTrackForClip(stripContextMenu.stripLayer)
                        onTriggered: {
                            var layer = stripContextMenu.stripLayer;
                            var srcTrack = timelineControlRoot.findTrackForClip(layer);
                            if (srcTrack && modelData && modelData !== srcTrack) {
                                srcTrack.removeClip(layer);
                                modelData.addClip(layer);
                                if (timelineControlRoot.project) timelineControlRoot.project.captureSnapshot();
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
                        var srcTrack = timelineControlRoot.findTrackForClip(layer);
                        if (srcTrack && timelineControlRoot.timelineModel?.composition) {
                            var newTrack = timelineControlRoot.timelineModel.composition.addTrack();
                            srcTrack.removeClip(layer);
                            newTrack.addClip(layer);
                            if (timelineControlRoot.project) timelineControlRoot.project.captureSnapshot();
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
                    timelineControlRoot.selectLayer(stripContextMenu.stripLayer, false);
                    timelineControlRoot.deleteSelectedLayers();
                }
            }
        }
    }

    // ── Empty track area menu ──
    Menu {
        id: emptyMenu
        property var track: null
        MenuItem { text: qsTr("Paste"); enabled: timelineControlRoot.clipboardData.length > 0; onTriggered: timelineControlRoot.pasteClips() }
        MenuSeparator {}
        MenuItem {
            text: qsTr("Add Track")
            onTriggered: {
                if (timelineControlRoot.timelineModel?.composition) {
                    timelineControlRoot.timelineModel.composition.addTrack();
                    if (timelineControlRoot.project) timelineControlRoot.project.captureSnapshot();
                }
            }
        }
    }

    // Keyboard shortcuts
    Item {
        anchors.fill: parent
        focus: true
        Keys.onDeletePressed: timelineControlRoot.deleteSelectedLayers()
        Keys.onEscapePressed: timelineControlRoot.clearSelection()
        Keys.onShortcutOverride: event.accepted = true
    }
}
