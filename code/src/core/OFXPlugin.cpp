#include "OFXPlugin.h"

OFXPlugin::OFXPlugin(const QString &identifier,
                     const QString &name,
                     const QString &group,
                     int versionMajor,
                     int versionMinor,
                     const QString &filePath,
                     const QStringList &supportedContexts,
                     QObject *parent)
    : QObject(parent)
    , m_identifier(identifier)
    , m_name(name)
    , m_group(group)
    , m_versionMajor(versionMajor)
    , m_versionMinor(versionMinor)
    , m_filePath(filePath)
    , m_supportedContexts(supportedContexts)
{
}
