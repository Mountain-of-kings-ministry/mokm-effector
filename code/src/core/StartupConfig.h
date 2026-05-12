#ifndef STARTUPCONFIG_H
#define STARTUPCONFIG_H

#include <QObject>
#include <QUrl>
#include <QStringList>
#include <QSettings>

class StartupConfig : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString mode READ mode WRITE setMode NOTIFY changed)
    Q_PROPERTY(QString projectName READ projectName WRITE setProjectName NOTIFY changed)
    Q_PROPERTY(QUrl filePath READ filePath WRITE setFilePath NOTIFY changed)
    Q_PROPERTY(int width READ width WRITE setWidth NOTIFY changed)
    Q_PROPERTY(int height READ height WRITE setHeight NOTIFY changed)
    Q_PROPERTY(qreal fps READ fps WRITE setFps NOTIFY changed)
    Q_PROPERTY(int duration READ duration WRITE setDuration NOTIFY changed)
    Q_PROPERTY(bool gpuRendering READ gpuRendering WRITE setGpuRendering NOTIFY changed)
    Q_PROPERTY(QString colorSpace READ colorSpace WRITE setColorSpace NOTIFY changed)
    Q_PROPERTY(QString status READ status WRITE setStatus NOTIFY statusChanged)
    Q_PROPERTY(QStringList recentProjects READ recentProjects NOTIFY recentProjectsChanged)
public:
    explicit StartupConfig(QObject *parent = nullptr);

    QString mode() const { return m_mode; }
    void setMode(const QString &v);

    QString status() const { return m_status; }
    void setStatus(const QString &v);

    QString projectName() const { return m_projectName; }
    void setProjectName(const QString &v);

    QUrl filePath() const { return m_filePath; }
    void setFilePath(const QUrl &v);

    int width() const { return m_width; }
    void setWidth(int v);
    int height() const { return m_height; }
    void setHeight(int v);

    qreal fps() const { return m_fps; }
    void setFps(qreal v);

    int duration() const { return m_duration; }
    void setDuration(int v);

    bool gpuRendering() const { return m_gpuRendering; }
    void setGpuRendering(bool v);

    QString colorSpace() const { return m_colorSpace; }
    void setColorSpace(const QString &v);

    QStringList recentProjects() const { return m_recentProjects; }
    void addRecentProject(const QString &path);
    void removeRecentProject(const QString &path);

signals:
    void changed();
    void statusChanged();
    void recentProjectsChanged();

private:
    void loadRecent();
    void saveRecent();

    QString m_mode = "new";
    QString m_status = "Initializing...";
    QString m_projectName = "Untitled";
    QUrl m_filePath;
    int m_width = 1920;
    int m_height = 1080;
    qreal m_fps = 30.0;
    int m_duration = 150;
    bool m_gpuRendering = true;
    QString m_colorSpace = "sRGB";
    QStringList m_recentProjects;
    static constexpr int kMaxRecent = 8;
};

#endif
