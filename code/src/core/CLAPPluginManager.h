#ifndef CLAPPLUGINMANAGER_H
#define CLAPPLUGINMANAGER_H

#include <QObject>
#include <QQmlListProperty>
#include <QVector>

class CLAPPlugin;
class CLAPInstance;

class CLAPPluginManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<CLAPPlugin> plugins READ plugins NOTIFY pluginsChanged)
    Q_PROPERTY(bool scanDone READ scanDone NOTIFY pluginsChanged)
public:
    explicit CLAPPluginManager(QObject *parent = nullptr);

    QQmlListProperty<CLAPPlugin> plugins();
    bool scanDone() const { return m_scanDone; }

    Q_INVOKABLE void rescan();

    Q_INVOKABLE CLAPPlugin* pluginById(const QString &pluginId) const;

    Q_INVOKABLE CLAPInstance* createInstance(const QString &pluginId, QObject *parent = nullptr);

signals:
    void pluginsChanged();

private:
    void scanPath(const QString &path);
    QVector<CLAPPlugin*> m_plugins;
    bool m_scanDone = false;
};

#endif
