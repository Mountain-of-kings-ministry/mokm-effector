import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import mokm_effector

Window {
    id: mainWindow
    width: 1400
    height: 900
    visible: true
    title: qsTr("MOKM Effector — Untitled")
    color: Theme.background

    // frameless window with topbar
    flags: Qt.FramelessWindowHint

    Project {
        id: project
        onUndoChanged: {
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
            onExportVideoRequested: exportDialog.open()
            onExportImageSequenceRequested: exportImageSequenceDialog.open()
            onPreferencesRequested: prefsDialog.open()

            onNewFileRequested: newProject()
            onOpenFileRequested: openDialog.open()
            onSaveFileRequested: saveProject()
            onSaveAsRequested: saveAsDialog.open()
            onUndoRequested: project.undo()
            onRedoRequested: project.redo()
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
                    project: project

                    onCreateRectLayer: createShapeLayer(ShapeLayer.Rectangle)
                    onCreateCircleLayer: createShapeLayer(ShapeLayer.Circle)
                    onCreateTriangleLayer: createShapeLayer(ShapeLayer.Triangle)
                    onCreateTextLayer: createTextLayer()
                    onLayerSelected: function (layer) {
                        selectedLayer = layer;
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
                            selectedLayer = layer;
                        }
                    }
                }

                PropertiesPanel {
                    SplitView.preferredWidth: 240
                    currentLayer: selectedLayer
                    timelineModel: globalTimelineModel
                }
            }

            ColumnLayout {
                SplitView.preferredHeight: 250
                spacing: 0

                Toolbar {
                    id: toolbar
                    Layout.fillWidth: true

                    timelineModel: globalTimelineModel
                    selectedLayer: selectedLayer
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
                        }
                    }
                }

                Component {
                    id: timelinePage

                    Timeline {
                        timelineModel: globalTimelineModel
                        selectedLayer: selectedLayer
                        project: project

                        onLayerSelected: function (layer) {
                            selectedLayer = layer;
                        }

                        onSelectionChanged: function (layers) {
                            viewport.setSelectedLayers(layers);
                        }
                    }
                }

                Component {
                    id: nodeEditorPage

                    NodeEditor {}
                }

                Component {
                    id: keyframeEditorPage

                    KeyframeEditor {}
                }
            }
        }
    }

    property Component shapeLayerComponent: ShapeLayer {}
    property Component textLayerComponent: TextLayer {}
    property Layer selectedLayer: null

    ExportController {
        id: exportController
        onExportFinished: function (success, message) {
            console.log("Export " + (success ? "succeeded" : "failed") + ": " + message);
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
                selectedLayer = null;
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
        selectedLayer = layer;
        project.captureSnapshot();
    }

    function deleteSelectedLayer() {
        if (!project)
            return;
        var tl = stackView.currentItem;
        var layers = (tl && tl.selectedLayers) ? tl.selectedLayers : [];
        if (layers.length === 0) {
            if (selectedLayer)
                layers = [selectedLayer];
            else
                return;
        }
        var comp = project.activeComposition;
        if (!comp)
            return;
        for (var li = 0; li < layers.length; li++) {
            var layer = layers[li];
            if (!layer)
                continue;
            for (var ti = 0; ti < comp.trackCount; ti++) {
                var track = comp.trackAt(ti);
                if (track.indexOf(layer) >= 0) {
                    track.removeClip(layer);
                    break;
                }
            }
        }
        selectedLayer = null;
        if (tl && tl.clearSelection)
            tl.clearSelection();
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
        selectedLayer = layer;
        project.captureSnapshot();
    }

    function newProject() {
        // Clear and recreate
        var comp = project.activeComposition;
        if (comp) {
            while (comp.trackCount > 0)
                comp.removeTrack(comp.trackAt(0));
        }
        while (project.assetCount > 0)
            project.removeAsset(project.assetAt(0));
        project.setName("Untitled");
        globalTimelineModel.composition = comp;
        selectedLayer = null;
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
        console.log("MAIN_DEBUG: Component.onCompleted, globalTimelineModel=" + (globalTimelineModel !== null));
        var comp = project.activeComposition;
        if (comp && project) {
            console.log("MAIN_DEBUG: creating demo rectangle, comp.trackCount=" + comp.trackCount);
            var rect = shapeLayerComponent.createObject(project, {
                name: "Rectangle 1",
                shapeType: ShapeLayer.Rectangle,
                shapeWidth: 300,
                shapeHeight: 200,
                color: Theme.primary
            });
            project.addAsset(rect);
            var track = comp.trackCount > 0 ? comp.trackAt(0) : comp.addTrack("Track 1");
            var clip = rect.clone(track);
            clip.startFrame = 0;
            clip.duration = 90;
            track.addClip(clip);
            globalTimelineModel.composition = comp;
        }
    }
}
