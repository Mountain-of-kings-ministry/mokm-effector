#include "AudioPluginManager.h"
#include "VST3Instance.h"
#include "CLAPInstance.h"
#include "EffectInstance.h"
#include <QDir>
#include <QDirIterator>
#include <QSettings>
#include <QDebug>
#include <QStandardPaths>

// Standard VST3 paths for Linux
static const QStringList standardVST3Paths = {
    "/usr/lib/vst3",
    "/usr/local/lib/vst3",
    QDir::homePath() + "/.vst3"
};

AudioPluginManager::AudioPluginManager(QObject *parent)
    : QObject(parent)
{
    scanPlugins();
}

void AudioPluginManager::scanPlugins()
{
    qDeleteAll(m_plugins);
    m_plugins.clear();

    scanVST3();
    scanCLAP();

    emit pluginsChanged();
}

void AudioPluginManager::scanVST3()
{
    qDebug() << "Scanning for VST3 plugins...";
    m_vst3Modules.clear();
    
    for (const auto &basePath : standardVST3Paths) {
        QDir dir(basePath);
        if (!dir.exists()) continue;

        QDirIterator it(basePath, {"*.vst3"}, QDir::Dirs | QDir::Files, QDirIterator::Subdirectories);
        while (it.hasNext()) {
            QString path = it.next();
            
            // Try to load as a VST3 module to get metadata
            std::string pathStr = path.toStdString();
            std::string error;
            auto module = VST3::Hosting::Module::create(pathStr, error);
            if (!module) continue;

            // Cache module handle — prevents dlclose/dlopen cycle that
            // corrupts D runtime and certain plugin state machines (Graillon 3 etc.)
            m_vst3Modules[path] = module;

            auto factory = module->getFactory();
            for (auto &classInfo : factory.classInfos()) {
                if (classInfo.category() == "Audio Module Class") {
                    m_plugins.append(new AudioPlugin(
                        QString::fromStdString(classInfo.name()),
                        "VST3",
                        QString::fromStdString(classInfo.ID().toString()),
                        QString::fromStdString(classInfo.vendor()),
                        path,
                        this
                    ));
                    qDebug() << "Found VST3:" << QString::fromStdString(classInfo.name());
                }
            }
        }
    }
}

#ifdef MOKM_ENABLE_CLAP
#include <dlfcn.h>
#include <clap/clap.h>
#include <clap/factory/plugin-factory.h>
#endif

void AudioPluginManager::scanCLAP()
{
#ifdef MOKM_ENABLE_CLAP
    qDebug() << "Scanning for CLAP plugins...";
    QStringList searchPaths = {
        QDir::homePath() + "/.clap",
        "/usr/lib/clap",
        "/usr/local/lib/clap"
    };

    for (const auto &path : searchPaths) {
        QDir dir(path);
        if (!dir.exists()) continue;

        QDirIterator it(path, {"*.clap"}, QDir::Files, QDirIterator::Subdirectories);
        while (it.hasNext()) {
            QString filePath = it.next();
            void *lib = dlopen(filePath.toUtf8().constData(), RTLD_NOW | RTLD_LOCAL);
            if (!lib) continue;

            auto entry = (const clap_plugin_entry_t *)dlsym(lib, "clap_entry");
            if (!entry || !entry->init) {
                dlclose(lib);
                continue;
            }

            if (!entry->init(filePath.toUtf8().constData())) {
                dlclose(lib);
                continue;
            }

            auto factory = (const clap_plugin_factory_t *)entry->get_factory(CLAP_PLUGIN_FACTORY_ID);
            if (!factory) {
                entry->deinit();
                dlclose(lib);
                continue;
            }

            uint32_t count = factory->get_plugin_count(factory);
            for (uint32_t i = 0; i < count; ++i) {
                const clap_plugin_descriptor_t *desc = factory->get_plugin_descriptor(factory, i);
                if (desc) {
                    m_plugins.append(new AudioPlugin(
                        desc->name ? QString::fromUtf8(desc->name) : "Unknown",
                        "CLAP",
                        desc->id ? QString::fromUtf8(desc->id) : QString(),
                        desc->vendor ? QString::fromUtf8(desc->vendor) : "Unknown",
                        filePath,
                        this
                    ));
                    qDebug() << "Found CLAP:" << (desc->name ? desc->name : "Unknown");
                }
            }
            entry->deinit();
            dlclose(lib);
        }
    }
#else
    qDebug() << "CLAP support disabled (headers not found)";
#endif
}

EffectInstance* AudioPluginManager::createInstance(AudioPlugin *plugin, QObject *parent)
{
    if (!plugin) return nullptr;

    auto *effect = new EffectInstance(plugin->name(), plugin->pluginId(), plugin->format(), parent ? parent : this);

    if (plugin->format() == "CLAP") {
#ifdef MOKM_ENABLE_CLAP
        auto *inst = new CLAPInstance(plugin->pluginId(), plugin->filePath(), effect);
        if (inst->load()) {
            effect->setClapInstance(inst);
        } else {
            delete inst;
            delete effect;
            return nullptr;
        }
#else
        delete effect;
        return nullptr;
#endif
    } else if (plugin->format() == "VST3") {
        // Pass cached module handle to prevent reloading the .so
        VST3::Hosting::Module::Ptr preloaded;
        auto it = m_vst3Modules.constFind(plugin->filePath());
        if (it != m_vst3Modules.constEnd())
            preloaded = it.value();
        auto *inst = new VST3Instance(plugin->filePath(), plugin->pluginId(), preloaded, effect);
        if (inst->load()) {
            effect->setVst3Instance(inst);
        } else {
            delete inst;
            delete effect;
            return nullptr;
        }
    }

    return effect;
}

EffectInstance* AudioPluginManager::createInstanceById(const QString &pluginId, const QString &format, QObject *parent)
{
    for (auto *p : m_plugins) {
        if (p->pluginId() == pluginId && p->format() == format)
            return createInstance(p, parent);
    }
    return nullptr;
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
