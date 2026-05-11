#ifndef OFXPLUGIN_H
#define OFXPLUGIN_H

#include <QObject>
#include <QString>
#include <QStringList>

class OFXPlugin : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString identifier READ identifier CONSTANT)
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString group READ group CONSTANT)
    Q_PROPERTY(int versionMajor READ versionMajor CONSTANT)
    Q_PROPERTY(int versionMinor READ versionMinor CONSTANT)
    Q_PROPERTY(QString filePath READ filePath CONSTANT)
    Q_PROPERTY(QStringList supportedContexts READ supportedContexts CONSTANT)
public:
    explicit OFXPlugin(const QString &identifier,
                       const QString &name,
                       const QString &group,
                       int versionMajor,
                       int versionMinor,
                       const QString &filePath,
                       const QStringList &supportedContexts,
                       QObject *parent = nullptr);

    QString identifier() const { return m_identifier; }
    QString name() const { return m_name; }
    QString group() const { return m_group; }
    int versionMajor() const { return m_versionMajor; }
    int versionMinor() const { return m_versionMinor; }
    QString filePath() const { return m_filePath; }
    QStringList supportedContexts() const { return m_supportedContexts; }

private:
    QString m_identifier;
    QString m_name;
    QString m_group;
    int m_versionMajor = 0;
    int m_versionMinor = 0;
    QString m_filePath;
    QStringList m_supportedContexts;
};

#endif
