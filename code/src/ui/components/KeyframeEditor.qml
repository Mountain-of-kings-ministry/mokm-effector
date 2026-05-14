import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root
    color: Theme.background
    clip: true

    property var timelineModel: null
    property var selectedObject: null
    property real pixelPerFrame: 8
    property string selectedProperty: "opacity"
    property int selectedKeyframeFrame: -1
    property string mode: "dope"

    // ── Target resolution ──
    readonly property var _target: {
        if (!selectedObject)
            return null;
        if (selectedObject.element !== undefined)
            return selectedObject.element;
        if (selectedObject.opacity !== undefined)
            return selectedObject;
        if (selectedObject.tracks !== undefined)
            return selectedObject;
        return null;
    }

    readonly property var _comp: timelineModel ? timelineModel.composition : null
    readonly property int _duration: _comp ? _comp.duration : 150
    readonly property int _kfStamp: root.timelineModel ? root.timelineModel.keyframesStamp : 0
    property int _dummyKf: root._kfStamp

    // ── Dynamic property list ──
    property var _props: []
    property var _propLabels: []

    function _getProperties(obj) {
        if (!obj)
            return [[], []];

        let keys = [];
        let labels = [];

        // Add '[ All ]' at index 0
        keys.push("all");
        labels.push("[ All ]");

        // Check for EffectInstance (has pluginId and parameters)
        if (obj.pluginId !== undefined && obj.parameters !== undefined) {
            let pKeys = Object.keys(obj.parameters);
            for (let i = 0; i < pKeys.length; i++) {
                keys.push(pKeys[i]);
                let info = obj.parameterInfo ? obj.parameterInfo(pKeys[i]) : null;
                labels.push(info ? info.label : ("Param " + pKeys[i]));
            }
        } else if (obj.tracks !== undefined) {
            let p = ["opacity", "offsetX", "offsetY", "rotation", "scaleX", "scaleY", "anchorX", "anchorY", "visible"];
            let l = ["Opacity", "Offset X", "Offset Y", "Rotation", "Scale X", "Scale Y", "Anchor X", "Anchor Y", "Visible"];
            keys = keys.concat(p);
            labels = labels.concat(l);
        } else if (obj.strips !== undefined && obj.tracks === undefined) {
            let p = ["opacity", "pan", "enabled", "mute", "solo", "looping"];
            let l = ["Opacity", "Pan", "Enabled", "Mute", "Solo", "Looping"];
            keys = keys.concat(p);
            labels = labels.concat(l);
        } else if (obj.element !== undefined) {
            let res = _getProperties(obj.element);
            keys = keys.concat(res[0].filter(k => k !== "all"));
            labels = labels.concat(res[1].filter(l => l !== "[ All ]"));
        } else {
            let p = ["opacity", "x", "y", "rotation", "scaleX", "scaleY", "blurRadius", "blendMode"];
            let l = ["Opacity", "Position X", "Position Y", "Rotation", "Scale X", "Scale Y", "Blur", "Blend Mode"];
            keys = keys.concat(p);
            labels = labels.concat(l);
        }
        return [keys, labels];
    }

    function _updateProps() {
        var p = _getProperties(_target);
        _props = p[0];
        _propLabels = p[1];
        if (_props.length > 0 && _props.indexOf(selectedProperty) < 0)
            selectedProperty = _props[0];
    }

    on_TargetChanged: _updateProps()
    Component.onCompleted: _updateProps()

    function _hasKeyframes(prop) {
        return _target && timelineModel && timelineModel.keyframeFrames(_target, prop).length > 0;
    }

    function _keyframesFor(prop) {
        var dummy = root._dummyKf;
        if (!_target || !timelineModel)
            return [];
        return timelineModel.keyframeFrames(_target, prop);
    }

    function _keyframeDataFor(prop) {
        var dummy = root._dummyKf;
        if (!_target || !timelineModel)
            return [];
        return timelineModel.getKeyframeData(_target, prop);
    }

    function _easeValue(t, easing) {
        if (easing === 0)
            return t;
        if (easing === 1)
            return t * t;
        if (easing === 2)
            return t * (2 - t);
        if (easing === 3)
            return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
        return t;
    }

    function goToGraph() {
        if (_props.indexOf(selectedProperty) >= 0)
            mode = "graph";
    }

    function goToDope() {
        mode = "dope";
    }

    function _buildSearchableItems() {
        var items = [];
        if (!_comp)
            return items;
        for (var li = 0; li < _comp.layerCount(); li++) {
            var tl = _comp.layerAt(li);
            items.push({
                object: tl,
                name: tl.name,
                depth: 0,
                typeName: "Layer"
            });
            for (var ti = 0; ti < tl.trackCount; ti++) {
                var tr = tl.trackAt(ti);
                items.push({
                    object: tr,
                    name: tr.name,
                    depth: 1,
                    typeName: "Track"
                });
                for (var si = 0; si < tr.stripCount; si++) {
                    var st = tr.stripAt(si);
                    var elName = st.element ? st.element.name : "?";
                    items.push({
                        object: st,
                        name: st.name + " (" + elName + ")",
                        depth: 2,
                        typeName: "Strip"
                    });
                }
            }
        }
        return items;
    }

    // ── Toolbar ──
    Rectangle {
        id: toolbar
        anchors.top: parent.top
        width: parent.width
        height: 36
        z: 10
        color: Theme.secondary
        border.color: Theme.border

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 8
            spacing: 8

            Button {
                id: selectBtn
                text: _target ? (selectedObject ? selectedObject.name || _target.name || "Selected" : "Select…") : "Select…"
                height: 26
                flat: true
                onClicked: selectPopup.open()
            }

            Button {
                text: mode === "graph" ? "Dope Sheet" : "Add Key"
                height: 26
                flat: true
                enabled: mode !== "graph"
                onClicked: {
                    if (!_target || !timelineModel || !selectedProperty)
                        return;
                    var frame = timelineModel.currentFrame;
                    var val = _target[selectedProperty];
                    if (val !== undefined) {
                        timelineModel.addKeyframe(_target, selectedProperty, frame, val);
                        selectedKeyframeFrame = frame;
                    }
                }
            }

            Button {
                text: "Delete"
                height: 26
                flat: true
                enabled: mode === "dope" && selectedKeyframeFrame >= 0
                onClicked: {
                    if (selectedKeyframeFrame >= 0 && _target && timelineModel) {
                        timelineModel.removeKeyframe(_target, selectedProperty, selectedKeyframeFrame);
                        selectedKeyframeFrame = -1;
                    }
                }
            }
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (!_target)
                    return "No target selected";
                var ml = mode === "graph" ? " [Graph]" : "";
                return (_target.name || "?") + " \u2014 " + selectedProperty + ml;
            }
            color: Theme.mutedForeground
            font.pixelSize: 11
        }
    }

    // ── Select Popup (searchable tree) ──
    Popup {
        id: selectPopup
        x: selectBtn.x
        y: toolbar.height
        width: 300
        height: 400
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property var items: []
        onAboutToShow: {
            searchField.text = "";
            items = _buildSearchableItems();
            rebuildFilter();
        }

        ListModel {
            id: filterModel
        }

        function rebuildFilter() {
            filterModel.clear();
            var q = searchField.text.toLowerCase();
            for (var i = 0; i < items.length; i++) {
                var it = items[i];
                if (!q || it.name.toLowerCase().indexOf(q) >= 0)
                    filterModel.append(it);
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.background
            border.color: Theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: "Search\u2026"
                    onTextChanged: selectPopup.rebuildFilter()
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: filterModel
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 28
                        color: ma.containsMouse ? Theme.muted : "transparent"

                        RowLayout {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 4 + model.depth * 16
                            spacing: 6

                            Text {
                                text: model.depth === 0 ? "\uD83D\uDCC1" : model.depth === 1 ? "\uD83D\uDCCB" : "\uD83C\uDF9E"
                                font.pixelSize: 10
                            }

                            Text {
                                text: model.name
                                color: Theme.foreground
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "(" + model.typeName + ")"
                                color: Theme.mutedForeground
                                font.pixelSize: 9
                            }
                        }

                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                selectedObject = model.object;
                                selectPopup.close();
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Body ──
    RowLayout {
        anchors.top: toolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 0

        // Left: Property list
        Rectangle {
            Layout.preferredWidth: 180
            Layout.fillHeight: true
            color: Theme.secondary
            border.color: Theme.border

            Column {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                Text {
                    text: "Properties"
                    color: Theme.foreground
                    font.pixelSize: 12
                    font.bold: true
                    height: 24
                }

                Repeater {
                    model: _props.length > 0 ? _props.length : 0

                    delegate: Rectangle {
                        width: parent.width
                        height: 28
                        radius: 4
                        color: selectedProperty === _props[index] ? Theme.selected : (ma.containsMouse ? Theme.muted : "transparent")

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            spacing: 8

                            Rectangle {
                                width: 10
                                height: 10
                                radius: 5
                                color: _hasKeyframes(_props[index]) ? Theme.accent : Theme.mutedForeground
                            }

                            Text {
                                text: _propLabels[index]
                                color: selectedProperty === _props[index] ? "#fff" : Theme.foreground
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                selectedProperty = _props[index];
                                selectedKeyframeFrame = -1;
                                mode = "dope";
                            }
                        }
                    }
                }
            }
        }

        // ── Dope Sheet ──
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.background
            clip: true
            visible: mode === "dope"

            Flickable {
                anchors.fill: parent
                contentWidth: Math.max(_duration * pixelPerFrame + 40, parent.width)
                contentHeight: parent.height
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Rectangle {
                    id: ruler
                    y: 0
                    width: parent.width
                    height: 28
                    color: Theme.secondary
                    border.color: Theme.border
                    z: 5

                    Repeater {
                        model: Math.ceil(_duration / 10) + 1
                        delegate: Item {
                            x: index * 10 * pixelPerFrame
                            y: 0
                            width: 1
                            height: ruler.height
                            visible: x <= parent.width
                            Rectangle {
                                width: 1
                                height: parent.height
                                color: Theme.border
                            }
                            Text {
                                x: 4
                                y: 2
                                text: (index * 10).toString()
                                color: Theme.mutedForeground
                                font.pixelSize: 9
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function (m) {
                            if (!timelineModel)
                                return;
                            var f = Math.round(m.x / pixelPerFrame);
                            timelineModel.currentFrame = Math.max(0, Math.min(f, _duration - 1));
                        }
                    }
                }

                // Rectangle {
                //     y: ruler.height; width: parent.width; height: parent.height - ruler.height
                //     color: Theme.background

                //     Repeater {
                //         model: Math.ceil(_duration / 10) + 1
                //         delegate: Rectangle {
                //             x: index * 10 * pixelPerFrame; y: 0; width: 1; height: parent.height
                //             color: index % 5 === 0 ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04)
                //             visible: x <= (_duration * pixelPerFrame)
                //         }
                //     }

                //     Rectangle { y: 0; width: parent.width; height: 1; color: Theme.border }

                //     // Click to add (BEHIND diamonds)
                //     MouseArea {
                //         anchors.fill: parent; acceptedButtons: Qt.LeftButton
                //         onClicked: function (m) {
                //             if (!_target || !timelineModel || !selectedProperty) return;
                //             var f = Math.round(m.x / pixelPerFrame);
                //             f = Math.max(0, Math.min(f, _duration - 1));
                //             var v = _target[selectedProperty];
                //             if (v !== undefined) {
                //                 timelineModel.addKeyframe(_target, selectedProperty, f, v);
                //                 selectedKeyframeFrame = f;
                //             }
                //         }
                //     }

                //                 // Bezier Handles
                //                 Repeater {
                //                     model: kf.easing === 4 ? [0, 1] : [] // 0:In, 1:Out
                //                     delegate: Rectangle {
                //                         property bool isOut: modelData === 1
                //                         x: (isOut ? kf.handleOut.x : kf.handleIn.x) * root.pixelPerFrame
                //                         y: graphArea.valueToY(kf.value + (isOut ? kf.handleOut.y : kf.handleIn.y)) - graphArea.valueToY(kf.value)
                //                         width: 8; height: 8; radius: 4
                //                         color: "#4ade80"
                //                         MouseArea {
                //                             anchors.fill: parent
                //                             drag.target: parent
                //                             onPositionChanged: {
                //                                 if (drag.active) {
                //                                     let newTime = parent.x / root.pixelPerFrame
                //                                     let newVal = graphArea.yToValue(graphArea.valueToY(kf.value) + parent.y) - kf.value
                //                                     if (isOut) kf.handleOut = Qt.point(newTime, newVal)
                //                                     else kf.handleIn = Qt.point(newTime, newVal)
                //                                     gCanvas.requestPaint()
                //                                 }
                //                             }
                //                         }
                //                     }
                //                 }

                //                 // Keyframe node
                //                 Rectangle {
                //                     width: 12; height: 12; rotation: 45; radius: 2
                //                     anchors.centerIn: parent
                //                     color: modelData === selectedKeyframeFrame ? Theme.accent : "#fff"

                //                     MouseArea {
                //                         anchors.fill: parent
                //                         acceptedButtons: Qt.LeftButton | Qt.RightButton
                //                         onClicked: function(mouse) {
                //                             selectedKeyframeFrame = modelData
                //                             if (mouse.button === Qt.RightButton) easingMenu.open()
                //                         }
                //                     }
                //                 }
                //             }
                //         }
                //     }
                // }

                Rectangle {
                    y: ruler.height
                    width: parent.width
                    height: parent.height - ruler.height
                    color: Theme.background

                    // Vertical grid lines
                    Repeater {
                        model: Math.ceil(_duration / 10) + 1
                        delegate: Rectangle {
                            x: index * 10 * pixelPerFrame
                            y: 0
                            width: 1
                            height: parent.height
                            color: index % 5 === 0 ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
                            visible: x <= (_duration * pixelPerFrame)
                        }
                    }

                    Rectangle {
                        y: 0
                        width: parent.width
                        height: 1
                        color: Theme.border
                    }

                    // Click to add keyframe
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: function (m) {
                            if (!_target || !timelineModel || !selectedProperty)
                                return;
                            var f = Math.round(m.x / pixelPerFrame);
                            f = Math.max(0, Math.min(f, _duration - 1));
                            var v = _target[selectedProperty];
                            if (v !== undefined) {
                                timelineModel.addKeyframe(_target, selectedProperty, f, v);
                                selectedKeyframeFrame = f;
                            }
                        }
                    }

                    // ==================== KEYFRAMES REPEATER ====================
                    Repeater {
                        model: _keyframesFor(selectedProperty)

                        delegate: Item {
                            id: kfDelegate
                            x: modelData * pixelPerFrame
                            y: 0
                            width: 1
                            height: parent.height

                            // Bezier Handles (only visible in Bezier mode)
                            Repeater {
                                model: (timelineModel.getKeyframe(root._target, root.selectedProperty, modelData).easing === 4) ? 2 : 0

                                delegate: Rectangle {
                                    property bool isOut: index === 1
                                    property var kf: timelineModel.getKeyframe(root._target, root.selectedProperty, modelData)

                                    x: (isOut ? kf.handleOut.x : kf.handleIn.x) * root.pixelPerFrame - 4
                                    y: 60 + (isOut ? kf.handleOut.y : kf.handleIn.y) * -80   // adjust multiplier based on your visual scale

                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: "#4ade80"
                                    border.color: "white"
                                    border.width: 1

                                    MouseArea {
                                        anchors.fill: parent
                                        drag.target: parent
                                        drag.axis: Drag.XAndY

                                        onReleased: {
                                            if (!kf)
                                                return;
                                            let newTime = (parent.x + 4) / root.pixelPerFrame;
                                            let newVal = (60 - parent.y) / 80;   // reverse the scaling

                                            if (isOut)
                                                kf.handleOut = Qt.point(newTime, newVal);
                                            else
                                                kf.handleIn = Qt.point(newTime, newVal);

                                            gCanvas.requestPaint();
                                        }
                                    }
                                }
                            }

                            // Keyframe Diamond
                            Rectangle {
                                width: 12
                                height: 12
                                rotation: 45
                                radius: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 60   // adjust this to match your dope sheet row height
                                color: modelData === selectedKeyframeFrame ? Theme.accent : "#ffffff"

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                                    onClicked: function (mouse) {
                                        selectedKeyframeFrame = modelData;
                                        if (mouse.button === Qt.RightButton) {
                                            easingMenu.popup();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Easing Context Menu
                Menu {
                    id: easingMenu
                    MenuItem {
                        text: "Linear"
                        onTriggered: if (selectedKeyframeFrame !== -1) {
                            var kf = timelineModel.getKeyframe(root._target, root.selectedProperty, selectedKeyframeFrame);
                            kf.easing = 0;
                        }
                    }
                    MenuItem {
                        text: "Ease In"
                        onTriggered: if (selectedKeyframeFrame !== -1) {
                            var kf = timelineModel.getKeyframe(root._target, root.selectedProperty, selectedKeyframeFrame);
                            kf.easing = 1;
                        }
                    }
                    MenuItem {
                        text: "Ease Out"
                        onTriggered: if (selectedKeyframeFrame !== -1) {
                            var kf = timelineModel.getKeyframe(root._target, root.selectedProperty, selectedKeyframeFrame);
                            kf.easing = 2;
                        }
                    }
                    MenuItem {
                        text: "Bezier"
                        onTriggered: if (selectedKeyframeFrame !== -1) {
                            var kf = timelineModel.getKeyframe(root._target, root.selectedProperty, selectedKeyframeFrame);
                            kf.easing = 4;
                        }
                    }
                }

                Rectangle {
                    id: playhead
                    x: (timelineModel ? timelineModel.currentFrame : 0) * pixelPerFrame - 1
                    y: 0
                    width: 2
                    height: parent.height
                    z: 20
                    color: Theme.error
                    Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: -6
                        color: Theme.error
                    }
                    MouseArea {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 20
                        height: parent.height
                        cursorShape: Qt.SizeHorCursor
                        drag.target: parent
                        drag.axis: Drag.XAxis
                        drag.minimumX: 0
                        drag.maximumX: (_duration - 1) * pixelPerFrame
                        onPositionChanged: {
                            if (drag.active && timelineModel) {
                                var f = Math.round(playhead.x / pixelPerFrame);
                                timelineModel.currentFrame = Math.max(0, Math.min(f, _duration - 1));
                            }
                        }
                    }
                }
            }
        }

        // ── Graph Editor ──
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.background
            clip: true
            visible: mode === "graph"

            Item {
                id: graphArea
                anchors.fill: parent
                anchors.margins: 24
                anchors.topMargin: 12
                anchors.bottomMargin: 28

                property var kfData: {
                    var dummy = root._dummyKf;
                    if (!root.selectedProperty || !root._target || !root.timelineModel)
                        return [];
                    return root.timelineModel.getKeyframeData(root._target, root.selectedProperty);
                }

                property real minVal: 0
                property real maxVal: 1

                function recalcBounds() {
                    var d = kfData;
                    if (d.length === 0) {
                        minVal = 0;
                        maxVal = 1;
                        return;
                    }
                    var mn = d[0].value, mx = d[0].value;
                    for (var i = 1; i < d.length; i++) {
                        if (d[i].value < mn)
                            mn = d[i].value;
                        if (d[i].value > mx)
                            mx = d[i].value;
                    }
                    var rng = mx - mn;
                    if (rng === 0)
                        rng = 1;
                    var pad = rng * 0.2;
                    minVal = mn - pad;
                    maxVal = mx + pad;
                }

                function frameToX(fr) {
                    return (fr / (_duration - 1)) * width;
                }
                function valueToY(v) {
                    var r = maxVal - minVal;
                    if (r === 0)
                        r = 1;
                    return height - ((v - minVal) / r) * height;
                }
                function xToFrame(x) {
                    return Math.round((x / width) * (_duration - 1));
                }
                function yToValue(y) {
                    return minVal + (1 - y / height) * (maxVal - minVal);
                }

                onKfDataChanged: recalcBounds()
                Component.onCompleted: recalcBounds()

                Canvas {
                    id: gCanvas
                    anchors.fill: parent
                    antialiasing: true

                    Connections {
                        target: root
                        function onSelectedKeyframeFrameChanged() {
                            gCanvas.requestPaint();
                        }
                        function on_DummyKfChanged() {
                            gCanvas.requestPaint();
                        }
                        function on_DurationChanged() {
                            gCanvas.requestPaint();
                        }
                    }
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        if (!ctx)
                            return;
                        var w = width, h = height;
                        ctx.clearRect(0, 0, w, h);

                        // Grid rendering
                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.06);
                        ctx.lineWidth = 1;
                        for (var gi = 0; gi <= 5; gi++) {
                            var gy = (gi / 5) * h;
                            ctx.beginPath();
                            ctx.moveTo(0, gy);
                            ctx.lineTo(w, gy);
                            ctx.stroke();
                            var val = graphArea.maxVal - (gi / 5) * (graphArea.maxVal - graphArea.minVal);
                            ctx.fillStyle = Theme.mutedForeground;
                            ctx.font = "9px monospace";
                            ctx.textAlign = "left";
                            ctx.fillText(val.toFixed(1), 2, gy + 3);
                        }
                        for (gi = 0; gi <= 10; gi++) {
                            var gx = (gi / 10) * w;
                            ctx.beginPath();
                            ctx.moveTo(gx, 0);
                            ctx.lineTo(gx, h);
                            ctx.stroke();
                            var fr = Math.round((gi / 10) * (_duration - 1));
                            ctx.textAlign = "center";
                            ctx.fillStyle = Theme.mutedForeground;
                            ctx.fillText(fr.toString(), gx, h + 14);
                        }

                        // Identify properties to render
                        var propsToRender = (root.selectedProperty === "all") ? _props.filter(p => p !== "all") : [root.selectedProperty];
                        var colors = ["#4ade80", "#fbbf24", "#f87171", "#60a5fa", "#a78bfa"];

                        for (var pIdx = 0; pIdx < propsToRender.length; pIdx++) {
                            var prop = propsToRender[pIdx];
                            var d = root.timelineModel.getKeyframeData(root._target, prop);
                            if (d.length === 0)
                                continue;

                            var sorted = d.slice();
                            sorted.sort(function (a, b) {
                                return a.frame - b.frame;
                            });

                            ctx.strokeStyle = colors[pIdx % colors.length];
                            ctx.lineWidth = 2;
                            ctx.beginPath();
                            for (var si = 0; si < sorted.length; si++) {
                                var px = graphArea.frameToX(sorted[si].frame);
                                var py = graphArea.valueToY(sorted[si].value);
                                if (si === 0) {
                                    ctx.moveTo(px, py);
                                } else {
                                    var prev = sorted[si - 1];
                                    var segFrames = sorted[si].frame - prev.frame;
                                    if (segFrames <= 0) {
                                        ctx.lineTo(px, py);
                                    } else {
                                        var steps = segFrames * 4;
                                        for (var s = 0; s <= steps; s++) {
                                            var t = s / steps;
                                            // Simple eased Y mapping for now
                                            var easedT = root._easeValue(t, prev.easing);
                                            var ix = graphArea.frameToX(prev.frame + t * segFrames);
                                            var iy = graphArea.valueToY(prev.value + (sorted[si].value - prev.value) * easedT);
                                            ctx.lineTo(ix, iy);
                                        }
                                    }
                                }
                            }
                            ctx.stroke();
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    property int hitIdx: -1
                    property real dragStartY: 0

                    function hitTest(mx, my) {
                        var d = graphArea.kfData;
                        for (var i = 0; i < d.length; i++) {
                            var px = graphArea.frameToX(d[i].frame);
                            var py = graphArea.valueToY(d[i].value);
                            var dx = mx - px, dy = my - py;
                            if (dx * dx + dy * dy < 100)
                                return i;
                        }
                        return -1;
                    }

                    function segmentHit(mx, my) {
                        var d = graphArea.kfData;
                        if (d.length < 2)
                            return -1;
                        var s = d.slice();
                        s.sort(function (a, b) {
                            return a.frame - b.frame;
                        });
                        for (var i = 0; i < s.length - 1; i++) {
                            var x1 = graphArea.frameToX(s[i].frame);
                            var y1 = graphArea.valueToY(s[i].value);
                            var x2 = graphArea.frameToX(s[i + 1].frame);
                            var y2 = graphArea.valueToY(s[i + 1].value);
                            var dx = x2 - x1, dy = y2 - y1;
                            var len = Math.sqrt(dx * dx + dy * dy);
                            if (len < 1)
                                continue;
                            var t = ((mx - x1) * dx + (my - y1) * dy) / (len * len);
                            t = Math.max(0, Math.min(1, t));
                            var nx = x1 + t * dx, ny = y1 + t * dy;
                            var dist = Math.sqrt((mx - nx) * (mx - nx) + (my - ny) * (my - ny));
                            if (dist < 15)
                                return i;
                        }
                        return -1;
                    }

                    cursorShape: hitIdx >= 0 ? Qt.SizeAllCursor : Qt.ArrowCursor

                    onPressed: function (m) {
                        var idx = hitTest(m.x, m.y);
                        if (idx >= 0) {
                            hitIdx = idx;
                            dragStartY = m.y;
                            root.selectedKeyframeFrame = graphArea.kfData[idx].frame;
                            return;
                        }

                        var seg = segmentHit(m.x, m.y);
                        if (seg >= 0 && root._target && root.timelineModel && root.selectedProperty) {
                            var sd = graphArea.kfData.slice();
                            sd.sort(function (a, b) {
                                return a.frame - b.frame;
                            });
                            var pe = sd[seg];
                            var newEasing = (pe.easing + 1) % 4;
                            root.timelineModel.setKeyframeEasing(root._target, root.selectedProperty, pe.frame, newEasing);
                            gCanvas.requestPaint();
                        }
                    }

                    onPositionChanged: function (m) {
                        if (!(m.buttons & Qt.LeftButton) || hitIdx < 0)
                            return;
                        if (!root._target || !root.timelineModel || !root.selectedProperty)
                            return;
                        var d = graphArea.kfData;
                        if (hitIdx >= d.length)
                            return;
                        var frame = d[hitIdx].frame;
                        var amp = graphArea.height;
                        var delta = (dragStartY - m.y) / amp;
                        var valRange = graphArea.maxVal - graphArea.minVal;
                        var newVal = d[hitIdx].value + delta * valRange;
                        newVal = Math.max(graphArea.minVal, Math.min(graphArea.maxVal, newVal));
                        root.timelineModel.removeKeyframe(root._target, root.selectedProperty, frame);
                        root.timelineModel.addKeyframe(root._target, root.selectedProperty, frame, newVal);
                        dragStartY = m.y;
                    }

                    onReleased: function (m) {
                        hitIdx = -1;
                    }
                    onDoubleClicked: function (m) {
                        if (hitTest(m.x, m.y) < 0)
                            goToDope();
                    }
                }
            }
        }
    }
}
