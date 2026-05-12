#ifndef TRACK_H
#define TRACK_H

#include <QObject>
#include <QString>
#include <QVector>
#include <QQmlListProperty>

class Layer;
class Strip;
class TimelineLayer;

class Track : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QQmlListProperty<Strip> strips READ strips NOTIFY stripsChanged)
    Q_PROPERTY(int stripCount READ stripCount NOTIFY stripsChanged)

    // Track type
    Q_PROPERTY(int trackType READ trackType WRITE setTrackType NOTIFY trackTypeChanged)

    // Track properties
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool mute READ mute WRITE setMute NOTIFY muteChanged)
    Q_PROPERTY(bool solo READ solo WRITE setSolo NOTIFY soloChanged)
    Q_PROPERTY(qreal opacity READ opacity WRITE setOpacity NOTIFY opacityChanged)
    Q_PROPERTY(qreal pan READ pan WRITE setPan NOTIFY panChanged)
    Q_PROPERTY(bool collapsed READ collapsed WRITE setCollapsed NOTIFY collapsedChanged)
    Q_PROPERTY(bool locked READ locked WRITE setLocked NOTIFY lockedChanged)
    Q_PROPERTY(int priority READ priority WRITE setPriority NOTIFY priorityChanged)
    Q_PROPERTY(bool looping READ looping WRITE setLooping NOTIFY loopingChanged)
    Q_PROPERTY(int loopCount READ loopCount WRITE setLoopCount NOTIFY loopCountChanged)
public:
    enum TrackType { Video = 0, Audio, Image };
    Q_ENUM(TrackType)

    explicit Track(QObject *parent = nullptr);
    ~Track() override;

    QString name() const { return m_name; }
    void setName(const QString &name);

    int trackType() const { return m_trackType; }
    void setTrackType(int type);

    QQmlListProperty<Strip> strips();
    int stripCount() const { return m_strips.size(); }
    Q_INVOKABLE Strip* stripAt(int index) const;

    Q_INVOKABLE void addStrip(Strip *strip);
    Q_INVOKABLE void removeStrip(Strip *strip);
    Q_INVOKABLE Strip* removeStripAt(int index);
    Q_INVOKABLE void moveStrip(int fromIndex, int toIndex);
    Q_INVOKABLE int indexOf(Strip *strip) const;

    Q_INVOKABLE Strip* createStripFromAsset(Layer *asset, const QString &stripName = QString(), int startFrame = 0, int duration = -1);

    Q_INVOKABLE void deleteTrack();

    TimelineLayer* layer() const { return m_layer; }
    void setLayer(TimelineLayer *layer);

    const QVector<Strip*>& stripList() const { return m_strips; }

    // Property accessors
    bool enabled() const { return m_enabled; }
    void setEnabled(bool v);
    bool mute() const { return m_mute; }
    void setMute(bool v);
    bool solo() const { return m_solo; }
    void setSolo(bool v);
    qreal opacity() const { return m_opacity; }
    void setOpacity(qreal v);
    qreal pan() const { return m_pan; }
    void setPan(qreal v);
    bool collapsed() const { return m_collapsed; }
    void setCollapsed(bool v);
    bool locked() const { return m_locked; }
    void setLocked(bool v);
    int priority() const { return m_priority; }
    void setPriority(int v);
    bool looping() const { return m_looping; }
    void setLooping(bool v);
    int loopCount() const { return m_loopCount; }
    void setLoopCount(int v);

    Q_INVOKABLE QString trackTypeName(int type) const;
    static QString trackTypeNameStatic(int type);

signals:
    void nameChanged();
    void stripsChanged();
    void trackTypeChanged();
    void enabledChanged();
    void muteChanged();
    void soloChanged();
    void opacityChanged();
    void panChanged();
    void collapsedChanged();
    void lockedChanged();
    void priorityChanged();
    void loopingChanged();
    void loopCountChanged();

private:
    QString m_name;
    int m_trackType = Video;
    TimelineLayer *m_layer = nullptr;
    QVector<Strip*> m_strips;

    bool m_enabled = true;
    bool m_mute = false;
    bool m_solo = false;
    qreal m_opacity = 1.0;
    qreal m_pan = 0.0;
    bool m_collapsed = false;
    bool m_locked = false;
    int m_priority = 0;
    bool m_looping = false;
    int m_loopCount = 1;
};

#endif
