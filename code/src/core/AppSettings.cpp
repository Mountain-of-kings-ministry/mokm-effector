#include "AppSettings.h"

AppSettings::AppSettings(QObject *parent)
    : QObject(parent)
    , m_settings("MOKM", "MOKM Effector")
{
}

// ── General ──

QString AppSettings::language() const
{
    return m_settings.value("general/language", "en").toString();
}
void AppSettings::setLanguage(const QString &v)
{
    if (language() != v) { m_settings.setValue("general/language", v); emit languageChanged(); }
}

QString AppSettings::theme() const
{
    return m_settings.value("general/theme", "Dark").toString();
}
void AppSettings::setTheme(const QString &v)
{
    if (theme() != v) { m_settings.setValue("general/theme", v); emit themeChanged(); }
}

int AppSettings::autoSaveInterval() const
{
    return m_settings.value("general/autoSaveInterval", 5).toInt();
}
void AppSettings::setAutoSaveInterval(int v)
{
    v = qBound(1, v, 60);
    if (autoSaveInterval() != v) { m_settings.setValue("general/autoSaveInterval", v); emit autoSaveIntervalChanged(); }
}

int AppSettings::undoLimit() const
{
    return m_settings.value("general/undoLimit", 20).toInt();
}
void AppSettings::setUndoLimit(int v)
{
    v = qBound(5, v, 200);
    if (undoLimit() != v) { m_settings.setValue("general/undoLimit", v); emit undoLimitChanged(); }
}

// ── Project defaults ──

int AppSettings::defaultWidth() const
{
    return m_settings.value("project/defaultWidth", 1920).toInt();
}
void AppSettings::setDefaultWidth(int v)
{
    if (defaultWidth() != v) { m_settings.setValue("project/defaultWidth", v); emit defaultProjectChanged(); }
}

int AppSettings::defaultHeight() const
{
    return m_settings.value("project/defaultHeight", 1080).toInt();
}
void AppSettings::setDefaultHeight(int v)
{
    if (defaultHeight() != v) { m_settings.setValue("project/defaultHeight", v); emit defaultProjectChanged(); }
}

qreal AppSettings::defaultFps() const
{
    return m_settings.value("project/defaultFps", 30.0).toDouble();
}
void AppSettings::setDefaultFps(qreal v)
{
    if (!qFuzzyCompare(defaultFps(), v)) { m_settings.setValue("project/defaultFps", v); emit defaultProjectChanged(); }
}

int AppSettings::defaultDuration() const
{
    return m_settings.value("project/defaultDuration", 150).toInt();
}
void AppSettings::setDefaultDuration(int v)
{
    if (defaultDuration() != v) { m_settings.setValue("project/defaultDuration", v); emit defaultProjectChanged(); }
}

QString AppSettings::defaultColorSpace() const
{
    return m_settings.value("project/defaultColorSpace", "sRGB").toString();
}
void AppSettings::setDefaultColorSpace(const QString &v)
{
    if (defaultColorSpace() != v) { m_settings.setValue("project/defaultColorSpace", v); emit defaultProjectChanged(); }
}

// ── Editing ──

int AppSettings::snapThreshold() const
{
    return m_settings.value("editing/snapThreshold", 8).toInt();
}
void AppSettings::setSnapThreshold(int v)
{
    v = qBound(1, v, 20);
    if (snapThreshold() != v) { m_settings.setValue("editing/snapThreshold", v); emit editingChanged(); }
}

qreal AppSettings::timelineScrollSpeed() const
{
    return m_settings.value("editing/timelineScrollSpeed", 1.0).toDouble();
}
void AppSettings::setTimelineScrollSpeed(qreal v)
{
    v = qBound(0.1, v, 5.0);
    if (!qFuzzyCompare(timelineScrollSpeed(), v)) { m_settings.setValue("editing/timelineScrollSpeed", v); emit editingChanged(); }
}

int AppSettings::defaultKeyframeEasing() const
{
    return m_settings.value("editing/defaultKeyframeEasing", 0).toInt();
}
void AppSettings::setDefaultKeyframeEasing(int v)
{
    v = qBound(0, v, 3);
    if (defaultKeyframeEasing() != v) { m_settings.setValue("editing/defaultKeyframeEasing", v); emit editingChanged(); }
}

// ── Audio ──

int AppSettings::audioSampleRate() const
{
    return m_settings.value("audio/sampleRate", 48000).toInt();
}
void AppSettings::setAudioSampleRate(int v)
{
    static const int validRates[] = {44100, 48000, 96000};
    bool ok = false;
    for (int r : validRates) { if (v == r) { ok = true; break; } }
    if (!ok) v = 48000;
    if (audioSampleRate() != v) { m_settings.setValue("audio/sampleRate", v); emit audioChanged(); }
}

qreal AppSettings::defaultVolume() const
{
    return m_settings.value("audio/defaultVolume", 1.0).toDouble();
}
void AppSettings::setDefaultVolume(qreal v)
{
    v = qBound(0.0, v, 1.0);
    if (!qFuzzyCompare(defaultVolume(), v)) { m_settings.setValue("audio/defaultVolume", v); emit audioChanged(); }
}

QString AppSettings::audioDevice() const
{
    return m_settings.value("audio/device", "Default").toString();
}
void AppSettings::setAudioDevice(const QString &v)
{
    if (audioDevice() != v) { m_settings.setValue("audio/device", v); emit audioChanged(); }
}

// ── Rendering ──

bool AppSettings::gpuAcceleration() const
{
    return m_settings.value("rendering/gpuAcceleration", true).toBool();
}
void AppSettings::setGpuAcceleration(bool v)
{
    if (gpuAcceleration() != v) { m_settings.setValue("rendering/gpuAcceleration", v); emit renderingChanged(); }
}

QString AppSettings::proxyResolution() const
{
    return m_settings.value("rendering/proxyResolution", "Full").toString();
}
void AppSettings::setProxyResolution(const QString &v)
{
    if (proxyResolution() != v) { m_settings.setValue("rendering/proxyResolution", v); emit renderingChanged(); }
}

QString AppSettings::codecPreset() const
{
    return m_settings.value("rendering/codecPreset", "ProRes").toString();
}
void AppSettings::setCodecPreset(const QString &v)
{
    if (codecPreset() != v) { m_settings.setValue("rendering/codecPreset", v); emit renderingChanged(); }
}

// ── System ──

QString AppSettings::cacheLocation() const
{
    return m_settings.value("system/cacheLocation", "$TMPDIR/mokm_cache").toString();
}
void AppSettings::setCacheLocation(const QString &v)
{
    if (cacheLocation() != v) { m_settings.setValue("system/cacheLocation", v); emit systemChanged(); }
}

QString AppSettings::tempLocation() const
{
    return m_settings.value("system/tempLocation", "$TMPDIR/mokm_temp").toString();
}
void AppSettings::setTempLocation(const QString &v)
{
    if (tempLocation() != v) { m_settings.setValue("system/tempLocation", v); emit systemChanged(); }
}

QString AppSettings::logLevel() const
{
    return m_settings.value("system/logLevel", "Info").toString();
}
void AppSettings::setLogLevel(const QString &v)
{
    if (logLevel() != v) { m_settings.setValue("system/logLevel", v); emit systemChanged(); }
}

void AppSettings::resetAll()
{
    m_settings.clear();
    emit languageChanged();
    emit themeChanged();
    emit autoSaveIntervalChanged();
    emit undoLimitChanged();
    emit defaultProjectChanged();
    emit editingChanged();
    emit audioChanged();
    emit renderingChanged();
    emit systemChanged();
}

void AppSettings::sync()
{
    m_settings.sync();
}
