import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root
    color: Theme.background
    clip: true

    property var nodeGraph: null
    property var selectedStrip: null

    function _detectType(obj) {
        if (!obj)
            return "none";
        if (obj.nodeGraph !== undefined)
            return "nodeStrip";
        if (obj.deleteStrip)
            return "strip";
        if (obj.deleteTrack)
            return "track";
        if (obj.deleteLayer)
            return "layer";
        if (obj.tracks !== undefined)
            return "layer";
        if (obj.strips !== undefined)
            return "track";
        if (obj.element !== undefined)
            return "strip";
        return "unknown";
    }

    onSelectedStripChanged: {
        var t = _detectType(selectedStrip);
        if (t === "nodeStrip" && selectedStrip.nodeGraph) {
            root.nodeGraph = selectedStrip.nodeGraph;
        } else if (t === "strip" && selectedStrip.element) {
            root.nodeGraph = null;
        } else {
            root.nodeGraph = null;
        }
    }

    // Top toolbar
    Rectangle {
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
            spacing: 6

            Button {
                text: "Cook"
                visible: root.nodeGraph !== null
                height: 26
                flat: true
                onClicked: {
                    if (root.selectedStrip && root.selectedStrip.cook)
                        root.selectedStrip.cook();
                }
            }

            Button {
                text: "Reset View"
                visible: root.nodeGraph !== null
                height: 26
                flat: true
                onClicked: graphView.resetView()
            }

            Button {
                text: "Zoom Out"
                visible: root.nodeGraph !== null
                height: 26
                flat: true
                onClicked: {
                    if (graphView)
                        graphView.scale = Math.max(0.2, graphView.scale / 1.2);
                }
            }

            Button {
                text: "Zoom In"
                visible: root.nodeGraph !== null
                height: 26
                flat: true
                onClicked: {
                    if (graphView)
                        graphView.scale = Math.min(3.0, graphView.scale * 1.2);
                }
            }

            Text {
                id: scaleLabel
                visible: root.nodeGraph !== null
                text: graphView ? (Math.round(graphView.scale * 100) + "%") : ""
                color: Theme.mutedForeground
                font.pixelSize: 11
                verticalAlignment: Text.AlignVCenter
            }

            Button {
                text: "Fit"
                visible: root.nodeGraph !== null
                height: 26
                flat: true
                onClicked: graphView.fitContent()
            }
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: root.nodeGraph ? (root.nodeGraph.nodeCount + " nodes") : "No Graph Selected"
            color: Theme.mutedForeground
            font.pixelSize: 10
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
                if (root.nodeGraph)
                    addNodeMenu.popup(screenX, screenY);
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
                onTriggered: root.nodeGraph.addNodeAutoConnect("Rectangle")
            }
            MenuItem {
                text: qsTr("Circle")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Circle")
            }
            MenuItem {
                text: qsTr("Ellipse")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Ellipse")
            }
            MenuItem {
                text: qsTr("Polygon")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Polygon")
            }
            MenuItem {
                text: qsTr("Star")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Star")
            }
            MenuItem {
                text: qsTr("Line")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Line")
            }
            MenuItem {
                text: qsTr("Arc")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Arc")
            }
            MenuItem {
                text: qsTr("Grid")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Grid")
            }
            MenuItem {
                text: qsTr("Spiral")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Spiral")
            }
            MenuItem {
                text: qsTr("Arrow")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Arrow")
            }
            MenuItem {
                text: qsTr("Rounded Rectangle")
                onTriggered: root.nodeGraph.addNodeAutoConnect("RoundedRect")
            }
            MenuItem {
                text: qsTr("Bezier Shape")
                onTriggered: root.nodeGraph.addNodeAutoConnect("BezierShape")
            }
            MenuItem {
                text: qsTr("Path")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Path")
            }
            MenuItem {
                text: qsTr("SVG")
                onTriggered: root.nodeGraph.addNodeAutoConnect("SVG")
            }
            MenuItem {
                text: qsTr("Spline")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Spline")
            }
            MenuItem {
                text: qsTr("Lottie")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Lottie")
            }
            MenuItem {
                text: qsTr("Gradient Shape")
                onTriggered: root.nodeGraph.addNodeAutoConnect("GradientShape")
            }
            MenuItem {
                text: qsTr("Parametric Shape")
                onTriggered: root.nodeGraph.addNodeAutoConnect("ParametricShape")
            }
            MenuItem {
                text: qsTr("Waveform")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Waveform")
            }
        }

        Menu {
            title: qsTr("Text")

            MenuItem {
                text: qsTr("Text")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Text")
            }
            MenuItem {
                text: qsTr("Text Along Path")
                onTriggered: root.nodeGraph.addNodeAutoConnect("TextAlongPath")
            }
            MenuItem {
                text: qsTr("Text Animator")
                onTriggered: root.nodeGraph.addNodeAutoConnect("TextAnimator")
            }
            MenuItem {
                text: qsTr("Text Range Selector")
                onTriggered: root.nodeGraph.addNodeAutoConnect("TextRangeSelector")
            }
            MenuItem {
                text: qsTr("Text Repeater")
                onTriggered: root.nodeGraph.addNodeAutoConnect("TextRepeater")
            }
            MenuItem {
                text: qsTr("Rich Text")
                onTriggered: root.nodeGraph.addNodeAutoConnect("RichText")
            }
            MenuItem {
                text: qsTr("Typewriter")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Typewriter")
            }
        }

        Menu {
            title: qsTr("Media")

            MenuItem {
                text: qsTr("Image")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Image")
            }
            MenuItem {
                text: qsTr("Video")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Video")
            }
            MenuItem {
                text: qsTr("Image Sequence")
                onTriggered: root.nodeGraph.addNodeAutoConnect("ImageSequence")
            }
            MenuItem {
                text: qsTr("Audio File")
                onTriggered: root.nodeGraph.addNodeAutoConnect("AudioFile")
            }
            MenuItem {
                text: qsTr("Webcam")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Webcam")
            }
            MenuItem {
                text: qsTr("Screen Capture")
                onTriggered: root.nodeGraph.addNodeAutoConnect("ScreenCapture")
            }
            MenuItem {
                text: qsTr("GIF")
                onTriggered: root.nodeGraph.addNodeAutoConnect("GIF")
            }
            MenuItem {
                text: qsTr("Sprite Sheet")
                onTriggered: root.nodeGraph.addNodeAutoConnect("SpriteSheet")
            }
        }

        Menu {
            title: qsTr("Geometry")

            MenuItem {
                text: qsTr("Extrude")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Extrude")
            }
            MenuItem {
                text: qsTr("Bevel")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Bevel")
            }
            MenuItem {
                text: qsTr("Boolean")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Boolean")
            }
            MenuItem {
                text: qsTr("Offset Path")
                onTriggered: root.nodeGraph.addNodeAutoConnect("OffsetPath")
            }
            MenuItem {
                text: qsTr("Merge Shapes")
                onTriggered: root.nodeGraph.addNodeAutoConnect("MergeShapes")
            }
            MenuItem {
                text: qsTr("Trim Path")
                onTriggered: root.nodeGraph.addNodeAutoConnect("TrimPath")
            }
            MenuItem {
                text: qsTr("Scatter")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Scatter")
            }
            MenuItem {
                text: qsTr("Instance")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Instance")
            }
            MenuItem {
                text: qsTr("Array")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Array")
            }
        }

        Menu {
            title: qsTr("Animation")

            MenuItem {
                text: qsTr("Keyframe")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Keyframe")
            }
            MenuItem {
                text: qsTr("Curve")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Curve")
            }
            MenuItem {
                text: qsTr("Easing")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Easing")
            }
            MenuItem {
                text: qsTr("Spring")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Spring")
            }
            MenuItem {
                text: qsTr("Bounce")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Bounce")
            }
            MenuItem {
                text: qsTr("Oscillator")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Oscillator")
            }
            MenuItem {
                text: qsTr("Wiggle")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Wiggle")
            }
            MenuItem {
                text: qsTr("Loop")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Loop")
            }
            MenuItem {
                text: qsTr("Ping Pong")
                onTriggered: root.nodeGraph.addNodeAutoConnect("PingPong")
            }
            MenuItem {
                text: qsTr("Time Stretch")
                onTriggered: root.nodeGraph.addNodeAutoConnect("TimeStretch")
            }
        }

        Menu {
            title: qsTr("Motion")

            MenuItem {
                text: qsTr("Cloner")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Cloner")
            }
            MenuItem {
                text: qsTr("Radial Clone")
                onTriggered: root.nodeGraph.addNodeAutoConnect("RadialClone")
            }
            MenuItem {
                text: qsTr("Grid Clone")
                onTriggered: root.nodeGraph.addNodeAutoConnect("GridClone")
            }
            MenuItem {
                text: qsTr("Follow Path")
                onTriggered: root.nodeGraph.addNodeAutoConnect("FollowPath")
            }
            MenuItem {
                text: qsTr("Look At")
                onTriggered: root.nodeGraph.addNodeAutoConnect("LookAt")
            }
            MenuItem {
                text: qsTr("Align")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Align")
            }
            MenuItem {
                text: qsTr("Distribute")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Distribute")
            }
            MenuItem {
                text: qsTr("Random Transform")
                onTriggered: root.nodeGraph.addNodeAutoConnect("RandomTransform")
            }
            MenuItem {
                text: qsTr("Trail")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Trail")
            }
            MenuItem {
                text: qsTr("Echo")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Echo")
            }
        }

        Menu {
            title: qsTr("Procedural")

            MenuItem {
                text: qsTr("Noise")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Noise")
            }
            MenuItem {
                text: qsTr("Curl Noise")
                onTriggered: root.nodeGraph.addNodeAutoConnect("CurlNoise")
            }
            MenuItem {
                text: qsTr("Random")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Random")
            }
            MenuItem {
                text: qsTr("Voronoi")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Voronoi")
            }
            MenuItem {
                text: qsTr("Perlin")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Perlin")
            }
            MenuItem {
                text: qsTr("Fractal")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Fractal")
            }
            MenuItem {
                text: qsTr("Expression")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Expression")
            }
            MenuItem {
                text: qsTr("Formula")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Formula")
            }
        }

        Menu {
            title: qsTr("Effects")

            MenuItem {
                text: qsTr("Blur")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Blur")
            }
            MenuItem {
                text: qsTr("Transform")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Transform")
            }
            MenuItem {
                text: qsTr("Glow")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Glow")
            }
            MenuItem {
                text: qsTr("Bloom")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Bloom")
            }
            MenuItem {
                text: qsTr("Shadow")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Shadow")
            }
            MenuItem {
                text: qsTr("Outline")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Outline")
            }
            MenuItem {
                text: qsTr("Chromatic Aberration")
                onTriggered: root.nodeGraph.addNodeAutoConnect("ChromaticAberration")
            }
            MenuItem {
                text: qsTr("Distortion")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Distortion")
            }
            MenuItem {
                text: qsTr("Pixelate")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Pixelate")
            }
            MenuItem {
                text: qsTr("Sharpen")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Sharpen")
            }
            MenuItem {
                text: qsTr("Glitch")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Glitch")
            }
            MenuItem {
                text: qsTr("Film Grain")
                onTriggered: root.nodeGraph.addNodeAutoConnect("FilmGrain")
            }
            MenuItem {
                text: qsTr("Color Correction")
                onTriggered: root.nodeGraph.addNodeAutoConnect("ColorCorrection")
            }
            MenuItem {
                text: qsTr("Curves")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Curves")
            }
            MenuItem {
                text: qsTr("Levels")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Levels")
            }
            MenuItem {
                text: qsTr("Keyer")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Keyer")
            }
        }

        Menu {
            title: qsTr("Audio")

            MenuItem {
                text: qsTr("Audio Reactive")
                onTriggered: root.nodeGraph.addNodeAutoConnect("AudioReactive")
            }
            MenuItem {
                text: qsTr("Audio Spectrum")
                onTriggered: root.nodeGraph.addNodeAutoConnect("AudioSpectrum")
            }
            MenuItem {
                text: qsTr("Audio Waveform")
                onTriggered: root.nodeGraph.addNodeAutoConnect("AudioWaveform")
            }
            MenuItem {
                text: qsTr("Beat Detection")
                onTriggered: root.nodeGraph.addNodeAutoConnect("BeatDetection")
            }
            MenuItem {
                text: qsTr("FFT")
                onTriggered: root.nodeGraph.addNodeAutoConnect("FFT")
            }
            MenuItem {
                text: qsTr("MIDI Input")
                onTriggered: root.nodeGraph.addNodeAutoConnect("MIDIInput")
            }
        }

        Menu {
            title: qsTr("Compositing")

            MenuItem {
                text: qsTr("Blend")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Blend")
            }
            MenuItem {
                text: qsTr("Merge")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Merge")
            }
            MenuItem {
                text: qsTr("Alpha Over")
                onTriggered: root.nodeGraph.addNodeAutoConnect("AlphaOver")
            }
            MenuItem {
                text: qsTr("Multiply")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Multiply")
            }
            MenuItem {
                text: qsTr("Screen")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Screen")
            }
            MenuItem {
                text: qsTr("Overlay")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Overlay")
            }
            MenuItem {
                text: qsTr("Mask")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Mask")
            }
            MenuItem {
                text: qsTr("Crop")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Crop")
            }
            MenuItem {
                text: qsTr("Transform 2D")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Transform2D")
            }
        }

        Menu {
            title: qsTr("Utility")

            MenuItem {
                text: qsTr("Clamp")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Clamp")
            }
            MenuItem {
                text: qsTr("Remap")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Remap")
            }
            MenuItem {
                text: qsTr("Lerp")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Lerp")
            }
            MenuItem {
                text: qsTr("Mix")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Mix")
            }
            MenuItem {
                text: qsTr("Math")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Math")
            }
            MenuItem {
                text: qsTr("Vector Math")
                onTriggered: root.nodeGraph.addNodeAutoConnect("VectorMath")
            }
            MenuItem {
                text: qsTr("Timer")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Timer")
            }
            MenuItem {
                text: qsTr("Counter")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Counter")
            }
        }

        Menu {
            title: qsTr("Debug")

            MenuItem {
                text: qsTr("Print")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Print")
            }
            MenuItem {
                text: qsTr("Inspector")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Inspector")
            }
            MenuItem {
                text: qsTr("FPS")
                onTriggered: root.nodeGraph.addNodeAutoConnect("FPS")
            }
            MenuItem {
                text: qsTr("Profiler")
                onTriggered: root.nodeGraph.addNodeAutoConnect("Profiler")
            }
            MenuItem {
                text: qsTr("Graph Debug")
                onTriggered: root.nodeGraph.addNodeAutoConnect("GraphDebug")
            }
        }
    }
}
