#include "CLAPPlugin.h"
#include <clap/clap.h>
#include <cstring>

CLAPPlugin::CLAPPlugin(const QString &pluginId,
                        const QString &name,
                        const QString &vendor,
                        const QString &version,
                        const QString &description,
                        const QStringList &features,
                        const QString &filePath,
                        QObject *parent)
    : QObject(parent)
    , m_id(pluginId)
    , m_name(name)
    , m_vendor(vendor)
    , m_version(version)
    , m_description(description)
    , m_features(features)
    , m_filePath(filePath)
{
}
