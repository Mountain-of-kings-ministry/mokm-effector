#ifndef OFXPLUGINMANAGER_H
#define OFXPLUGINMANAGER_H

#include <QObject>
#include <QQmlListProperty>
#include <QVector>

class OFXPlugin;

class OFXPluginManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<OFXPlugin> plugins READ plugins NOTIFY pluginsChanged)
    Q_PROPERTY(bool scanDone READ scanDone NOTIFY pluginsChanged)
public:
    explicit OFXPluginManager(QObject *parent = nullptr);

    QQmlListProperty<OFXPlugin> plugins();
    bool scanDone() const { return m_scanDone; }

    Q_INVOKABLE void rescan();

    Q_INVOKABLE OFXPlugin* pluginByIdentifier(const QString &identifier) const;

    Q_INVOKABLE void applyPluginToLayer(OFXPlugin *plugin, QObject *layer);

signals:
    void pluginsChanged();

private:
    void scanPath(const QString &path);
    QVector<OFXPlugin*> m_plugins;
    bool m_scanDone = false;
};

#endif
