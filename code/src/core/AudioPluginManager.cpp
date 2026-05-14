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

// #include "AudioPluginManager.h"
// #include <QDebug>
// #include <QDir>                    // ← Added
// #include <QCoreApplication>        // ← Added for processEvents

// AudioPlugin::AudioPlugin(const juce::PluginDescription& desc, QObject* parent)
//     : QObject(parent), m_desc(desc) {}

// QString AudioPlugin::name() const {
//     return QString::fromStdString(m_desc.name.toStdString());
// }

// QString AudioPlugin::format() const {
//     return QString::fromStdString(m_desc.pluginFormatName.toStdString());
// }

// AudioPluginManager::AudioPluginManager(QObject *parent)
//     : QObject(parent)
// {
//     juce::addHeadlessDefaultFormatsToManager(m_formatManager);
//     scanPlugins();
// }

// void AudioPluginManager::rescan() { scanPlugins(); }

// void AudioPluginManager::scanPlugins()
// {
//     m_plugins.clear();
//     m_knownPluginList.clear();

//     auto formats = m_formatManager.getFormats();

//     for (juce::AudioPluginFormat* format : formats)
//     {
//         if (format == nullptr) continue;
//         scanFormat(format);
//     }

//     auto allTypes = m_knownPluginList.getTypes();
//     for (const auto& desc : allTypes)
//     {
//         m_plugins.append(new AudioPlugin(desc, this));
//     }

//     qDebug() << "=== PLUGIN SCAN COMPLETE ===";
//     qDebug() << "Found" << m_plugins.size() << "audio plugins total";
//     qDebug() << "=== SCANNED PLUGINS ===";
//     for (auto* p : m_plugins) {
//         qDebug() << p->format() << ":" << p->name();
//     }

//     emit pluginsChanged();
// }

// void AudioPluginManager::scanFormat(juce::AudioPluginFormat* format)
// {
//     juce::FileSearchPath searchPaths = format->getDefaultLocationsToSearch();

//     // === Add common Linux paths ===
//     if (format->getName() == "VST3")
//     {
//         searchPaths.addIfNotAlreadyThere(juce::File("/usr/lib/vst3"));
//         searchPaths.addIfNotAlreadyThere(juce::File("/usr/local/lib/vst3"));
//         searchPaths.addIfNotAlreadyThere(juce::File(QDir::homePath().toStdString() + "/.vst3"));
//     }
//     else if (format->getName() == "VST")
//     {
//         searchPaths.addIfNotAlreadyThere(juce::File("/usr/lib/vst"));
//         searchPaths.addIfNotAlreadyThere(juce::File(QDir::homePath().toStdString() + "/.vst"));
//     }

//     juce::PluginDirectoryScanner scanner(
//         m_knownPluginList,
//         *format,
//         searchPaths,
//         true,
//         juce::File()
//     );

//     juce::String name;

//     while (scanner.scanNextFile(true, name))
//     {
//         QCoreApplication::processEvents(QEventLoop::ExcludeUserInputEvents);
//     }

//     // Fixed debug output
//     qDebug() << "Scanned format:" << QString::fromStdString(format->getName().toStdString())
//              << "- plugins found:" << m_knownPluginList.getNumTypes();
// }


// ================================================================
// QQmlListProperty Implementation
// ================================================================

// static qsizetype countPlugins(QQmlListProperty<AudioPlugin>* prop) {
//     return static_cast<QList<AudioPlugin*>*>(prop->data)->size();
// }

// static AudioPlugin* atPlugin(QQmlListProperty<AudioPlugin>* prop, qsizetype index) {
//     return static_cast<QList<AudioPlugin*>*>(prop->data)->at(index);
// }

// QQmlListProperty<AudioPlugin> AudioPluginManager::plugins()
// {
//     return QQmlListProperty<AudioPlugin>(this, &m_plugins, &countPlugins, &atPlugin);
// }
