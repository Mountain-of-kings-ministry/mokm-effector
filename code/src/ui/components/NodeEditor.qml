import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import mokm_effector

Item {
    id: root
    property var nodeGraph
    property real menuSceneX: 0
    property real menuSceneY: 0
    property int _contextNodeId: -1
    function createNodeAt(type) {
        if (root.nodeGraph)
            root.nodeGraph.addNodeAt(type, menuSceneX, menuSceneY);
    }
    // Top toolbar: zoom controls and node count
    Rectangle {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 36
        color: (typeof Theme !== 'undefined' && Theme.headerBackground ? Theme.headerBackground : "#2b2b2b")
        border.color: (typeof Theme !== 'undefined' && Theme.border ? Theme.border : "#444444")

        RowLayout {
            anchors.fill: parent
            anchors.margins: 6

            // Zoom controls
            Item {
                Layout.fillWidth: true
            }

            Text {
                id: scaleLabel
                visible: root.nodeGraph !== null
                text: graphView ? (Math.round(graphView.scale * 100) + "%") : ""
                color: Theme.mutedForeground
                font.pixelSize: 11
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter
            }

            Button {
                text: "Fit"
                visible: root.nodeGraph !== null
                height: 26
                flat: true
                onClicked: graphView.fitContent()
            }

            Text {
                Layout.rightMargin: 12
                Layout.alignment: Qt.AlignVCenter
                text: root.nodeGraph ? (root.nodeGraph.nodeCount + " nodes") : "No Graph Selected"
                color: (typeof Theme !== 'undefined' && Theme.mutedForeground ? Theme.mutedForeground : "#a0a0a0")
                font.pixelSize: 10
            }
        }
    }

    // Content area
    Item {
        anchors.top: parent.top
        anchors.topMargin: 36
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        NodeGraphView {
            id: graphView
            anchors.fill: parent
            nodeGraph: root.nodeGraph
            visible: root.nodeGraph !== null
            interactive: true
            Component.onCompleted: {
                if (graphView)
                    graphView.scale = 0.75;
            }
            onCanvasRightClicked: function (sceneX, sceneY, screenX, screenY) {
                if (root.nodeGraph) {
                    menuSceneX = sceneX;
                    menuSceneY = sceneY;
                    addNodeMenu.popup(screenX, screenY);
                }
            }
            onNodeRightClicked: function (nodeId, screenX, screenY) {
                _contextNodeId = nodeId;
                nodeContextMenu.popup(screenX, screenY);
            }
        }

        // Placeholder
        Rectangle {
            anchors.fill: parent
            visible: root.nodeGraph === null
            color: Theme.background

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.strokeStyle = Theme.border;
                    ctx.lineWidth = 1;
                    var gs = 24;
                    for (var x = 0; x < width; x += gs) {
                        ctx.beginPath();
                        ctx.moveTo(x, 0);
                        ctx.lineTo(x, height);
                        ctx.stroke();
                    }
                    for (var y = 0; y < height; y += gs) {
                        ctx.beginPath();
                        ctx.moveTo(0, y);
                        ctx.lineTo(width, y);
                        ctx.stroke();
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: qsTr("Select a NodeStrip to edit its node graph")
                color: Theme.mutedForeground
                font.pixelSize: 13
            }
        }
    }

    // ── Right-click "Add Node" context menu ──
    Menu {
        id: addNodeMenu

        Menu {
            title: qsTr("Generators")

            MenuItem {
                text: qsTr("Rectangle")
                onTriggered: root.createNodeAt("Rectangle")
            }
            MenuItem {
                text: qsTr("Circle")
                onTriggered: root.createNodeAt("Circle")
            }
            MenuItem {
                text: qsTr("Ellipse")
                onTriggered: root.createNodeAt("Ellipse")
            }
            MenuItem {
                text: qsTr("Polygon")
                onTriggered: root.createNodeAt("Polygon")
            }
            MenuItem {
                text: qsTr("Star")
                onTriggered: root.createNodeAt("Star")
            }
            MenuItem {
                text: qsTr("Line")
                onTriggered: root.createNodeAt("Line")
            }
            MenuItem {
                text: qsTr("Arc")
                onTriggered: root.createNodeAt("Arc")
            }
            MenuItem {
                text: qsTr("Grid")
                onTriggered: root.createNodeAt("Grid")
            }
            MenuItem {
                text: qsTr("Spiral")
                onTriggered: root.createNodeAt("Spiral")
            }
            MenuItem {
                text: qsTr("Arrow")
                onTriggered: root.createNodeAt("Arrow")
                MenuItem {
                    text: qsTr("Keyframe")
                    onTriggered: root.createNodeAt("Keyframe")
                }
                MenuItem {
                    text: qsTr("Curve")
                    onTriggered: root.createNodeAt("Curve")
                }
                MenuItem {
                    text: qsTr("Easing")
                    onTriggered: root.createNodeAt("Easing")
                }
                MenuItem {
                    text: qsTr("Spring")
                    onTriggered: root.createNodeAt("Spring")
                }
                MenuItem {
                    text: qsTr("Bounce")
                    onTriggered: root.createNodeAt("Bounce")
                }
                MenuItem {
                    text: qsTr("Oscillator")
                    onTriggered: root.createNodeAt("Oscillator")
                }
                MenuItem {
                    text: qsTr("Wiggle")
                    onTriggered: root.createNodeAt("Wiggle")
                }
                MenuItem {
                    text: qsTr("Loop")
                    onTriggered: root.createNodeAt("Loop")
                }
                MenuItem {
                    text: qsTr("Ping Pong")
                    onTriggered: root.createNodeAt("PingPong")
                }
                MenuItem {
                    text: qsTr("Time Stretch")
                    onTriggered: root.createNodeAt("TimeStretch")
                }
            }
            MenuItem {
                text: qsTr("SVG")
                onTriggered: root.createNodeAt("SVG")
            }
            MenuItem {
                text: qsTr("Spline")
                onTriggered: root.createNodeAt("Spline")
            }
            MenuItem {
                text: qsTr("Lottie")
                onTriggered: root.createNodeAt("Lottie")
            }
            MenuItem {
                text: qsTr("Gradient Shape")
                onTriggered: root.createNodeAt("GradientShape")
            }
            MenuItem {
                text: qsTr("Parametric Shape")
                onTriggered: root.createNodeAt("ParametricShape")
            }
            MenuItem {
                text: qsTr("Waveform")
                onTriggered: root.createNodeAt("Waveform")
            }
        }

        Menu {
            title: qsTr("Text")

            MenuItem {
                text: qsTr("Text")
                onTriggered: root.createNodeAt("Text")
            }
            MenuItem {
                text: qsTr("Text Along Path")
                onTriggered: root.createNodeAt("TextAlongPath")
            }
            MenuItem {
                text: qsTr("Text Animator")
                onTriggered: root.createNodeAt("TextAnimator")
            }
            MenuItem {
                text: qsTr("Text Range Selector")
                onTriggered: root.createNodeAt("TextRangeSelector")
            }
            MenuItem {
                text: qsTr("Text Repeater")
                onTriggered: root.createNodeAt("TextRepeater")
            }
            MenuItem {
                text: qsTr("Rich Text")
                onTriggered: root.createNodeAt("RichText")
            }
            MenuItem {
                text: qsTr("Typewriter")
                onTriggered: root.createNodeAt("Typewriter")
            }
        }

        Menu {
            title: qsTr("Media")

            MenuItem {
                text: qsTr("Image")
                onTriggered: root.createNodeAt("Image")
            }
            MenuItem {
                text: qsTr("Video")
                onTriggered: root.createNodeAt("Video")
            }
            MenuItem {
                text: qsTr("Image Sequence")
                onTriggered: root.createNodeAt("ImageSequence")
            }
            MenuItem {
                text: qsTr("Audio File")
                onTriggered: root.createNodeAt("AudioFile")
            }
            MenuItem {
                text: qsTr("Webcam")
                onTriggered: root.createNodeAt("Webcam")
            }
            MenuItem {
                text: qsTr("Screen Capture")
                onTriggered: root.createNodeAt("ScreenCapture")
            }
            MenuItem {
                text: qsTr("GIF")
                onTriggered: root.createNodeAt("GIF")
            }
            MenuItem {
                text: qsTr("Sprite Sheet")
                onTriggered: root.createNodeAt("SpriteSheet")
            }
        }

        Menu {
            title: qsTr("Geometry")

            MenuItem {
                text: qsTr("Extrude")
                onTriggered: root.createNodeAt("Extrude")
            }
            MenuItem {
                text: qsTr("Bevel")
                onTriggered: root.createNodeAt("Bevel")
            }
            MenuItem {
                text: qsTr("Boolean")
                onTriggered: root.createNodeAt("Boolean")
            }
            MenuItem {
                text: qsTr("Offset Path")
                onTriggered: root.createNodeAt("OffsetPath")
            }
            MenuItem {
                text: qsTr("Merge Shapes")
                onTriggered: root.createNodeAt("MergeShapes")
            }
            MenuItem {
                text: qsTr("Trim Path")
                onTriggered: root.createNodeAt("TrimPath")
            }
            MenuItem {
                text: qsTr("Scatter")
                onTriggered: root.createNodeAt("Scatter")
            }
            MenuItem {
                text: qsTr("Instance")
                onTriggered: root.createNodeAt("Instance")
            }
            MenuItem {
                text: qsTr("Array")
                onTriggered: root.createNodeAt("Array")
            }
        }

        Menu {
            title: qsTr("Animation")

            MenuItem {
                text: qsTr("Keyframe")
                onTriggered: root.createNodeAt("Keyframe")
            }
            MenuItem {
                text: qsTr("Curve")
                onTriggered: root.createNodeAt("Curve")
            }
            MenuItem {
                text: qsTr("Easing")
                onTriggered: root.createNodeAt("Easing")
            }
            MenuItem {
                text: qsTr("Spring")
                onTriggered: root.createNodeAt("Spring")
            }
            MenuItem {
                text: qsTr("Bounce")
                onTriggered: root.createNodeAt("Bounce")
            }
            MenuItem {
                text: qsTr("Oscillator")
                onTriggered: root.createNodeAt("Oscillator")
            }
            MenuItem {
                text: qsTr("Wiggle")
                onTriggered: root.createNodeAt("Wiggle")
            }
            MenuItem {
                text: qsTr("Loop")
                onTriggered: root.createNodeAt("Loop")
            }
            MenuItem {
                text: qsTr("Ping Pong")
                onTriggered: root.createNodeAt("PingPong")
            }
            MenuItem {
                text: qsTr("Time Stretch")
                onTriggered: root.createNodeAt("TimeStretch")
            }
        }

        Menu {
            title: qsTr("Motion")

            MenuItem {
                text: qsTr("Cloner")
                onTriggered: root.createNodeAt("Cloner")
            }
            MenuItem {
                text: qsTr("Radial Clone")
                onTriggered: root.createNodeAt("RadialClone")
            }
            MenuItem {
                text: qsTr("Grid Clone")
                onTriggered: root.createNodeAt("GridClone")
            }
            MenuItem {
                text: qsTr("Follow Path")
                onTriggered: root.createNodeAt("FollowPath")
            }
            MenuItem {
                text: qsTr("Look At")
                onTriggered: root.createNodeAt("LookAt")
            }
            MenuItem {
                text: qsTr("Align")
                onTriggered: root.createNodeAt("Align")
            }
            MenuItem {
                text: qsTr("Distribute")
                onTriggered: root.createNodeAt("Distribute")
            }
            MenuItem {
                text: qsTr("Random Transform")
                onTriggered: root.createNodeAt("RandomTransform")
            }
            MenuItem {
                text: qsTr("Trail")
                onTriggered: root.createNodeAt("Trail")
            }
            MenuItem {
                text: qsTr("Echo")
                onTriggered: root.createNodeAt("Echo")
            }
        }

        Menu {
            title: qsTr("Procedural")

            MenuItem {
                text: qsTr("Noise")
                onTriggered: root.createNodeAt("Noise")
            }
            MenuItem {
                text: qsTr("Curl Noise")
                onTriggered: root.createNodeAt("CurlNoise")
            }
            MenuItem {
                text: qsTr("Random")
                onTriggered: root.createNodeAt("Random")
            }
            MenuItem {
                text: qsTr("Voronoi")
                onTriggered: root.createNodeAt("Voronoi")
            }
            MenuItem {
                text: qsTr("Perlin")
                onTriggered: root.createNodeAt("Perlin")
            }
            MenuItem {
                text: qsTr("Fractal")
                onTriggered: root.createNodeAt("Fractal")
            }
            MenuItem {
                text: qsTr("Expression")
                onTriggered: root.createNodeAt("Expression")
            }
            MenuItem {
                text: qsTr("Formula")
                onTriggered: root.createNodeAt("Formula")
            }
        }

        Menu {
            title: qsTr("Effects")

            MenuItem {
                text: qsTr("Blur")
                onTriggered: root.createNodeAt("Blur")
            }
            MenuItem {
                text: qsTr("Transform")
                onTriggered: root.createNodeAt("Transform")
            }
            MenuItem {
                text: qsTr("Glow")
                onTriggered: root.createNodeAt("Glow")
            }
            MenuItem {
                text: qsTr("Bloom")
                onTriggered: root.createNodeAt("Bloom")
            }
            MenuItem {
                text: qsTr("Shadow")
                onTriggered: root.createNodeAt("Shadow")
            }
            MenuItem {
                text: qsTr("Outline")
                onTriggered: root.createNodeAt("Outline")
            }
            MenuItem {
                text: qsTr("Chromatic Aberration")
                onTriggered: root.createNodeAt("ChromaticAberration")
            }
            MenuItem {
                text: qsTr("Distortion")
                onTriggered: root.createNodeAt("Distortion")
            }
            MenuItem {
                text: qsTr("Pixelate")
                onTriggered: root.createNodeAt("Pixelate")
            }
            MenuItem {
                text: qsTr("Sharpen")
                onTriggered: root.createNodeAt("Sharpen")
            }
            MenuItem {
                text: qsTr("Glitch")
                onTriggered: root.createNodeAt("Glitch")
            }
            MenuItem {
                text: qsTr("Film Grain")
                onTriggered: root.createNodeAt("FilmGrain")
            }
            MenuItem {
                text: qsTr("Color Correction")
                onTriggered: root.createNodeAt("ColorCorrection")
            }
            MenuItem {
                text: qsTr("Curves")
                onTriggered: root.createNodeAt("Curves")
            }
            MenuItem {
                text: qsTr("Levels")
                onTriggered: root.createNodeAt("Levels")
            }
            MenuItem {
                text: qsTr("Keyer")
                onTriggered: root.createNodeAt("Keyer")
            }
        }

        Menu {
            title: qsTr("Audio")

            MenuItem {
                text: qsTr("Audio Reactive")
                onTriggered: root.createNodeAt("AudioReactive")
            }
            MenuItem {
                text: qsTr("Audio Spectrum")
                onTriggered: root.createNodeAt("AudioSpectrum")
            }
            MenuItem {
                text: qsTr("Audio Waveform")
                onTriggered: root.createNodeAt("AudioWaveform")
            }
            MenuItem {
                text: qsTr("Beat Detection")
                onTriggered: root.createNodeAt("BeatDetection")
            }
            MenuItem {
                text: qsTr("FFT")
                onTriggered: root.createNodeAt("FFT")
            }
            MenuItem {
                text: qsTr("MIDI Input")
                onTriggered: root.createNodeAt("MIDIInput")
            }
        }

        Menu {
            title: qsTr("Compositing")

            MenuItem {
                text: qsTr("Blend")
                onTriggered: root.createNodeAt("Blend")
            }
            MenuItem {
                text: qsTr("Merge")
                onTriggered: root.createNodeAt("Merge")
            }
            MenuItem {
                text: qsTr("Alpha Over")
                onTriggered: root.createNodeAt("AlphaOver")
            }
            MenuItem {
                text: qsTr("Multiply")
                onTriggered: root.createNodeAt("Multiply")
            }
            MenuItem {
                text: qsTr("Screen")
                onTriggered: root.createNodeAt("Screen")
            }
            MenuItem {
                text: qsTr("Overlay")
                onTriggered: root.createNodeAt("Overlay")
            }
            MenuItem {
                text: qsTr("Mask")
                onTriggered: root.createNodeAt("Mask")
            }
            MenuItem {
                text: qsTr("Crop")
                onTriggered: root.createNodeAt("Crop")
            }
            MenuItem {
                text: qsTr("Transform 2D")
                onTriggered: root.createNodeAt("Transform2D")
            }
        }

        Menu {
            title: qsTr("Utility")

            MenuItem {
                text: qsTr("Clamp")
                onTriggered: root.createNodeAt("Clamp")
            }
            MenuItem {
                text: qsTr("Remap")
                onTriggered: root.createNodeAt("Remap")
            }
            MenuItem {
                text: qsTr("Lerp")
                onTriggered: root.createNodeAt("Lerp")
            }
            MenuItem {
                text: qsTr("Mix")
                onTriggered: root.createNodeAt("Mix")
            }
            MenuItem {
                text: qsTr("Math")
                onTriggered: root.createNodeAt("Math")
            }
            MenuItem {
                text: qsTr("Vector Math")
                onTriggered: root.createNodeAt("VectorMath")
            }
            MenuItem {
                text: qsTr("Timer")
                onTriggered: root.createNodeAt("Timer")
            }
            MenuItem {
                text: qsTr("Counter")
                onTriggered: root.createNodeAt("Counter")
            }
        }

        Menu {
            title: qsTr("Debug")

            MenuItem {
                text: qsTr("Print")
                onTriggered: root.createNodeAt("Print")
            }
            MenuItem {
                text: qsTr("Inspector")
                onTriggered: root.createNodeAt("Inspector")
            }
            MenuItem {
                text: qsTr("FPS")
                onTriggered: root.createNodeAt("FPS")
            }
            MenuItem {
                text: qsTr("Profiler")
                onTriggered: root.createNodeAt("Profiler")
            }
            MenuItem {
                text: qsTr("Graph Debug")
                onTriggered: root.createNodeAt("GraphDebug")
            }
        }
    }

    // ── Right-click node context menu ──
    Menu {
        id: nodeContextMenu

        MenuItem {
            text: qsTr("Delete")
            onTriggered: {
                if (root.nodeGraph && _contextNodeId >= 0)
                    root.nodeGraph.removeNode(_contextNodeId);
                _contextNodeId = -1;
            }
        }
        MenuItem {
            text: qsTr("Duplicate")
            onTriggered: {
                if (root.nodeGraph && _contextNodeId >= 0) {
                    var ids = root.nodeGraph.nodeIds();
                    var json = root.nodeGraph.nodeParameters(_contextNodeId);
                    var type = json["name"] || "";
                    if (type) {
                        var pos = root.nodeGraph.nodeParameters(_contextNodeId);
                        var newId = root.nodeGraph.addNode(type);
                        if (newId >= 0) {
                            // Copy parameters from source
                            for (var k in pos) {
                                if (k !== "name" && k !== "id")
                                    root.nodeGraph.setNodeParameter(newId, k, pos[k]);
                            }
                        }
                    }
                }
                _contextNodeId = -1;
            }
        }
    }
}
