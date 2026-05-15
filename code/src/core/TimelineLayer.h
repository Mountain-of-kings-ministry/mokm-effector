#ifndef TIMELINELAYER_H
#define TIMELINELAYER_H

#include <QObject>
#include <QString>
#include <QVector>
#include <QQmlListProperty>

class Track;
class Composition;

class TimelineLayer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QQmlListProperty<Track> tracks READ tracks NOTIFY tracksChanged)
    Q_PROPERTY(int trackCount READ trackCount NOTIFY tracksChanged)

    // Layer compositing properties
    Q_PROPERTY(qreal opacity READ opacity WRITE setOpacity NOTIFY opacityChanged)
    Q_PROPERTY(bool visible READ visible WRITE setVisible NOTIFY visibleChanged)
    Q_PROPERTY(bool locked READ locked WRITE setLocked NOTIFY lockedChanged)
    Q_PROPERTY(bool mute READ mute WRITE setMute NOTIFY muteChanged)
    Q_PROPERTY(bool solo READ solo WRITE setSolo NOTIFY soloChanged)
    Q_PROPERTY(qreal offsetX READ offsetX WRITE setOffsetX NOTIFY offsetXChanged)
    Q_PROPERTY(qreal offsetY READ offsetY WRITE setOffsetY NOTIFY offsetYChanged)
    Q_PROPERTY(qreal rotation READ rotation WRITE setRotation NOTIFY rotationChanged)
    Q_PROPERTY(qreal scaleX READ scaleX WRITE setScaleX NOTIFY scaleXChanged)
    Q_PROPERTY(qreal scaleY READ scaleY WRITE setScaleY NOTIFY scaleYChanged)
    Q_PROPERTY(qreal anchorX READ anchorX WRITE setAnchorX NOTIFY anchorXChanged)
    Q_PROPERTY(qreal anchorY READ anchorY WRITE setAnchorY NOTIFY anchorYChanged)
public:
    explicit TimelineLayer(QObject *parent = nullptr);
    ~TimelineLayer() override;

    QString name() const { return m_name; }
    void setName(const QString &name);

    QQmlListProperty<Track> tracks();
    int trackCount() const { return m_tracks.size(); }

    Q_INVOKABLE Track* trackAt(int index) const;
    Q_INVOKABLE Track* addTrack(const QString &name = QString());
    Q_INVOKABLE void addTrack(Track *track);
    Q_INVOKABLE Track* insertTrack(int index, int trackType);
    Q_INVOKABLE void removeTrack(Track *track);
    Q_INVOKABLE int trackIndex(Track *track) const;
    Q_INVOKABLE void moveTrack(int fromIndex, int toIndex);

    Q_INVOKABLE void deleteLayer();

    Q_PROPERTY(Composition* composition READ composition NOTIFY compositionChanged)
    Composition* composition() const { return m_composition; }
    void setComposition(Composition *comp);

    // Layer properties
    qreal opacity() const { return m_opacity; }
    void setOpacity(qreal v);
    bool visible() const { return m_visible; }
    void setVisible(bool v);
    bool locked() const { return m_locked; }
    void setLocked(bool v);
    bool enabled() const { return m_enabled; }
    void setEnabled(bool v);
    bool mute() const { return m_mute; }
    void setMute(bool v);
    bool solo() const { return m_solo; }
    void setSolo(bool v);
    qreal offsetX() const { return m_offsetX; }
    void setOffsetX(qreal v);
    qreal offsetY() const { return m_offsetY; }
    void setOffsetY(qreal v);
    qreal rotation() const { return m_rotation; }
    void setRotation(qreal v);
    qreal scaleX() const { return m_scaleX; }
    void setScaleX(qreal v);
    qreal scaleY() const { return m_scaleY; }
    void setScaleY(qreal v);
    qreal anchorX() const { return m_anchorX; }
    void setAnchorX(qreal v);
    qreal anchorY() const { return m_anchorY; }
    void setAnchorY(qreal v);

signals:
    void nameChanged();
    void tracksChanged();
    void opacityChanged();
    void visibleChanged();
    void lockedChanged();
    void enabledChanged();
    void muteChanged();
    void soloChanged();
    void offsetXChanged();
    void offsetYChanged();
    void rotationChanged();
    void scaleXChanged();
    void scaleYChanged();
    void anchorXChanged();
    void anchorYChanged();
    void compositionChanged();

private:
    QString m_name = "Layer 1";
    QVector<Track*> m_tracks;
    Composition *m_composition = nullptr;

    qreal m_opacity = 1.0;
    bool m_visible = true;
    bool m_locked = false;
    bool m_enabled = true;
    bool m_mute = false;
    bool m_solo = false;
    qreal m_offsetX = 0.0;
    qreal m_offsetY = 0.0;
    qreal m_rotation = 0.0;
    qreal m_scaleX = 1.0;
    qreal m_scaleY = 1.0;
    qreal m_anchorX = 0.0;
    qreal m_anchorY = 0.0;
};

#endif
