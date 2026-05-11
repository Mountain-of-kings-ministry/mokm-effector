#include "CLAPPluginManager.h"
#include "CLAPPlugin.h"
#include "CLAPInstance.h"
#include <QDir>
#include <QFileInfo>
#include <QDirIterator>
#include <QProcessEnvironment>
#include <dlfcn.h>
#include <clap/clap.h>
#include <clap/factory/plugin-factory.h>
#include <cstring>

CLAPPluginManager::CLAPPluginManager(QObject *parent)
    : QObject(parent)
{
}

QQmlListProperty<CLAPPlugin> CLAPPluginManager::plugins()
{
    return QQmlListProperty<CLAPPlugin>(this, &m_plugins);
}

void CLAPPluginManager::rescan()
{
    qDeleteAll(m_plugins);
    m_plugins.clear();
    m_scanDone = false;

    QStringList searchPaths;
    auto env = QProcessEnvironment::systemEnvironment();
    if (env.contains("CLAP_PATH"))
        searchPaths << env.value("CLAP_PATH").split(':', Qt::SkipEmptyParts);

    searchPaths << QDir::homePath() + "/.clap" << "/usr/lib/clap" << "/usr/local/lib/clap";

    for (const auto &path : searchPaths)
        scanPath(path);

    m_scanDone = true;
    emit pluginsChanged();
}

void CLAPPluginManager::scanPath(const QString &path)
{
    QDir dir(path);
    if (!dir.exists()) return;

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
                QStringList features;
                if (desc->features) {
                    const char *const *feat = desc->features;
                    while (*feat) {
                        features.append(QString::fromUtf8(*feat));
                        ++feat;
                    }
                }
                m_plugins.append(new CLAPPlugin(
                    desc->id ? QString::fromUtf8(desc->id) : QString(),
                    desc->name ? QString::fromUtf8(desc->name) : QString(),
                    desc->vendor ? QString::fromUtf8(desc->vendor) : QString(),
                    desc->version ? QString::fromUtf8(desc->version) : QString(),
                    desc->description ? QString::fromUtf8(desc->description) : QString(),
                    features,
                    filePath,
                    this
                ));
            }
        }

        entry->deinit();
        dlclose(lib);
    }
}

CLAPPlugin* CLAPPluginManager::pluginById(const QString &pluginId) const
{
    for (auto *p : m_plugins) {
        if (p->pluginId() == pluginId)
            return p;
    }
    return nullptr;
}

CLAPInstance* CLAPPluginManager::createInstance(const QString &pluginId, QObject *parent)
{
    auto *plugin = pluginById(pluginId);
    if (!plugin) return nullptr;
    auto *inst = new CLAPInstance(plugin->pluginId(), plugin->filePath(), parent ? parent : this);
    inst->load();
    return inst;
}
