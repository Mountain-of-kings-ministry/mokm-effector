#ifndef AUDIOPLUGINMANAGER_H
#define AUDIOPLUGINMANAGER_H

#include <QObject>
#include <QQmlListProperty>
#include <QStringList>

class AudioPlugin : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString format READ format CONSTANT)
    Q_PROPERTY(QString pluginId READ pluginId CONSTANT)
    Q_PROPERTY(QString vendor READ vendor CONSTANT)
    Q_PROPERTY(QString filePath READ filePath CONSTANT)

public:
    explicit AudioPlugin(const QString &name, const QString &format, 
                        const QString &pluginId, const QString &vendor, 
                        const QString &filePath,
                        QObject* parent = nullptr)
        : QObject(parent), m_name(name), m_format(format), 
          m_pluginId(pluginId), m_vendor(vendor), m_filePath(filePath) {}

    QString name() const { return m_name; }
    QString format() const { return m_format; }
    QString pluginId() const { return m_pluginId; }
    QString vendor() const { return m_vendor; }
    QString filePath() const { return m_filePath; }

private:
    QString m_name;
    QString m_format;
    QString m_pluginId;
    QString m_vendor;
    QString m_filePath;
};

class AudioPlugin;
class EffectInstance;

class AudioPluginManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<AudioPlugin> availablePlugins READ plugins NOTIFY pluginsChanged)

public:
    explicit AudioPluginManager(QObject *parent = nullptr);

    QQmlListProperty<AudioPlugin> plugins();
    Q_INVOKABLE void scanPlugins();

    Q_INVOKABLE EffectInstance* createInstance(AudioPlugin *plugin, QObject *parent = nullptr);
    Q_INVOKABLE EffectInstance* createInstanceById(const QString &pluginId, const QString &format, QObject *parent = nullptr);

signals:
    void pluginsChanged();

private:
    void scanVST3();
    void scanCLAP();

    QList<AudioPlugin*> m_plugins;
};

#endif
