import QtQuick
import QtQuick.Layouts
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
    }

    TimelineModel {
        id: timelineModel
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TopBar {
            id: topBar
            Layout.fillWidth: true

            onCreateRectLayer: createShapeLayer(ShapeLayer.Rectangle)
            onCreateCircleLayer: createShapeLayer(ShapeLayer.Circle)
            onCreateTriangleLayer: createShapeLayer(ShapeLayer.Triangle)
            onCreateTextLayer: createTextLayer()
            onDeleteSelectedLayer: deleteSelectedLayer()
            onExportVideoRequested: exportDialog.open()
            onExportImageSequenceRequested: exportImageSequenceDialog.open()
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 1

            ProjectBin {
                id: projectBin
                Layout.preferredWidth: 220
                Layout.fillHeight: true
                composition: project.activeComposition

                onCreateRectLayer: createShapeLayer(ShapeLayer.Rectangle)
                onCreateCircleLayer: createShapeLayer(ShapeLayer.Circle)
                onCreateTriangleLayer: createShapeLayer(ShapeLayer.Triangle)
                onCreateTextLayer: createTextLayer()
                onLayerSelected: function(layer) { selectedLayer = layer }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.background

                ThorVGViewport {
                    id: viewport
                    anchors.fill: parent
                    anchors.margins: 1
                    composition: project.activeComposition
                    currentFrame: timelineModel.currentFrame
                }
            }

            PropertiesPanel {
                Layout.preferredWidth: 240
                Layout.fillHeight: true
                currentLayer: selectedLayer
                timelineModel: timelineModel
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Toolbar {
                id: toolbar
                Layout.fillWidth: true
                timelineModel: timelineModel
                selectedLayer: selectedLayer
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            Timeline {
                id: timeline
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                Layout.minimumHeight: 80
                timelineModel: timelineModel
                selectedLayer: selectedLayer
                onLayerSelected: function (layer) {
                    selectedLayer = layer;
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
            if (!comp || !timelineModel) return;
            var folderUrl = exportDialog.selectedFolder || exportDialog.currentFolder;
            if (!folderUrl) return;
            var folder = String(folderUrl).replace(/^file:\/\//, "");
            var videoPath = folder + "/output.mp4";
            exportController.exportSequence(comp, timelineModel, folder, videoPath);
        }
    }

    FileDialog {
        id: exportImageSequenceDialog
        title: qsTr("Select Export Folder for Image Sequence")
        acceptLabel: qsTr("Export PNG Sequence")
        fileMode: FileDialog.Directory
        onAccepted: function () {
            var comp = project.activeComposition;
            if (!comp || !timelineModel) return;
            var folderUrl = exportImageSequenceDialog.selectedFolder || exportImageSequenceDialog.currentFolder;
            if (!folderUrl) return;
            var folder = String(folderUrl).replace(/^file:\/\//, "");
            exportController.exportSequence(comp, timelineModel, folder);
        }
    }

    function createShapeLayer(type) {
        var comp = project.activeComposition;
        if (!comp)
            return;
        var names = ["Rectangle", "Ellipse", "Circle", "Triangle"];
        var name = (type >= 0 && type < names.length ? names[type] : "Shape") + " " + (comp.layers.length + 1);
        var layer = shapeLayerComponent.createObject(comp, {
            name: name,
            shapeType: type,
            shapeWidth: 200,
            shapeHeight: 200,
            color: Theme.primary
        });
        comp.addLayer(layer);
        selectedLayer = layer;
    }

    function deleteSelectedLayer() {
        if (!selectedLayer)
            return;
        var comp = project.activeComposition;
        if (!comp)
            return;
        comp.removeLayer(selectedLayer);
        selectedLayer = null;
    }

    function createTextLayer() {
        var comp = project.activeComposition;
        if (!comp)
            return;
        var layer = textLayerComponent.createObject(comp, {
            name: "Text " + (comp.layers.length + 1),
            text: "Hello MOKM",
            color: Theme.foreground,
            fontSize: 48
        });
        comp.addLayer(layer);
        selectedLayer = layer;
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
        var comp = project.activeComposition;
        if (comp) {
            var rect = shapeLayerComponent.createObject(comp, {
                name: "Rectangle 1",
                shapeType: ShapeLayer.Rectangle,
                shapeWidth: 300,
                shapeHeight: 200,
                color: Theme.primary
            });
            comp.addLayer(rect);
            timelineModel.composition = comp;
        }
    }
}
