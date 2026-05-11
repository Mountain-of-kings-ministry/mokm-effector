#ifndef APPSETTINGS_H
#define APPSETTINGS_H

#include <QObject>
#include <QString>
#include <QSettings>

class AppSettings : public QObject
{
    Q_OBJECT
    // General
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(int autoSaveInterval READ autoSaveInterval WRITE setAutoSaveInterval NOTIFY autoSaveIntervalChanged)
    Q_PROPERTY(int undoLimit READ undoLimit WRITE setUndoLimit NOTIFY undoLimitChanged)
    // Project defaults
    Q_PROPERTY(int defaultWidth READ defaultWidth WRITE setDefaultWidth NOTIFY defaultProjectChanged)
    Q_PROPERTY(int defaultHeight READ defaultHeight WRITE setDefaultHeight NOTIFY defaultProjectChanged)
    Q_PROPERTY(qreal defaultFps READ defaultFps WRITE setDefaultFps NOTIFY defaultProjectChanged)
    Q_PROPERTY(int defaultDuration READ defaultDuration WRITE setDefaultDuration NOTIFY defaultProjectChanged)
    Q_PROPERTY(QString defaultColorSpace READ defaultColorSpace WRITE setDefaultColorSpace NOTIFY defaultProjectChanged)
    // Editing
    Q_PROPERTY(int snapThreshold READ snapThreshold WRITE setSnapThreshold NOTIFY editingChanged)
    Q_PROPERTY(qreal timelineScrollSpeed READ timelineScrollSpeed WRITE setTimelineScrollSpeed NOTIFY editingChanged)
    Q_PROPERTY(int defaultKeyframeEasing READ defaultKeyframeEasing WRITE setDefaultKeyframeEasing NOTIFY editingChanged)
    // Audio
    Q_PROPERTY(int audioSampleRate READ audioSampleRate WRITE setAudioSampleRate NOTIFY audioChanged)
    Q_PROPERTY(qreal defaultVolume READ defaultVolume WRITE setDefaultVolume NOTIFY audioChanged)
    Q_PROPERTY(QString audioDevice READ audioDevice WRITE setAudioDevice NOTIFY audioChanged)
    // Rendering
    Q_PROPERTY(bool gpuAcceleration READ gpuAcceleration WRITE setGpuAcceleration NOTIFY renderingChanged)
    Q_PROPERTY(QString proxyResolution READ proxyResolution WRITE setProxyResolution NOTIFY renderingChanged)
    Q_PROPERTY(QString codecPreset READ codecPreset WRITE setCodecPreset NOTIFY renderingChanged)
    // System
    Q_PROPERTY(QString cacheLocation READ cacheLocation WRITE setCacheLocation NOTIFY systemChanged)
    Q_PROPERTY(QString tempLocation READ tempLocation WRITE setTempLocation NOTIFY systemChanged)
    Q_PROPERTY(QString logLevel READ logLevel WRITE setLogLevel NOTIFY systemChanged)
public:
    explicit AppSettings(QObject *parent = nullptr);

    // General
    QString language() const;
    void setLanguage(const QString &v);
    QString theme() const;
    void setTheme(const QString &v);
    int autoSaveInterval() const;
    void setAutoSaveInterval(int v);
    int undoLimit() const;
    void setUndoLimit(int v);

    // Project defaults
    int defaultWidth() const;
    void setDefaultWidth(int v);
    int defaultHeight() const;
    void setDefaultHeight(int v);
    qreal defaultFps() const;
    void setDefaultFps(qreal v);
    int defaultDuration() const;
    void setDefaultDuration(int v);
    QString defaultColorSpace() const;
    void setDefaultColorSpace(const QString &v);

    // Editing
    int snapThreshold() const;
    void setSnapThreshold(int v);
    qreal timelineScrollSpeed() const;
    void setTimelineScrollSpeed(qreal v);
    int defaultKeyframeEasing() const;
    void setDefaultKeyframeEasing(int v);

    // Audio
    int audioSampleRate() const;
    void setAudioSampleRate(int v);
    qreal defaultVolume() const;
    void setDefaultVolume(qreal v);
    QString audioDevice() const;
    void setAudioDevice(const QString &v);

    // Rendering
    bool gpuAcceleration() const;
    void setGpuAcceleration(bool v);
    QString proxyResolution() const;
    void setProxyResolution(const QString &v);
    QString codecPreset() const;
    void setCodecPreset(const QString &v);

    // System
    QString cacheLocation() const;
    void setCacheLocation(const QString &v);
    QString tempLocation() const;
    void setTempLocation(const QString &v);
    QString logLevel() const;
    void setLogLevel(const QString &v);

    Q_INVOKABLE void resetAll();
    Q_INVOKABLE void sync();

signals:
    void languageChanged();
    void themeChanged();
    void autoSaveIntervalChanged();
    void undoLimitChanged();
    void defaultProjectChanged();
    void editingChanged();
    void audioChanged();
    void renderingChanged();
    void systemChanged();

private:
    QSettings m_settings;
};

#endif
