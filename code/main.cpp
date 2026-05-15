#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSurfaceFormat>
#include <QColor>
#include <QDir>

#include "src/core/Layer.h"
#include "src/core/ShapeLayer.h"
#include "src/viewport/ColorWheelItem.h"
#include "src/core/TextLayer.h"
#include "src/core/ImageLayer.h"
#include "src/core/AudioLayer.h"
#include "src/core/VideoLayer.h"
#include "src/core/Composition.h"
#include "src/core/Project.h"
#include "src/core/Keyframe.h"
#include "src/viewport/ThorVGViewport.h"
#include "src/timeline/TimelineModel.h"
#include "src/core/ExportController.h"
#include "src/core/Track.h"
#include "src/core/Strip.h"
#include "src/core/TimelineLayer.h"
#include "src/core/StartupConfig.h"
#include "src/core/AppSettings.h"
#include "src/core/AudioEngine.h"
#include "src/core/OFXPluginManager.h"
#include "src/core/OFXPlugin.h"
#include "src/core/AudioPluginManager.h"
#include "src/core/EffectInstance.h"
#include "src/core/EffectChain.h"
#include "src/core/VST3Instance.h"
#include "src/core/CLAPInstance.h"

#ifdef MOKM_ENABLE_CLAP
#include "src/core/CLAPPluginManager.h"
#include "src/core/CLAPPlugin.h"
#endif

#ifdef MOKM_ENABLE_NODES
#include "NodeEditor/GraphModel.h"
#include "NodeEditor/DataFlowEngine.h"
#include "NodeEditor/UndoManager.h"
#include "NodeEditor/BaseNode.h"
#include "NodeEditor/DefaultNodes.h"
#include "src/nodes/MOKMNodes.h"
#endif

int main(int argc, char *argv[])
{
    // Suppress libpng duplicate eXIf warning (harmless) — must be before QApplication
    qputenv("QT_LOGGING_RULES", "qt.gui.imageio.warning=false");

    QApplication app(argc, argv);
    app.setApplicationName("MOKM Effector");
    app.setOrganizationName("MOKM");

    QSurfaceFormat fmt;
    fmt.setSamples(4);
    QSurfaceFormat::setDefaultFormat(fmt);

    qmlRegisterType<Layer>("mokm_effector", 1, 0, "Layer");
    qmlRegisterType<ShapeLayer>("mokm_effector", 1, 0, "ShapeLayer");
    qmlRegisterType<TextLayer>("mokm_effector", 1, 0, "TextLayer");
    qmlRegisterType<ImageLayer>("mokm_effector", 1, 0, "ImageLayer");
    qmlRegisterType<AudioLayer>("mokm_effector", 1, 0, "AudioLayer");
    qmlRegisterType<VideoLayer>("mokm_effector", 1, 0, "VideoLayer");
    qmlRegisterType<Composition>("mokm_effector", 1, 0, "Composition");
    qmlRegisterType<Project>("mokm_effector", 1, 0, "Project");
    qmlRegisterType<Keyframe>("mokm_effector", 1, 0, "Keyframe");
    qmlRegisterType<ThorVGViewport>("mokm_effector", 1, 0, "ThorVGViewport");
    qmlRegisterType<ColorWheelItem>("mokm_effector", 1, 0, "ColorWheelItem");
    qmlRegisterType<TimelineModel>("mokm_effector", 1, 0, "TimelineModel");
    qmlRegisterType<ExportController>("mokm_effector", 1, 0, "ExportController");
    qmlRegisterType<Track>("mokm_effector", 1, 0, "Track");
    qmlRegisterType<Strip>("mokm_effector", 1, 0, "Strip");
    qmlRegisterType<TimelineLayer>("mokm_effector", 1, 0, "TimelineLayer");
    qmlRegisterType<EffectInstance>("mokm_effector", 1, 0, "EffectInstance");
    qmlRegisterType<EffectChain>("mokm_effector", 1, 0, "EffectChain");
    qmlRegisterType<AudioPlugin>("mokm_effector", 1, 0, "AudioPlugin");
    qmlRegisterType<VST3Instance>("mokm_effector", 1, 0, "VST3Instance");
    qmlRegisterType<CLAPInstance>("mokm_effector", 1, 0, "CLAPInstance");

    qmlRegisterType<OFXPlugin>("mokm_effector", 1, 0, "OFXPlugin");
    qmlRegisterType<OFXPluginManager>("mokm_effector", 1, 0, "OFXPluginManager");
#ifdef MOKM_ENABLE_CLAP
    qmlRegisterType<CLAPPlugin>("mokm_effector", 1, 0, "CLAPPlugin");
    qmlRegisterType<CLAPPluginManager>("mokm_effector", 1, 0, "CLAPPluginManager");
#endif

    qmlRegisterSingletonType<AppSettings>("mokm_effector", 1, 0, "AppSettings",
                                          [](QQmlEngine *, QJSEngine *) -> QObject *
                                          {
                                              return new AppSettings();
                                          });

    QQmlApplicationEngine engine;

    // Shared context properties
    auto *startupConfig = new StartupConfig(&engine);
    engine.rootContext()->setContextProperty("_startupConfig", startupConfig);

    auto *project = new Project(&engine);
    engine.rootContext()->setContextProperty("project", project);

    // Plugin managers
    auto *ofxManager = new OFXPluginManager(&engine);
    engine.rootContext()->setContextProperty("_ofxPluginManager", ofxManager);
    
    // Audio plugin manager (VST3 + CLAP)
    auto *pluginManager = new AudioPluginManager(&engine);
    engine.rootContext()->setContextProperty("_audioPluginManager", pluginManager);


    // Audio engine
    auto *audioEngine = new AudioEngine(&engine);
    engine.rootContext()->setContextProperty("_audioEngine", audioEngine);

#ifdef MOKM_ENABLE_NODES
    auto *graphModel = new NodeEditor::GraphModel(&engine);
    auto *undoManager = new NodeEditor::UndoManager(graphModel, &engine);
    auto *dataFlowEngine = new NodeEditor::DataFlowEngine(graphModel, &engine);

    // === Proper Node Registration ===
    NodeEditor::registerDefaultNodeTypes(graphModel);

    // Register MOKM-specific nodes (only once!)
    NodeEditor::registerMOKMNodeTypes(graphModel);

    // If you have more node sets in the future:
    // NodeEditor::registerSomeOtherNodes(graphModel);

    engine.addImportPath(
        QDir(QCoreApplication::applicationDirPath())
            .absoluteFilePath("../../third_parties/Qt-Node-editor/build/default"));

    engine.rootContext()->setContextProperty("_graphModel", graphModel);
    engine.rootContext()->setContextProperty("_undoManager", undoManager);
    engine.rootContext()->setContextProperty("_dataFlowEngine", dataFlowEngine);
#endif

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []()
        { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("mokm_effector", "SplashScreen");

    return QCoreApplication::exec();
}
