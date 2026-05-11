#ifndef CLAPPLUGIN_H
#define CLAPPLUGIN_H

#include <QObject>
#include <QString>
#include <QStringList>

class CLAPPlugin : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString pluginId READ pluginId CONSTANT)
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString vendor READ vendor CONSTANT)
    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString description READ description CONSTANT)
    Q_PROPERTY(QStringList features READ features CONSTANT)
    Q_PROPERTY(QString filePath READ filePath CONSTANT)
public:
    explicit CLAPPlugin(const QString &pluginId,
                        const QString &name,
                        const QString &vendor,
                        const QString &version,
                        const QString &description,
                        const QStringList &features,
                        const QString &filePath,
                        QObject *parent = nullptr);

    QString pluginId() const { return m_id; }
    QString name() const { return m_name; }
    QString vendor() const { return m_vendor; }
    QString version() const { return m_version; }
    QString description() const { return m_description; }
    QStringList features() const { return m_features; }
    QString filePath() const { return m_filePath; }

private:
    QString m_id;
    QString m_name;
    QString m_vendor;
    QString m_version;
    QString m_description;
    QStringList m_features;
    QString m_filePath;
};

#endif
