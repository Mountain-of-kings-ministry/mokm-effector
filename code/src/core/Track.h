#ifndef TRACK_H
#define TRACK_H

#include <QObject>
#include <QString>
#include <QVector>
#include <QQmlListProperty>

class Layer;

class Track : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(bool locked READ locked WRITE setLocked NOTIFY lockedChanged)
    Q_PROPERTY(QQmlListProperty<Layer> clips READ clips NOTIFY clipsChanged)
    Q_PROPERTY(int clipCount READ clipCount NOTIFY clipsChanged)
public:
    explicit Track(QObject *parent = nullptr);
    ~Track() override;

    QString name() const { return m_name; }
    void setName(const QString &name);

    bool locked() const { return m_locked; }
    void setLocked(bool locked);

    QQmlListProperty<Layer> clips();
    int clipCount() const { return m_clips.size(); }
    Q_INVOKABLE Layer* clipAt(int index) const;

    Q_INVOKABLE void addClip(Layer *layer);
    Q_INVOKABLE void removeClip(Layer *layer);
    Q_INVOKABLE Layer* removeClipAt(int index);
    Q_INVOKABLE void moveClip(int fromIndex, int toIndex);
    Q_INVOKABLE int indexOf(Layer *layer) const;

    const QVector<Layer*>& clipList() const { return m_clips; }

signals:
    void nameChanged();
    void lockedChanged();
    void clipsChanged();

private:
    QString m_name;
    bool m_locked = false;
    QVector<Layer*> m_clips;
};

#endif
