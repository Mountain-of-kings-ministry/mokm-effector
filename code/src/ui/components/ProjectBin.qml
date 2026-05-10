import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: binRoot
    color: Theme.secondary
    clip: true

    readonly property var bin: binRoot

    property Composition composition: null
    property Project project: null

    signal createRectLayer
    signal createCircleLayer
    signal createTriangleLayer
    signal createTextLayer
    signal layerSelected(var layer)
    signal addAssetToTrack(var asset)
    signal addAssetToNewTrack(var asset)

    property var _selected: null

    property Component shapeLayerComponent: ShapeLayer {}
    property Component textLayerComponent: TextLayer {}
    property Component timelineLayerComponent: TimelineLayer {}

    function createNodeStrip(type) {
        if (!bin.project)
            return;
        var proj = bin.project;
        var layer;
        var names = ["Rectangle", "Ellipse", "Circle", "Triangle"];
        var num = proj.assetCount + 1;

        switch (type) {
        case "Rectangle":
            layer = shapeLayerComponent.createObject(proj, {
                name: "Rectangle " + num,
                shapeType: ShapeLayer.Rectangle,
                shapeWidth: 200,
                shapeHeight: 200,
                color: Theme.primary
            });
            break;
        case "Ellipse":
            layer = shapeLayerComponent.createObject(proj, {
                name: "Ellipse " + num,
                shapeType: ShapeLayer.Ellipse,
                shapeWidth: 200,
                shapeHeight: 150,
                color: Theme.primary
            });
            break;
        case "Circle":
            layer = shapeLayerComponent.createObject(proj, {
                name: "Circle " + num,
                shapeType: ShapeLayer.Circle,
                shapeWidth: 200,
                shapeHeight: 200,
                color: Theme.primary
            });
            break;
        case "Triangle":
            layer = shapeLayerComponent.createObject(proj, {
                name: "Triangle " + num,
                shapeType: ShapeLayer.Triangle,
                shapeWidth: 200,
                shapeHeight: 200,
                color: Theme.primary
            });
            break;
        case "Text":
            layer = textLayerComponent.createObject(proj, {
                name: "Text " + num,
                text: type,
                color: Theme.foreground,
                fontSize: 48
            });
            break;
        default:
            layer = shapeLayerComponent.createObject(proj, {
                name: type + " " + num,
                shapeType: ShapeLayer.Rectangle,
                shapeWidth: 200,
                shapeHeight: 200,
                color: Theme.primary
            });
            break;
        }

        if (layer) {
            proj.addAsset(layer);
            bin._selected = layer;
            bin.layerSelected(layer);
        }
    }

    // ── Collect layers and tracks into JS arrays for reliable menu population ──
    function getLayers() {
        if (!bin.composition) return [];
        var result = [];
        var count = bin.composition.layerCount();
        for (var i = 0; i < count; i++) {
            result.push(bin.composition.layerAt(i));
        }
        return result;
    }

    function getTracks(layerObj) {
        if (!layerObj) return [];
        var result = [];
        var count = layerObj.trackCount;
        for (var i = 0; i < count; i++) {
            result.push(layerObj.trackAt(i));
        }
        return result;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            height: 32
            color: Theme.secondaryHover

            Text {
                anchors.centerIn: parent
                text: qsTr("Project Bin")
                color: Theme.mutedForeground
                font.pixelSize: 11
                font.letterSpacing: 0.5
            }
        }

        ScrollView {
            id: binScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                id: binContent
                width: binScrollView.availableWidth
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    height: 22
                    color: "transparent"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 12
                        text: qsTr("Assets")
                        color: Theme.mutedForeground
                        font.pixelSize: 10
                        font.letterSpacing: 0.5
                    }
                }

                Repeater {
                    model: bin.project && bin.project.assets ? bin.project.assets : 0

                    delegate: Rectangle {
                        id: assetDelegate
                        Layout.fillWidth: true
                        height: 22
                        color: {
                            if (bin._selected === modelData)
                                return Theme.selected;
                            if (assetMouse.containsMouse)
                                return Theme.secondaryHover;
                            return index % 2 === 0 ? "transparent" : Qt.alpha(Theme.secondaryHover, 0.15);
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 28
                            spacing: 6

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 2
                                color: modelData?.enabled ?? false ? Theme.foreground : Theme.muted
                            }

                            Text {
                                text: modelData?.name ?? ""
                                color: bin._selected === modelData ? "#ffffff" : Theme.foreground
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: assetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.LeftButton) {
                                    bin._selected = modelData;
                                    bin.layerSelected(modelData);
                                }
                            }
                            onPressed: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    bin._selected = modelData;
                                    bin.layerSelected(modelData);
                                    assetContextMenu.asset = modelData;
                                    assetContextMenu.popup(assetMouse, mouse.x, mouse.y);
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 100

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onPressed: function (m) {
                            if (!bin.project)
                                return;
                            contextMenu.popup(m.x, m.y);
                        }
                    }
                }
            }
        }
    }

    // ── Right-click empty area menu ──
    Menu {
        id: contextMenu

        Menu {
            title: qsTr("Generators")

            MenuItem { text: qsTr("Rectangle"); onTriggered: createNodeStrip("Rectangle") }
            MenuItem { text: qsTr("Text"); onTriggered: createNodeStrip("Text") }
            MenuItem { text: qsTr("Circle"); onTriggered: createNodeStrip("Circle") }
            MenuItem { text: qsTr("Ellipse"); onTriggered: createNodeStrip("Ellipse") }
            MenuItem { text: qsTr("Polygon"); onTriggered: createNodeStrip("Polygon") }
            MenuItem { text: qsTr("Star"); onTriggered: createNodeStrip("Star") }
            MenuItem { text: qsTr("Line"); onTriggered: createNodeStrip("Line") }
            MenuItem { text: qsTr("Arc"); onTriggered: createNodeStrip("Arc") }
            MenuItem { text: qsTr("Grid"); onTriggered: createNodeStrip("Grid") }
            MenuItem { text: qsTr("Spiral"); onTriggered: createNodeStrip("Spiral") }
            MenuItem { text: qsTr("Arrow"); onTriggered: createNodeStrip("Arrow") }
            MenuItem { text: qsTr("Rounded Rectangle"); onTriggered: createNodeStrip("RoundedRectangle") }
            MenuItem { text: qsTr("Bezier Shape"); onTriggered: createNodeStrip("BezierShape") }
            MenuItem { text: qsTr("Path"); onTriggered: createNodeStrip("Path") }
            MenuItem { text: qsTr("SVG"); onTriggered: createNodeStrip("SVG") }
            MenuItem { text: qsTr("Spline"); onTriggered: createNodeStrip("Spline") }
            MenuItem { text: qsTr("Lottie"); onTriggered: createNodeStrip("Lottie") }
        }

        Menu {
            title: qsTr("Media")

            MenuItem { text: qsTr("Image"); onTriggered: createNodeStrip("Image") }
            MenuItem { text: qsTr("Video"); onTriggered: createNodeStrip("Video") }
            MenuItem { text: qsTr("Image Sequence"); onTriggered: createNodeStrip("ImageSequence") }
            MenuItem { text: qsTr("Audio File"); onTriggered: createNodeStrip("AudioFile") }
            MenuItem { text: qsTr("Webcam"); onTriggered: createNodeStrip("Webcam") }
            MenuItem { text: qsTr("Screen Capture"); onTriggered: createNodeStrip("ScreenCapture") }
            MenuItem { text: qsTr("GIF"); onTriggered: createNodeStrip("GIF") }
            MenuItem { text: qsTr("Sprite Sheet"); onTriggered: createNodeStrip("SpriteSheet") }
        }

        Menu {
            title: qsTr("Procedural")

            MenuItem { text: qsTr("Noise"); onTriggered: createNodeStrip("Noise") }
            MenuItem { text: qsTr("Curl Noise"); onTriggered: createNodeStrip("CurlNoise") }
            MenuItem { text: qsTr("Voronoi"); onTriggered: createNodeStrip("Voronoi") }
        }
    }

    // ── Right-click asset menu ──
    Menu {
        id: assetContextMenu
        property var asset: null

        MenuItem {
            text: qsTr("Add to Layer")
            enabled: bin.composition !== null && assetContextMenu.asset !== null

            // Dynamically populate submenus on open
            onTriggered: {} // Popup happens via submenus' aboutToShow
        }

        // ── Layer submenus built dynamically ──
        Instantiator {
            id: layerInstantiator
            active: false // We populate manually

            delegate: Menu { }
        }

        // Populate asset context menu when it's about to show
        onAboutToShow: {
            // Remove all dynamic items, keeping only "Delete Asset" (the last one)
            while (this.count > 1) {
                var item = this.itemAt(this.count - 2);
                if (!item) break;
                this.removeItem(item);
                if (item && item.destroy)
                    item.destroy();
            }

            // Add "Add to Layer" header at the beginning
            var layers = getLayers();
            if (layers.length === 0) {
                // No layers yet — offer to create one
                var noLayerItem = addMenuItem(qsTr("+ New Layer First"));
                noLayerItem.triggered.connect(function() {
                    if (!assetContextMenu.asset || !bin.composition) return;
                    var comp = bin.composition;
                    var tl = bin.timelineLayerComponent.createObject(comp, {
                        name: "Layer " + (comp.layerCount() + 1)
                    });
                    comp.addLayer(tl);
                    var track = tl.addTrack();
                    track.createStripFromAsset(assetContextMenu.asset, "", 0, 90);
                    if (bin.project)
                        bin.project.captureSnapshot();
                });
            } else {
                for (var li = 0; li < layers.length; li++) {
                    var layerObj = layers[li];
                    addMenu(layerObj);
                }
            }
        }

        // Helper: add a plain MenuItem and return it
        function addMenuItem(text) {
            var item = Qt.createQmlObject(
                'import QtQuick.Controls; MenuItem { text: "' + text.replace(/"/g, '\\"') + '" }',
                assetContextMenu, "dynamicMenuItem");
            var idx = Math.max(0, assetContextMenu.count - 1);
            assetContextMenu.insertItem(idx, item);
            return item;
        }

        // Helper: add menu items for tracks within a layer
        function addMenu(layerObj) {
            var tracks = getTracks(layerObj);
            var headerItem = addMenuItem(layerObj.name || "Layer");
            headerItem.enabled = false;

            if (tracks.length === 0) {
                var newTrackItem = addMenuItem("  + New Track");
                newTrackItem.triggered.connect(function() {
                    if (!assetContextMenu.asset || !layerObj) return;
                    var track = layerObj.addTrack();
                    track.createStripFromAsset(assetContextMenu.asset, "", 0, 90);
                    if (bin.project)
                        bin.project.captureSnapshot();
                });
                return;
            }

            for (var ti = 0; ti < tracks.length; ti++) {
                var trackObj = tracks[ti];
                var trackItem = addMenuItem("  " + (trackObj.name || ("Track " + (ti + 1))));
                trackItem.triggered.connect(function(t) {
                    return function() {
                        if (assetContextMenu.asset && t) {
                            t.createStripFromAsset(assetContextMenu.asset, "", 0, 90);
                            if (bin.project)
                                bin.project.captureSnapshot();
                        }
                    };
                }(trackObj));
            }

            var addTrackItem = addMenuItem("  + New Track");
            addTrackItem.triggered.connect(function() {
                if (!assetContextMenu.asset || !layerObj) return;
                var track = layerObj.addTrack();
                track.createStripFromAsset(assetContextMenu.asset, "", 0, 90);
                if (bin.project)
                    bin.project.captureSnapshot();
            });
        }

        MenuSeparator {}

        MenuItem {
            text: qsTr("Delete Asset")
            onTriggered: {
                if (assetContextMenu.asset && bin.project) {
                    bin.project.removeAsset(assetContextMenu.asset);
                    if (bin._selected === assetContextMenu.asset)
                        bin._selected = null;
                    if (bin.project)
                        bin.project.captureSnapshot();
                }
            }
        }
    }

    // Dead code removed — old Instantiator approach replaced with dynamic onAboutToShow
}
