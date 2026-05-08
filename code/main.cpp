#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "someclass.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    qmlRegisterType<someClass>("kingClass", 1, 0, "SomeClass");

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
