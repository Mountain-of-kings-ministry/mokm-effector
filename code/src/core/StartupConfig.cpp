#include "StartupConfig.h"

StartupConfig::StartupConfig(QObject *parent)
    : QObject(parent)
{
    loadRecent();
}

void StartupConfig::setMode(const QString &v)
{
    if (m_mode != v) { m_mode = v; emit changed(); }
}

void StartupConfig::setStatus(const QString &v)
{
    if (m_status != v) { m_status = v; emit statusChanged(); }
}

void StartupConfig::setProjectName(const QString &v)
{
    if (m_projectName != v) { m_projectName = v; emit changed(); }
}

void StartupConfig::setFilePath(const QUrl &v)
{
    if (m_filePath != v) { m_filePath = v; emit changed(); }
}

void StartupConfig::setWidth(int v)
{
    if (m_width != v) { m_width = v; emit changed(); }
}

void StartupConfig::setHeight(int v)
{
    if (m_height != v) { m_height = v; emit changed(); }
}

void StartupConfig::setFps(qreal v)
{
    if (!qFuzzyCompare(m_fps, v)) { m_fps = v; emit changed(); }
}

void StartupConfig::setDuration(int v)
{
    if (m_duration != v) { m_duration = v; emit changed(); }
}

void StartupConfig::setGpuRendering(bool v)
{
    if (m_gpuRendering != v) { m_gpuRendering = v; emit changed(); }
}

void StartupConfig::setColorSpace(const QString &v)
{
    if (m_colorSpace != v) { m_colorSpace = v; emit changed(); }
}

void StartupConfig::addRecentProject(const QString &path)
{
    m_recentProjects.removeAll(path);
    m_recentProjects.prepend(path);
    while (m_recentProjects.size() > kMaxRecent)
        m_recentProjects.removeLast();
    saveRecent();
    emit recentProjectsChanged();
}

void StartupConfig::removeRecentProject(const QString &path)
{
    m_recentProjects.removeAll(path);
    saveRecent();
    emit recentProjectsChanged();
}

void StartupConfig::loadRecent()
{
    QSettings settings;
    m_recentProjects = settings.value("startup/recentProjects").toStringList();
}

void StartupConfig::saveRecent()
{
    QSettings settings;
    settings.setValue("startup/recentProjects", m_recentProjects);
}
