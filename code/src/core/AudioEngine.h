#ifndef AUDIOENGINE_H
#define AUDIOENGINE_H

#include <QObject>
#include <QUrl>
#include <QVector>

#include "../timeline/TimelineModel.h"

class QMediaPlayer;
class QAudioOutput;
class Track;
class Strip;
class AudioLayer;

class AudioEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(TimelineModel* timelineModel READ timelineModel WRITE setTimelineModel NOTIFY timelineModelChanged)
    Q_PROPERTY(qreal masterVolume READ masterVolume WRITE setMasterVolume NOTIFY masterVolumeChanged)
    Q_PROPERTY(qreal masterPan READ masterPan WRITE setMasterPan NOTIFY masterPanChanged)
    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
public:
    explicit AudioEngine(QObject *parent = nullptr);
    ~AudioEngine() override;

    TimelineModel* timelineModel() const { return m_timeline; }
    void setTimelineModel(TimelineModel *model);

    qreal masterVolume() const { return m_masterVolume; }
    void setMasterVolume(qreal vol);

    qreal masterPan() const { return m_masterPan; }
    void setMasterPan(qreal pan);

    bool playing() const { return m_playing; }

    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void stop();

    Q_INVOKABLE bool hasAudioAtFrame(int frame) const;

signals:
    void timelineModelChanged();
    void masterVolumeChanged();
    void masterPanChanged();
    void playingChanged();

private slots:
    void onTimelinePlay();
    void onTimelinePause();
    void onMediaPositionChanged(qint64 position);
    void onMediaStateChanged();

private:
    void onTimelineFrameChanged(int frame);

private:
    void syncToTimeline();
    void applyTrackVolume(int frame);
    AudioLayer* findAudioLayerAtFrame(int frame) const;

    TimelineModel *m_timeline = nullptr;
    QMediaPlayer *m_player = nullptr;
    QAudioOutput *m_audioOutput = nullptr;
    qreal m_masterVolume = 1.0;
    qreal m_masterPan = 0.0;
    bool m_playing = false;
    bool m_seeking = false;
};

#endif
