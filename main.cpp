#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDir>
#include <iostream>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    // Set the assets path as a context property - can be overridden with MODEL_PATH env var
    QString modelPath = qEnvironmentVariable("MODEL_PATH");
    if (modelPath.isEmpty()) {
        // Default to application directory
        modelPath = "file://" + QDir::currentPath() + "/model.glb";
    }
    engine.rootContext()->setContextProperty("modelPath", modelPath);

    const QUrl url("qrc:/demo/QML/main.qml");
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    std::cout << "Hello Torizon!" << std::endl;

    return app.exec();
}
