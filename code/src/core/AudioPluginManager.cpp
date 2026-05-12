#include "AudioPluginManager.h"
#include <juce_audio_processors/juce_audio_processors.h>

// AudioPluginManager::AudioPluginManager(QObject *parent) : QObject(parent)
// {
//     m_formatManager.addDefaultFormats();
// }
//
AudioPluginManager::AudioPluginManager(QObject *parent)
    : QObject(parent)
{
    juce::addHeadlessDefaultFormatsToManager(m_formatManager);
}

void AudioPluginManager::scanPlugins()
{
    m_knownPluginList.clear();
    m_plugins.clear();

    auto formats = m_formatManager.getFormats();   // Array<AudioPluginFormat*>

    for (juce::AudioPluginFormat* format : formats)
    {
        if (format == nullptr)
            continue;

        juce::PluginDirectoryScanner scanner(
            m_knownPluginList,
            *format,                                      // single format
            format->getDefaultLocationsToSearch(),        // better than hard-coded path
            true,                                         // recursive
            juce::File()                                  // dead man's pedal
        );

        juce::String name;
        while (scanner.scanNextFile(true, name))
        {
            // You can log progress here if you want: qDebug() << "Scanning:" << name;
        }
    }

    // Populate your QML list
    for (int i = 0; i < m_knownPluginList.getNumTypes(); ++i)
    {
        const juce::PluginDescription* desc = m_knownPluginList.getType(i);
        if (desc)
            m_plugins.append(new AudioPlugin(*desc, this));
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
