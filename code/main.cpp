#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include <QQmlContext>
#include "src/functions/core/MokmProjectManager.h"
#include "src/functions/core/MokmUndoManager.h"
#include "src/functions/database/MediaBinModel.h"
#include "src/functions/timeline/TimelineModel.h"
#include "src/functions/timeline/PlayheadController.h"

#include "src/functions/database/MediaBinImageProvider.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Initialize logic singletons
    new MokmProjectManager(&app);
    new MokmUndoManager(&app);
    new MediaBinModel(&app);
    new TimelineModel(&app);
    new PlayheadController(&app);

    // Expose Singletons to QML
    qmlRegisterSingletonInstance("Mokm.Core", 1, 0, "ProjectManager", MokmProjectManager::instance());
    qmlRegisterSingletonInstance("Mokm.Core", 1, 0, "UndoManager", MokmUndoManager::instance());
    qmlRegisterSingletonInstance("Mokm.Database", 1, 0, "MediaBinModel", MediaBinModel::instance());
    qmlRegisterSingletonInstance("Mokm.Timeline", 1, 0, "TimelineModel", TimelineModel::instance());
    qmlRegisterSingletonInstance("Mokm.Timeline", 1, 0, "PlayheadController", PlayheadController::instance());

    QQmlApplicationEngine engine;
    engine.addImageProvider(QLatin1String("media-bin"), new MediaBinImageProvider());

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []()
        { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(QUrl(QStringLiteral("qrc:/untitled/src/ui/Main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return QCoreApplication::exec();
}
