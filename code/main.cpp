#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSurfaceFormat>

#include "src/core/Layer.h"
#include "src/core/ShapeLayer.h"
#include "src/core/TextLayer.h"
#include "src/core/Composition.h"
#include "src/core/Project.h"
#include "src/core/Keyframe.h"
#include "src/viewport/ThorVGViewport.h"
#include "src/timeline/TimelineModel.h"
#include "src/core/ExportController.h"
#include "src/core/Track.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("MOKM Effector");
    app.setOrganizationName("MOKM");

    QSurfaceFormat fmt;
    fmt.setSamples(4);
    QSurfaceFormat::setDefaultFormat(fmt);

    qmlRegisterType<Layer>("mokm_effector", 1, 0, "Layer");
    qmlRegisterType<ShapeLayer>("mokm_effector", 1, 0, "ShapeLayer");
    qmlRegisterType<TextLayer>("mokm_effector", 1, 0, "TextLayer");
    qmlRegisterType<Composition>("mokm_effector", 1, 0, "Composition");
    qmlRegisterType<Project>("mokm_effector", 1, 0, "Project");
    qmlRegisterType<Keyframe>("mokm_effector", 1, 0, "Keyframe");
    qmlRegisterType<ThorVGViewport>("mokm_effector", 1, 0, "ThorVGViewport");
    qmlRegisterType<TimelineModel>("mokm_effector", 1, 0, "TimelineModel");
    qmlRegisterType<ExportController>("mokm_effector", 1, 0, "ExportController");
    qmlRegisterType<Track>("mokm_effector", 1, 0, "Track");

    QQmlApplicationEngine engine;
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
