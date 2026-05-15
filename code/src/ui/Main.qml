import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import mokm_effector
import NodeEditor

Window {
    id: mainWindow
    width: 1400
    height: 900
    visible: true
    title: qsTr("MOKM Effector — Untitled")
    color: Theme.background

    property bool animateFaders: false

    // frameless window with topbar
    flags: Qt.FramelessWindowHint

    Connections {
        target: project
        function onUndoChanged() {
            topBar.canUndo = project.canUndo;
            topBar.canRedo = project.canRedo;
        }
    }

    TimelineModel {
        id: globalTimelineModel
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TopBar {
            id: topBar
            Layout.fillWidth: true
            window: mainWindow

            onCreateRectLayer: createShapeLayer(ShapeLayer.Rectangle)
            onCreateCircleLayer: createShapeLayer(ShapeLayer.Circle)
            onCreateTriangleLayer: createShapeLayer(ShapeLayer.Triangle)
            onCreateTextLayer: createTextLayer()
            onDeleteSelectedLayer: deleteSelectedLayer()
            onImportImageRequested: importImageDialog.open()
            onImportAudioRequested: importAudioDialog.open()
            onImportVideoRequested: importVideoDialog.open()
            onExportVideoRequested: exportDialog.open()
            onExportImageSequenceRequested: exportImageSequenceDialog.open()
            onPreferencesRequested: prefsDialog.open()
        }

        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: Qt.Vertical

            handle: Rectangle {
                implicitWidth: 2
                implicitHeight: 2
                color: SplitHandle.pressed ? Theme.accent : (SplitHandle.hovered ? Theme.input : Theme.border)
            }

            SplitView {
                SplitView.fillHeight: true
                orientation: Qt.Horizontal

                handle: Rectangle {
                    implicitWidth: 2
                    implicitHeight: 2
                    color: SplitHandle.pressed ? Theme.accent : (SplitHandle.hovered ? Theme.input : Theme.border)
                }

                ProjectBin {
                    id: projectBin
                    SplitView.preferredWidth: 220
                    composition: project.activeComposition
                    projectModel: project

                    onImportImageRequested: importImageDialog.open()
                    onImportAudioRequested: importAudioDialog.open()
                    onImportVideoRequested: importVideoDialog.open()
                    onCreateRectLayer: createShapeLayer(ShapeLayer.Rectangle)
                    onCreateCircleLayer: createShapeLayer(ShapeLayer.Circle)
                    onCreateTriangleLayer: createShapeLayer(ShapeLayer.Triangle)
                    onCreateTextLayer: createTextLayer()
                    onLayerSelected: function (layer) {
                        selectedObject = layer;
                    }
                }

                Rectangle {
                    SplitView.fillWidth: true
                    color: Theme.background

                    ThorVGViewport {
                        id: viewport
                        anchors.fill: parent
                        anchors.margins: 1
                        composition: project.activeComposition
                        currentFrame: globalTimelineModel.currentFrame
                        onLayerSelected: function (layer) {
                            selectedObject = layer;
                        }
                        onLayerDragFinished: function (layer, x, y) {
                            if (globalTimelineModel && globalTimelineModel.autoKeyframeEnabled) {
                                globalTimelineModel.addKeyframe(layer, "x", globalTimelineModel.currentFrame, x);
                                globalTimelineModel.addKeyframe(layer, "y", globalTimelineModel.currentFrame, y);
                            }
                        }
                    }
                }

                EffectorPropertiesPanel {
                    SplitView.preferredWidth: 240
                    selectedObject: mainWindow.selectedObject
                    timelineModel: globalTimelineModel
                }
            }

            ColumnLayout {
                SplitView.preferredHeight: 450
                SplitView.minimumHeight: 200
                spacing: 0

                Toolbar {
                    id: toolbar
                    Layout.fillWidth: true

                    timelineModel: globalTimelineModel
                    selectedObject: selectedObject
                    currentTool: (stackView.currentItem && stackView.currentItem.currentTool !== undefined) ? stackView.currentItem.currentTool : "select"
                    snapEnabled: (stackView.currentItem && stackView.currentItem.snapEnabled !== undefined) ? stackView.currentItem.snapEnabled : true

                    onToolChanged: function(tool) {
                        if (stackView.currentItem && stackView.currentItem.currentTool !== undefined)
                            stackView.currentItem.currentTool = tool;
                    }

                    onSnapToggled: function(enabled) {
                        if (stackView.currentItem && stackView.currentItem.snapEnabled !== undefined)
                            stackView.currentItem.snapEnabled = enabled;
                    }

                    onSplitAtPlayhead: {
                        if (stackView.currentItem && typeof stackView.currentItem.splitAtPlayhead === 'function')
                            stackView.currentItem.splitAtPlayhead();
                    }

                    onDeleteSelected: {
                        if (stackView.currentItem && typeof stackView.currentItem.deleteSelected === 'function')
                            stackView.currentItem.deleteSelected();
                    }

                    onRippleDeleteSelected: {
                        if (stackView.currentItem && typeof stackView.currentItem.rippleDeleteSelected === 'function')
                            stackView.currentItem.rippleDeleteSelected();
                    }

                    onDuplicateSelected: {
                        if (stackView.currentItem && typeof stackView.currentItem.duplicateSelected === 'function')
                            stackView.currentItem.duplicateSelected();
                    }

                    onAnimateFadersToggled: function(enabled) {
                        mainWindow.animateFaders = enabled;
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                }

                StackView {
                    id: stackView
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    initialItem: timelinePage
                }

                BottomTabBar {
                    id: bottomTabBar

                    Layout.fillWidth: true

                    onTabClicked: function (index) {
                        switch (index) {
                        case 0:
                            stackView.replace(timelinePage);
                            break;
                        case 1:
                            stackView.replace(nodeEditorPage);
                            break;
                        case 2:
                            stackView.replace(keyframeEditorPage);
                            break;
                        case 3:
                            stackView.replace(audioPage);
                            break;
                        case 4:
                            stackView.replace(colorGradingPage);
                            break;
                        }
                    }
                }

                Component {
                    id: timelinePage

                    Timeline {
                        timelineModel: globalTimelineModel
                        selectedObject: selectedObject

                        onObjectSelected: function (obj) {
                            mainWindow.selectedObject = obj;
                        }

                        onElementSelected: function (element) {
                            viewport.setSelectedLayers([element]);
                        }
                    }
                }

                Component {
                    id: audioPage

                    AudioEditor {
                        timelineModel: globalTimelineModel
                        selectedObject: mainWindow.selectedObject
                        animateFaders: mainWindow.animateFaders
                    }
                }

                 Component {
                    id: colorGradingPage

                    ColorGradingEditor {
                        timelineModel: globalTimelineModel
                        selectedObject: mainWindow.selectedObject
                    }
                }

                Component {
                    id: nodeEditorPage

                    NodeEditor {
                        timelineModel: globalTimelineModel
                        selectedObject: mainWindow.selectedObject
                    }
                }

                Component {
                    id: keyframeEditorPage

                    KeyframeEditor {
                        timelineModel: globalTimelineModel
                        selectedObject: selectedObject
                    }
                }
            }
        }
    }

    property Component shapeLayerComponent: ShapeLayer {}
    property Component compositionComponent: Composition {}
    property Component textLayerComponent: TextLayer {}
    property Component imageLayerComponent: ImageLayer {}
    property Component audioLayerComponent: AudioLayer {}
    property Component videoLayerComponent: VideoLayer {}
    property var selectedObject: null

    ExportController {
        id: exportController
        onExportFinished: function (success, message) {
            console.log("Export " + (success ? "succeeded" : "failed") + ": " + message);
        }
    }

    function getBaseName(url) {
        var str = String(url);
        var lastSlash = str.lastIndexOf("/");
        var lastDot = str.lastIndexOf(".");
        if (lastSlash === -1) lastSlash = str.lastIndexOf("\\");
        var name = str.substring(lastSlash + 1, lastDot === -1 ? str.length : lastDot);
        return decodeURIComponent(name);
    }

    FileDialog {
        id: importImageDialog
        title: qsTr("Import Image")
        nameFilters: ["Images (*.png *.jpg *.jpeg *.gif *.bmp *.webp)", "All Files (*)"]
        onAccepted: {
            if (!importImageDialog.selectedFile) return;
            var url = importImageDialog.selectedFile;
            var layer = imageLayerComponent.createObject(project, {
                name: getBaseName(url),
                source: url
            });
            project.addAsset(layer);
            selectedObject = layer;
            project.captureSnapshot();
        }
    }

    FileDialog {
        id: importAudioDialog
        title: qsTr("Import Audio")
        nameFilters: ["Audio (*.wav *.mp3 *.ogg *.flac *.aac *.m4a)", "All Files (*)"]
        onAccepted: {
            if (!importAudioDialog.selectedFile) return;
            var url = importAudioDialog.selectedFile;
            var layer = audioLayerComponent.createObject(project, {
                name: getBaseName(url),
                source: url
            });
            project.addAsset(layer);
            selectedObject = layer;
            project.captureSnapshot();
        }
    }

    FileDialog {
        id: importVideoDialog
        title: qsTr("Import Video")
        nameFilters: ["Video (*.mp4 *.mov *.avi *.mkv *.webm *.m4v *.ts)", "All Files (*)"]
        onAccepted: {
            if (!importVideoDialog.selectedFile) return;
            var url = importVideoDialog.selectedFile;
            var baseName = getBaseName(url);
            
            // 1. Create Video Layer
            var vLayer = videoLayerComponent.createObject(project, {
                name: baseName + " (Video)",
                source: url
            });
            project.addAsset(vLayer);
            
            // 2. Extract and Create Audio Layer
            var wavPath = project.extractAudioFromVideo(url, baseName);
            if (wavPath && wavPath.length > 0) {
                var aLayer = audioLayerComponent.createObject(project, {
                    name: baseName + " (Audio)",
                    source: wavPath
                });
                project.addAsset(aLayer);
            }
            
            selectedObject = vLayer;
            project.captureSnapshot();
        }
    }

    FileDialog {
        id: exportDialog
        title: qsTr("Select Export Folder")
        acceptLabel: qsTr("Export Animation")
        fileMode: FileDialog.Directory
        onAccepted: function () {
            var comp = project.activeComposition;
            if (!comp || !globalTimelineModel)
                return;
            var folderUrl = exportDialog.selectedFolder || exportDialog.currentFolder;
            if (!folderUrl)
                return;
            var folder = String(folderUrl).replace(/^file:\/\//, "");
            var videoPath = folder + "/output.mp4";
            exportController.exportSequence(comp, globalTimelineModel, folder, videoPath);
        }
    }

    PreferencesDialog {
        id: prefsDialog
        project: project
    }

    FileDialog {
        id: exportImageSequenceDialog
        title: qsTr("Select Export Folder for Image Sequence")
        acceptLabel: qsTr("Export PNG Sequence")
        fileMode: FileDialog.Directory
        onAccepted: function () {
            var comp = project.activeComposition;
            if (!comp || !globalTimelineModel)
                return;
            var folderUrl = exportImageSequenceDialog.selectedFolder || exportImageSequenceDialog.currentFolder;
            if (!folderUrl)
                return;
            var folder = String(folderUrl).replace(/^file:\/\//, "");
            exportController.exportSequence(comp, globalTimelineModel, folder);
        }
    }

    FileDialog {
        id: openDialog
        title: qsTr("Open Project")
        acceptLabel: qsTr("Open")
        nameFilters: ["MOKM Project (*.mokm)", "All Files (*)"]
        onAccepted: {
            if (openDialog.selectedFile) {
                project.loadFromFile(openDialog.selectedFile);
                globalTimelineModel.composition = project.activeComposition;
                selectedObject = null;
                if (stackView.currentItem && stackView.currentItem.clearSelection)
                    stackView.currentItem.clearSelection();
            }
        }
    }

    FileDialog {
        id: saveAsDialog
        title: qsTr("Save Project As")
        acceptLabel: qsTr("Save")
        nameFilters: ["MOKM Project (*.mokm)", "All Files (*)"]
        fileMode: FileDialog.SaveFile
        onAccepted: {
            if (saveAsDialog.selectedFile)
                project.saveToFile(saveAsDialog.selectedFile);
        }
    }

    function createShapeLayer(type) {
        if (!project)
            return;
        var names = ["Rectangle", "Ellipse", "Circle", "Triangle"];
        var name = (type >= 0 && type < names.length ? names[type] : "Shape") + " " + (project.assets.length + 1);
        var layer = shapeLayerComponent.createObject(project, {
            name: name,
            shapeType: type,
            shapeWidth: 200,
            shapeHeight: 200,
            color: Theme.primary
        });
        project.addAsset(layer);
        selectedObject = layer;
        project.captureSnapshot();
    }

    function deleteSelectedLayer() {
        if (!project || !project.activeComposition)
            return;
        var comp = project.activeComposition;
        if (!selectedObject)
            return;
        // Handle different object types
        if (selectedObject.deleteStrip) {
            selectedObject.deleteStrip();
        } else if (selectedObject.deleteTrack) {
            selectedObject.deleteTrack();
        } else if (selectedObject.deleteLayer) {
            selectedObject.deleteLayer();
        } else {
            // Try to find and remove strip element across all layers/tracks/strips
            for (var li = 0; li < comp.layerCount(); li++) {
                var tl = comp.layerAt(li);
                for (var ti = 0; ti < tl.trackCount; ti++) {
                    var track = tl.trackAt(ti);
                    for (var si = 0; si < track.stripCount(); si++) {
                        var strip = track.stripAt(si);
                        if (strip.element === selectedObject) {
                            track.removeStrip(strip);
                            project.captureSnapshot();
                            selectedObject = null;
                            return;
                        }
                    }
                }
            }
        }
        selectedObject = null;
        project.captureSnapshot();
    }

    function createTextLayer() {
        if (!project)
            return;
        var layer = textLayerComponent.createObject(project, {
            name: "Text " + (project.assets.length + 1),
            text: "Hello MOKM",
            color: Theme.foreground,
            fontSize: 48
        });
        project.addAsset(layer);
        selectedObject = layer;
        project.captureSnapshot();
    }

    function newProject() {
        // Clear and recreate
        var comp = project.activeComposition;
        if (comp) {
            comp.clearLayers();
        }
        while (project.assetCount > 0)
            project.removeAsset(project.assetAt(0));
        project.setName("Untitled");
        globalTimelineModel.composition = comp;
        selectedObject = null;
        if (stackView.currentItem && stackView.currentItem.clearSelection)
            stackView.currentItem.clearSelection();
        // Reset undo/redo
        project.clearUndoRedo();
    }

    function saveProject() {
        if (project.filePath.toString().length > 0) {
            project.saveToFile(project.filePath);
        } else {
            saveAsDialog.open();
        }
    }

    // ── Frameless window resize handles ──
    property int resizeMargin: 5

    component ResizeHandle: MouseArea {
        property int edgeLeft: 0
        property int edgeRight: 0
        property int edgeTop: 0
        property int edgeBottom: 0
        property int startX: 0
        property int startY: 0
        property int startW: 0
        property int startH: 0

        onPressed: function (m) {
            startX = m.x;
            startY = m.y;
            if (mainWindow.window) {
                startW = mainWindow.window.width;
                startH = mainWindow.window.height;
            }
        }
        onPositionChanged: function (m) {
            if (!(m.buttons & Qt.LeftButton) || !mainWindow.window)
                return;
            var dx = m.x - startX;
            var dy = m.y - startY;
            var win = mainWindow.window;
            if (edgeLeft) {
                win.setX(win.x + dx);
                win.setWidth(startW - dx);
            }
            if (edgeRight) {
                win.setWidth(startW + dx);
            }
            if (edgeTop) {
                win.setY(win.y + dy);
                win.setHeight(startH - dy);
            }
            if (edgeBottom) {
                win.setHeight(startH + dy);
            }
        }
    }

    ResizeHandle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: mainWindow.resizeMargin
        edgeLeft: 1
        cursorShape: Qt.SizeHorCursor
    }
    ResizeHandle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: mainWindow.resizeMargin
        edgeRight: 1
        cursorShape: Qt.SizeHorCursor
    }
    ResizeHandle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: mainWindow.resizeMargin
        edgeTop: 1
        cursorShape: Qt.SizeVerCursor
    }
    ResizeHandle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: mainWindow.resizeMargin
        edgeBottom: 1
        cursorShape: Qt.SizeVerCursor
    }
    ResizeHandle {
        anchors.left: parent.left
        anchors.top: parent.top
        width: mainWindow.resizeMargin * 2
        height: mainWindow.resizeMargin * 2
        edgeLeft: 1
        edgeTop: 1
        cursorShape: Qt.SizeFDiagCursor
    }
    ResizeHandle {
        anchors.right: parent.right
        anchors.top: parent.top
        width: mainWindow.resizeMargin * 2
        height: mainWindow.resizeMargin * 2
        edgeRight: 1
        edgeTop: 1
        cursorShape: Qt.SizeBDiagCursor
    }
    ResizeHandle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: mainWindow.resizeMargin * 2
        height: mainWindow.resizeMargin * 2
        edgeLeft: 1
        edgeBottom: 1
        cursorShape: Qt.SizeBDiagCursor
    }
    ResizeHandle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: mainWindow.resizeMargin * 2
        height: mainWindow.resizeMargin * 2
        edgeRight: 1
        edgeBottom: 1
        cursorShape: Qt.SizeFDiagCursor
    }

    Component.onCompleted: {
        var cfg = _startupConfig;
        if (cfg && cfg.mode === "new") {
            project.name = cfg.projectName || "Untitled";
            var comp = project.activeComposition;
            if (!comp) {
                comp = compositionComponent.createObject(project, {});
                project.addComposition(comp);
                project.activeComposition = comp;
            }
            comp.width = cfg.width || 1920;
            comp.height = cfg.height || 1080;
            comp.frameRate = cfg.fps || 30;
            project.frameRate = cfg.fps || 30;
            comp.duration = cfg.duration || 150;
            var tl = comp.ensureDefaultLayer();
            var track = tl.trackAt(0);
            track.trackType = Track.Video;
            comp.rebuildFlatLayers();
            globalTimelineModel.composition = comp;
        } else if (cfg && cfg.mode === "open") {
            var fileUrl = cfg.filePath;
            if (fileUrl) {
                project.loadFromFile(fileUrl);
                globalTimelineModel.composition = project.activeComposition;
            }
        } else {
            // Fallback: ensure basic setup
            var comp = project.activeComposition;
            if (!comp) {
                comp = compositionComponent.createObject(project, {});
                project.addComposition(comp);
                project.activeComposition = comp;
            }
            var tl = comp.ensureDefaultLayer();
            var track = tl.trackAt(0);
            track.trackType = Track.Video;
            comp.rebuildFlatLayers();
            globalTimelineModel.composition = comp;
        }
        // Wire audio engine to timeline
        if (typeof _audioEngine !== "undefined")
            _audioEngine.timelineModel = globalTimelineModel;

        // Window title
        mainWindow.title = "MOKM Effector — " + (project.name || "Untitled");
        project.nameChanged.connect(function() {
            mainWindow.title = "MOKM Effector — " + (project.name || "Untitled");
        });
    }
}
