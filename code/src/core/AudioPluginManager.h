#ifndef AUDIOPLUGINMANAGER_H
#define AUDIOPLUGINMANAGER_H

#include <QObject>
#include <QQmlListProperty>
#include "JucePlugin.h"
#include <juce_audio_processors/juce_audio_processors.h>

class AudioPlugin : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString name READ name CONSTANT)
public:
    explicit AudioPlugin(const juce::PluginDescription& desc, QObject* parent = nullptr)
        : QObject(parent), m_desc(desc) {}

    QString name() const {
        return QString::fromStdString(m_desc.name.toStdString());
    }

    const juce::PluginDescription& description() const { return m_desc; }

private:
    juce::PluginDescription m_desc;
};

class AudioPluginManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<AudioPlugin> availablePlugins READ plugins NOTIFY pluginsChanged)

public:
    explicit AudioPluginManager(QObject *parent = nullptr);

    QQmlListProperty<AudioPlugin> plugins();
    Q_INVOKABLE void scanPlugins();

signals:
    void pluginsChanged();

private:
    juce::AudioPluginFormatManager m_formatManager;
    juce::KnownPluginList m_knownPluginList;   // ← fixed
    QList<AudioPlugin*> m_plugins;
};

#endif
