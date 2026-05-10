#ifndef TIMELINEMODEL_H
#define TIMELINEMODEL_H

#include <QObject>
#include <QTimer>
#include <QMap>
#include <QVector>
#include <QPair>

#include "../core/Keyframe.h"

class Composition;
class Layer;

class TimelineModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Composition* composition READ composition WRITE setComposition NOTIFY compositionChanged)
    Q_PROPERTY(int currentFrame READ currentFrame WRITE setCurrentFrame NOTIFY currentFrameChanged)
    Q_PROPERTY(bool playing READ playing WRITE setPlaying NOTIFY playingChanged)
    Q_PROPERTY(qreal playbackSpeed READ playbackSpeed WRITE setPlaybackSpeed NOTIFY playbackSpeedChanged)
    Q_PROPERTY(int keyframesStamp READ keyframesStamp NOTIFY keyframesChanged)
    Q_PROPERTY(bool autoKeyframeEnabled READ autoKeyframeEnabled WRITE setAutoKeyframeEnabled NOTIFY autoKeyframeEnabledChanged)
public:
    explicit TimelineModel(QObject *parent = nullptr);
    ~TimelineModel() override;

    Composition* composition() const { return m_composition; }
    void setComposition(Composition *comp);

    int currentFrame() const { return m_currentFrame; }
    void setCurrentFrame(int frame);

    bool playing() const { return m_playing; }
    void setPlaying(bool playing);

    qreal playbackSpeed() const { return m_playbackSpeed; }
    void setPlaybackSpeed(qreal speed);

    int keyframesStamp() const { return m_keyframesStamp; }

    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void goToFrame(int frame);
    Q_INVOKABLE void goToStart();
    Q_INVOKABLE void goToEnd();
    Q_INVOKABLE void stepForward();
    Q_INVOKABLE void stepBackward();

    bool autoKeyframeEnabled() const { return m_autoKeyframeEnabled; }
    void setAutoKeyframeEnabled(bool enabled);

    Q_INVOKABLE void addKeyframe(QObject *obj, const QString &property, int frame, const QVariant &value);
    Q_INVOKABLE void removeKeyframe(QObject *obj, const QString &property, int frame);
    Q_INVOKABLE void setKeyframeEasing(QObject *obj, const QString &property, int frame, int easing);
    Q_INVOKABLE QVariant getValueAt(QObject *obj, const QString &property, int frame) const;
    Q_INVOKABLE bool hasKeyframe(QObject *obj, const QString &property, int frame) const;
    Q_INVOKABLE QVector<int> keyframeFrames(QObject *obj, const QString &property) const;
    Q_INVOKABLE QVariantList getKeyframeData(QObject *obj, const QString &property) const;

    void applyKeyframes();

signals:
    void compositionChanged();
    void currentFrameChanged();
    void playingChanged();
    void playbackSpeedChanged();
    void keyframesChanged();
    void autoKeyframeEnabledChanged();

private slots:
    void onTick();

private:
    using KeyframeMap = QMap<int, Keyframe*>;
    struct PropertyKeyframes {
        QMap<QString, KeyframeMap> keyframes;
    };

    qreal interpolateValue(qreal from, qreal to, qreal t, Keyframe::Easing easing) const;

    Composition *m_composition = nullptr;
    int m_currentFrame = 0;
    bool m_playing = false;
    qreal m_playbackSpeed = 1.0;
    int m_keyframesStamp = 0;
    bool m_autoKeyframeEnabled = false;
    QTimer *m_timer = nullptr;

    // keyframes grouped by QObject ptr -> property name -> frame -> keyframe
    QMap<QObject*, QMap<QString, KeyframeMap>> m_keyframes;
};

#endif
