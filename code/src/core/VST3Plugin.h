#ifndef VST3PLUGIN_H
#define VST3PLUGIN_H

#include <QObject>
#include <QString>

class VST3Plugin : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString vendor READ vendor CONSTANT)
    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString filePath READ filePath CONSTANT)
    Q_PROPERTY(QString cid READ cid CONSTANT) // Class ID
public:
    explicit VST3Plugin(const QString &name,
                        const QString &vendor,
                        const QString &version,
                        const QString &filePath,
                        const QString &cid,
                        QObject *parent = nullptr)
        : QObject(parent), m_name(name), m_vendor(vendor),
          m_version(version), m_filePath(filePath), m_cid(cid) {}

    QString name() const { return m_name; }
    QString vendor() const { return m_vendor; }
    QString version() const { return m_version; }
    QString filePath() const { return m_filePath; }
    QString cid() const { return m_cid; }

private:
    QString m_name;
    QString m_vendor;
    QString m_version;
    QString m_filePath;
    QString m_cid;
};

#endif
