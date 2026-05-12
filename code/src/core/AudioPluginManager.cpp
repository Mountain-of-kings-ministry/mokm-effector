#include "AudioPluginManager.h"
#include <juce_audio_processors/juce_audio_processors.h>
#include <QDir>
#include <QSettings>

AudioPluginManager::AudioPluginManager(QObject *parent)
    : QObject(parent)
{
    juce::addHeadlessDefaultFormatsToManager(m_formatManager);
    
    // Auto-scan on initialization
    scanPlugins();
}

void AudioPluginManager::scanPlugins()
{
    m_knownPluginList.clear();
    m_plugins.clear();

    auto formats = m_formatManager.getFormats();

    for (juce::AudioPluginFormat* format : formats)
    {
        if (format == nullptr)
            continue;

        // Optionally add user-defined paths from settings here if available
        juce::FileSearchPath searchPaths = format->getDefaultLocationsToSearch();
        
        juce::PluginDirectoryScanner scanner(
            m_knownPluginList,
            *format,
            searchPaths,
            true,
            juce::File()
        );

        juce::String name;
        while (scanner.scanNextFile(true, name)) { }
    }

    auto allTypes = m_knownPluginList.getTypes();
    for (const auto& desc : allTypes)
    {
        m_plugins.append(new AudioPlugin(desc, this));
    }

    emit pluginsChanged();
}

static qsizetype countPlugins(QQmlListProperty<AudioPlugin>* prop) {
    return static_cast<QList<AudioPlugin*>*>(prop->data)->size();
}
static AudioPlugin* atPlugin(QQmlListProperty<AudioPlugin>* prop, qsizetype index) {
    return static_cast<QList<AudioPlugin*>*>(prop->data)->at(index);
}

QQmlListProperty<AudioPlugin> AudioPluginManager::plugins()
{
    return QQmlListProperty<AudioPlugin>(this, &m_plugins, &countPlugins, &atPlugin);
}
// ... rest of implementation unchanged
