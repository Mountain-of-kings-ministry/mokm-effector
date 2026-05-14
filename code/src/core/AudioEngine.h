#ifndef AUDIOENGINE_H
#define AUDIOENGINE_H

#include <QObject>
#include <QUrl>
#include <QVector>
#include <QMutex>
#include <QTimer>

#include "../timeline/TimelineModel.h"

#include <QAudioSink>
#include <QAudioFormat>
#include <QIODevice>

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

private:
    void writeAudio();
    AudioLayer* findAudioLayerAtFrame(int frame) const;
    void processAudioBlock(float **buffers, int nChannels, int nFrames, int frame);

    TimelineModel *m_timeline = nullptr;
    QAudioSink *m_audioSink = nullptr;
    QIODevice *m_audioOutputDevice = nullptr;
    QAudioFormat m_format;
    int m_bytesPerSample = 4;
    qreal m_masterVolume = 1.0;
    qreal m_masterPan = 0.0;
    double m_currentPositionSamples = 0;
    QTimer *m_audioTimer = nullptr;
    QMutex m_audioMutex;
    bool m_playing = false;
};

#endif
