#ifndef PROJECT_H
#define PROJECT_H

#include <QObject>
#include <QString>
#include <QVector>
#include <QQmlListProperty>
#include <QUrl>

class Composition;

class Project : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QUrl filePath READ filePath WRITE setFilePath NOTIFY filePathChanged)
    Q_PROPERTY(qreal frameRate READ frameRate WRITE setFrameRate NOTIFY frameRateChanged)
    Q_PROPERTY(QQmlListProperty<Composition> compositions READ compositions NOTIFY compositionsChanged)
    Q_PROPERTY(Composition* activeComposition READ activeComposition WRITE setActiveComposition NOTIFY activeCompositionChanged)
public:
    explicit Project(QObject *parent = nullptr);
    ~Project() override;

    QString name() const { return m_name; }
    void setName(const QString &name);

    QUrl filePath() const { return m_filePath; }
    void setFilePath(const QUrl &path);

    qreal frameRate() const { return m_frameRate; }
    void setFrameRate(qreal fps);

    QQmlListProperty<Composition> compositions();
    int compositionCount() const { return m_compositions.size(); }
    Composition* compositionAt(int index) const;
    void addComposition(Composition *comp);
    void removeComposition(Composition *comp);

    Composition* activeComposition() const { return m_activeComposition; }
    void setActiveComposition(Composition *comp);

signals:
    void nameChanged();
    void filePathChanged();
    void frameRateChanged();
    void compositionsChanged();
    void activeCompositionChanged();

private:
    QString m_name = "Untitled";
    QUrl m_filePath;
    qreal m_frameRate = 30.0;
    QVector<Composition*> m_compositions;
    Composition *m_activeComposition = nullptr;
};

#endif
