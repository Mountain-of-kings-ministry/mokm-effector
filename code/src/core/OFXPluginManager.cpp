#include "OFXPluginManager.h"
#include "OFXPlugin.h"
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QProcessEnvironment>
#include <dlfcn.h>

// Minimal OFX types for scanning — always define these locally.
// When MOKM_ENABLE_INTEROP is active, ofxCore.h provides the real OfxPlugin,
// but the local definition may conflict. We use a local namespace to avoid that.
namespace {

typedef int OfxStatus;

struct OfxPluginInfo {
    const char *pluginApi;
    int apiVersion;
    const char *pluginIdentifier;
    int pluginVersionMajor;
    int pluginVersionMinor;
    OfxStatus (*setHost)(const void *host);
    OfxStatus (*mainEntry)(const char *action, const void *handle, const void *inArgs, void *outArgs);
};

typedef OfxPluginInfo* (*OfxGetPluginFunc)(int index);
typedef int (*OfxGetNumberOfPluginsFunc)();

} // anonymous namespace

OFXPluginManager::OFXPluginManager(QObject *parent)
    : QObject(parent)
{
}

QQmlListProperty<OFXPlugin> OFXPluginManager::plugins()
{
    return QQmlListProperty<OFXPlugin>(this, &m_plugins);
}

void OFXPluginManager::rescan()
{
    qDeleteAll(m_plugins);
    m_plugins.clear();
    m_scanDone = false;

    QStringList searchPaths;
    auto env = QProcessEnvironment::systemEnvironment();
    if (env.contains("OFX_PLUGIN_PATH"))
        searchPaths << env.value("OFX_PLUGIN_PATH").split(':', Qt::SkipEmptyParts);

    searchPaths << QDir::homePath() + "/.openfx"
                << "/usr/OFX/Plugins"
                << "/usr/local/OFX/Plugins"
                << "/Library/OFX/Plugins";

    for (const auto &path : searchPaths)
        scanPath(path);

    m_scanDone = true;
    emit pluginsChanged();
}

void OFXPluginManager::scanPath(const QString &path)
{
    QDir dir(path);
    if (!dir.exists()) return;

    QStringList filters;
    filters << "*.ofx.bundle" << "*.ofx";
    QDirIterator it(path, filters, QDir::Dirs | QDir::Files, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        QString entryPath = it.next();
        QFileInfo fi(entryPath);

        QString binaryPath;
        if (fi.isDir()) {
            QStringList patterns;
            patterns << entryPath + "/Contents/MacOS/*"
                     << entryPath + "/*.so"
                     << entryPath + "/*.ofx";
            Q_UNUSED(patterns)
            QDirIterator bit(entryPath, {"*.so", "*.ofx", "*"}, QDir::Files);
            while (bit.hasNext()) {
                binaryPath = bit.next();
                break;
            }
        } else {
            binaryPath = entryPath;
        }

        if (binaryPath.isEmpty()) continue;

        void *lib = dlopen(binaryPath.toUtf8().constData(), RTLD_NOW | RTLD_LOCAL);
        if (!lib) continue;

        auto getPluginCount = (OfxGetNumberOfPluginsFunc)dlsym(lib, "OfxGetNumberOfPlugins");
        auto getPlugin = (OfxGetPluginFunc)dlsym(lib, "OfxGetPlugin");

        if (!getPluginCount || !getPlugin) {
            dlclose(lib);
            continue;
        }

        int nPlugins = getPluginCount();
        for (int i = 0; i < nPlugins; ++i) {
            OfxPluginInfo *plugin = getPlugin(i);
            if (!plugin || !plugin->pluginIdentifier) continue;

            m_plugins.append(new OFXPlugin(
                QString::fromUtf8(plugin->pluginIdentifier),
                QString::fromUtf8(plugin->pluginIdentifier),
                QString(),
                plugin->pluginVersionMajor,
                plugin->pluginVersionMinor,
                binaryPath,
                {"kOfxImageEffectContextFilter"},
                this
            ));
        }

        dlclose(lib);
    }
}

OFXPlugin* OFXPluginManager::pluginByIdentifier(const QString &identifier) const
{
    for (auto *p : m_plugins) {
        if (p->identifier() == identifier)
            return p;
    }
    return nullptr;
}

void OFXPluginManager::applyPluginToLayer(OFXPlugin *plugin, QObject *layer)
{
    if (!plugin || !layer) return;
    layer->setProperty("_ofxPluginId", plugin->identifier());
    layer->setProperty("_ofxPluginEnabled", true);
}
