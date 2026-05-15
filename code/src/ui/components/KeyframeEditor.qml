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
        if (!selectedObject) return null;
        if (selectedObject.element !== undefined) return selectedObject.element;
        if (selectedObject.opacity !== undefined) return selectedObject;
        if (selectedObject.tracks !== undefined) return selectedObject;
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
        if (!obj) return [[], []];
        
        let keys = ["all"];
        let labels = ["[ All ]"];

        if (obj.pluginId !== undefined && obj.parameters !== undefined) {
            let pKeys = Object.keys(obj.parameters);
            for (let i = 0; i < pKeys.length; i++) {
                keys.push(pKeys[i]);
                let info = obj.parameterInfo ? obj.parameterInfo(pKeys[i]) : null;
                labels.push(info ? info.label : ("Param " + pKeys[i]));
            }
        } else if (obj.tracks !== undefined) {
            let p = ["opacity","offsetX","offsetY","rotation","scaleX","scaleY","anchorX","anchorY","visible"];
            let l = ["Opacity","Offset X","Offset Y","Rotation","Scale X","Scale Y","Anchor X","Anchor Y","Visible"];
            keys = keys.concat(p); labels = labels.concat(l);
        } else if (obj.strips !== undefined && obj.tracks === undefined) {
            let p = ["opacity","pan","enabled","mute","solo","looping"];
            let l = ["Opacity","Pan","Enabled","Mute","Solo","Looping"];
            keys = keys.concat(p); labels = labels.concat(l);
        } else if (obj.element !== undefined) {
             let res = _getProperties(obj.element);
             keys = keys.concat(res[0].filter(function(k) { return k !== "all"; }));
             labels = labels.concat(res[1].filter(function(l) { return l !== "[ All ]"; }));
        } else {
             let p = ["opacity","x","y","rotation","scaleX","scaleY","blurRadius","blendMode"];
             let l = ["Opacity","Position X","Position Y","Rotation","Scale X","Scale Y","Blur","Blend Mode"];
             keys = keys.concat(p); labels = labels.concat(l);
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
        if (!_target || !timelineModel) return [];
        if (prop === "all") {
            var frames = [];
            for (var i = 0; i < _props.length; i++) {
                var p = _props[i];
                if (p === "all") continue;
                var pFrames = timelineModel.keyframeFrames(_target, p);
                for (var j = 0; j < pFrames.length; j++) {
                    if (frames.indexOf(pFrames[j]) === -1)
                        frames.push(pFrames[j]);
                }
            }
            return frames.sort(function(a, b) { return a - b; });
        }
        return timelineModel.keyframeFrames(_target, prop);
    }

    function _easeValue(t, easing) {
        if (easing === 1) return t * t;
        if (easing === 2) return t * (2 - t);
        if (easing === 3) return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
        return t;
    }

    function goToGraph() { if (_props.indexOf(selectedProperty) >= 0) mode = "graph"; }
    function goToDope() { mode = "dope"; }

    function _buildSearchableItems() {
        var items = [];
        if (!_comp) return items;
        for (var li = 0; li < _comp.layerCount(); li++) {
            var tl = _comp.layerAt(li);
            items.push({ object: tl, name: tl.name, depth: 0, typeName: "Layer" });
            for (var ti = 0; ti < tl.trackCount; ti++) {
                var tr = tl.trackAt(ti);
                items.push({ object: tr, name: tr.name, depth: 1, typeName: "Track" });
                for (var si = 0; si < tr.stripCount; si++) {
                    var st = tr.stripAt(si);
                    var elName = st.element ? st.element.name : "?";
                    items.push({ object: st, name: st.name + " (" + elName + ")", depth: 2, typeName: "Strip" });
                }
            }
        }
        return items;
    }

    // ── Toolbar ──
    Rectangle {
        id: toolbar
        anchors.top: parent.top; width: parent.width; height: 36; z: 10
        color: Theme.secondary; border.color: Theme.border

        Row {
            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8
            spacing: 8
            Button {
                id: selectBtn
                text: _target ? (selectedObject ? selectedObject.name || _target.name || "Selected" : "Select…") : "Select…"
                height: 26; flat: true; onClicked: selectPopup.open()
            }
            Button {
                text: mode === "graph" ? "Dope Sheet" : "Add Key"
                height: 26; flat: true; enabled: mode !== "graph"
                onClicked: {
                    if (!_target || !timelineModel || !selectedProperty || selectedProperty === "all") return;
                    var frame = timelineModel.currentFrame;
                    var val = _target[selectedProperty];
                    if (val !== undefined) {
                        timelineModel.addKeyframe(_target, selectedProperty, frame, val);
                        selectedKeyframeFrame = frame;
                    }
                }
            }
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
            text: _target ? (_target.name || "?") + " — " + selectedProperty : "No target"
            color: Theme.mutedForeground; font.pixelSize: 11
        }
    }

    Popup {
        id: selectPopup
        x: selectBtn.x; y: toolbar.height; width: 300; height: 400; modal: true
        contentItem: Rectangle {
            color: Theme.background; border.color: Theme.border
            ListView {
                anchors.fill: parent; anchors.margins: 4; model: _buildSearchableItems()
                delegate: ItemDelegate {
                    width: parent.width; text: modelData.name + " (" + modelData.typeName + ")"
                    onClicked: { selectedObject = modelData.object; selectPopup.close(); }
                }
            }
        }
    }

    RowLayout {
        anchors.top: toolbar.bottom; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; spacing: 0

        // Property list
        Rectangle {
            Layout.preferredWidth: 180; Layout.fillHeight: true
            color: Theme.secondary; border.color: Theme.border
            Column {
                anchors.fill: parent; anchors.margins: 8; spacing: 4
                Repeater {
                    model: _props.length
                    delegate: ItemDelegate {
                        width: parent.width; height: 28
                        text: _propLabels[index]
                        highlighted: selectedProperty === _props[index]
                        onClicked: { selectedProperty = _props[index]; mode = "dope"; }
                    }
                }
            }
        }

        // Dope Sheet
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true; color: Theme.background; visible: mode === "dope"
            Flickable {
                anchors.fill: parent; contentWidth: _duration * pixelPerFrame + 100; clip: true
                Rectangle {
                    width: parent.contentWidth; height: parent.height; color: "transparent"
                    Repeater {
                        model: _keyframesFor(selectedProperty)
                        delegate: Rectangle {
                            x: modelData * pixelPerFrame - 6; y: 50; width: 12; height: 12; rotation: 45
                            color: modelData === selectedKeyframeFrame ? Theme.accent : "#fff"
                            MouseArea { 
                                anchors.fill: parent; onClicked: selectedKeyframeFrame = modelData
                                onDoubleClicked: goToGraph()
                            }
                        }
                    }
                }
            }
        }

        // Graph Editor
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true; color: Theme.background; visible: mode === "graph"
            Item {
                id: graphArea
                anchors.fill: parent; anchors.margins: 40
                property real minVal: 0; property real maxVal: 1
                
                function recalcBounds() {
                    let min = 0; let max = 1;
                    let first = true;
                    let props = (selectedProperty === "all") ? _props.filter(function(p){return p!=="all";}) : [selectedProperty];
                    for (let pIdx = 0; pIdx < props.length; pIdx++) {
                        let d = timelineModel.getKeyframeData(root._target, props[pIdx]);
                        for (let i = 0; i < d.length; i++) {
                            if (first) { min = d[i].value; max = d[i].value; first = false; }
                            else {
                                if (d[i].value < min) min = d[i].value;
                                if (d[i].value > max) max = d[i].value;
                            }
                        }
                    }
                    let rng = max - min; if (rng === 0) rng = 1;
                    minVal = min - rng * 0.2; maxVal = max + rng * 0.2;
                    console.log("RecalcBounds - min:", minVal, "max:", maxVal, "props:", props.length);
                }

                function frameToX(fr) { return (fr / (Math.max(1, _duration - 1))) * width; }
                function valueToY(v) { return height - ((v - minVal) / (maxVal - minVal || 1)) * height; }
                function yToValue(y) { return minVal + (1 - y / height) * (maxVal - minVal); }

                Connections {
                    target: root
                    function onSelectedPropertyChanged() { graphArea.recalcBounds(); gCanvas.requestPaint(); }
                    function onSelectedObjectChanged() { graphArea.recalcBounds(); gCanvas.requestPaint(); }
                }

                Canvas {
                    id: gCanvas; anchors.fill: parent; onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                        var props = (selectedProperty === "all") ? _props.filter(function(p){return p!=="all";}) : [selectedProperty];
                        var colors = ["#4ade80", "#fbbf24", "#f87171", "#60a5fa", "#a78bfa", "#ec4899"];
                        
                        for (var pIdx = 0; pIdx < props.length; pIdx++) {
                            var prop = props[pIdx];
                            var d = timelineModel.getKeyframeData(root._target, prop);
                            if (d.length === 0) continue;
                            ctx.strokeStyle = colors[pIdx % colors.length]; ctx.lineWidth = 2; ctx.beginPath();
                            for (var i = 0; i < d.length; i++) {
                                var kf = d[i]; var px = graphArea.frameToX(kf.frame), py = graphArea.valueToY(kf.value);
                                if (i === 0) ctx.moveTo(px, py);
                                else {
                                    var prev = d[i-1];
                                    var prevObj = timelineModel.getKeyframe(root._target, prop, prev.frame);
                                    var currObj = timelineModel.getKeyframe(root._target, prop, kf.frame);
                                    if (prev.easing === 4 && prevObj && currObj) {
                                        ctx.bezierCurveTo(graphArea.frameToX(prev.frame + prevObj.handleOut.x), graphArea.valueToY(prev.value + prevObj.handleOut.y),
                                                          graphArea.frameToX(kf.frame + currObj.handleIn.x), graphArea.valueToY(kf.value + currObj.handleIn.y), px, py);
                                    }
 else {
                                        var segFrames = kf.frame - prev.frame;
                                        for (var s = 1; s <= 10; s++) {
                                            var t = s / 10;
                                            var easedT = root._easeValue(t, prev.easing);
                                            ctx.lineTo(graphArea.frameToX(prev.frame + t * segFrames), graphArea.valueToY(prev.value + (kf.value - prev.value) * easedT));
                                        }
                                    }
                                }
                            }
                            ctx.stroke();

                            if (prop === selectedProperty || selectedProperty === "all") {
                                ctx.save(); ctx.setLineDash([2, 2]); ctx.lineWidth = 1; ctx.strokeStyle = Qt.rgba(1,1,1,0.3);
                                for (var ti = 0; ti < d.length; ti++) {
                                    var tkf = d[ti]; var tkfObj = timelineModel.getKeyframe(root._target, prop, tkf.frame);
                                    if (tkfObj && tkfObj.easing === 4) {
                                        var tx = graphArea.frameToX(tkf.frame), ty = graphArea.valueToY(tkf.value);
                                        ctx.beginPath(); ctx.moveTo(tx, ty);
                                        ctx.lineTo(graphArea.frameToX(tkf.frame + tkfObj.handleIn.x), graphArea.valueToY(tkf.value + tkfObj.handleIn.y)); ctx.stroke();
                                        ctx.beginPath(); ctx.moveTo(tx, ty);
                                        ctx.lineTo(graphArea.frameToX(tkf.frame + tkfObj.handleOut.x), graphArea.valueToY(tkf.value + tkfObj.handleOut.y)); ctx.stroke();
                                    }

                                }
                                ctx.restore();
                            }
                        }
                    }
                }

                Repeater {
                    model: (selectedProperty !== "all") ? _keyframesFor(selectedProperty) : []
                    delegate: Item {
                        property var kf: timelineModel.getKeyframe(root._target, root.selectedProperty, modelData)
                        x: graphArea.frameToX(modelData); y: graphArea.valueToY(kf ? kf.value : 0); visible: kf !== null
                        Rectangle { 
                            width: 10; height: 10; rotation: 45; color: Theme.accent; anchors.centerIn: parent 
                            MouseArea {
                                anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: function(mouse) {
                                    selectedKeyframeFrame = modelData;
                                    if (mouse.button === Qt.RightButton) easingMenu.popup();
                                }
                            }
                        }
                        Repeater {
                            model: kf && kf.easing === 4 ? [0, 1] : []
                            delegate: Rectangle {
                                property bool isOut: index === 1
                                x: (isOut ? kf.handleOut.x : kf.handleIn.x) * (graphArea.width / Math.max(1, _duration - 1)) - 4
                                y: (graphArea.valueToY(kf.value + (isOut ? kf.handleOut.y : kf.handleIn.y)) - graphArea.valueToY(kf.value)) - 4
                                width: 8; height: 8; radius: 4; color: "#4ade80"; border.color: "#fff"
                                MouseArea {
                                    anchors.fill: parent; drag.target: parent
                                    onPositionChanged: {
                                        if (drag.active) {
                                            let dt = parent.x / (graphArea.width / Math.max(1, _duration - 1));
                                            let dv = graphArea.yToValue(graphArea.valueToY(kf.value) + parent.y) - kf.value;
                                            if (isOut) kf.handleOut = Qt.point(dt, dv); else kf.handleIn = Qt.point(dt, dv);
                                            gCanvas.requestPaint();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Menu {
        id: easingMenu
        MenuItem { text: "Linear"; onTriggered: { var kf = timelineModel.getKeyframe(root._target, root.selectedProperty, selectedKeyframeFrame); kf.easing = 0; gCanvas.requestPaint(); } }
        MenuItem { text: "Bezier"; onTriggered: { var kf = timelineModel.getKeyframe(root._target, root.selectedProperty, selectedKeyframeFrame); kf.easing = 4; gCanvas.requestPaint(); } }
    }
}
