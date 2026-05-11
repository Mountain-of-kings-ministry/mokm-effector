#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSurfaceFormat>

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
#include "src/core/OFXPluginManager.h"
#include "src/core/OFXPlugin.h"

#ifdef MOKM_ENABLE_CLAP
#include "src/core/CLAPPluginManager.h"
#include "src/core/CLAPPlugin.h"
#include "src/core/CLAPInstance.h"
#endif

#ifdef MOKM_ENABLE_NODES
#include "src/nodes/NodeGraph.h"
#include "src/nodes/NodeStrip.h"
#include "src/nodes/NodeGraphView.h"
#endif

int main(int argc, char *argv[])
{
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

    qmlRegisterType<OFXPlugin>("mokm_effector", 1, 0, "OFXPlugin");
    qmlRegisterType<OFXPluginManager>("mokm_effector", 1, 0, "OFXPluginManager");
#ifdef MOKM_ENABLE_CLAP
    qmlRegisterType<CLAPPlugin>("mokm_effector", 1, 0, "CLAPPlugin");
    qmlRegisterType<CLAPPluginManager>("mokm_effector", 1, 0, "CLAPPluginManager");
    qmlRegisterType<CLAPInstance>("mokm_effector", 1, 0, "CLAPInstance");
#endif

    qmlRegisterSingletonType<AppSettings>("mokm_effector", 1, 0, "AppSettings",
        [](QQmlEngine *, QJSEngine *) -> QObject * {
            return new AppSettings();
        });

#ifdef MOKM_ENABLE_NODES
    qmlRegisterType<NodeGraph>("mokm_effector", 1, 0, "NodeGraph");
    qmlRegisterType<NodeStrip>("mokm_effector", 1, 0, "NodeStrip");
    qmlRegisterType<NodeGraphView>("mokm_effector", 1, 0, "NodeGraphView");
#endif

    QQmlApplicationEngine engine;

    // Shared context properties
    auto *startupConfig = new StartupConfig(&engine);
    engine.rootContext()->setContextProperty("_startupConfig", startupConfig);

    auto *project = new Project(&engine);
    engine.rootContext()->setContextProperty("project", project);

    // Plugin managers
    auto *ofxManager = new OFXPluginManager(&engine);
    engine.rootContext()->setContextProperty("_ofxPluginManager", ofxManager);

#ifdef MOKM_ENABLE_CLAP
    auto *clapManager = new CLAPPluginManager(&engine);
    engine.rootContext()->setContextProperty("_clapPluginManager", clapManager);
#endif

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []()
        { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("mokm_effector", "ProjectProperties");

    return QCoreApplication::exec();
}
