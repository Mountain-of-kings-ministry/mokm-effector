#include "AudioEngine.h"
#include "AudioLayer.h"
#include "Track.h"
#include "Strip.h"
#include "Composition.h"
#include "TimelineLayer.h"

#include <QMediaPlayer>
#include <QAudioOutput>

AudioEngine::AudioEngine(QObject *parent)
    : QObject(parent)
{
    m_player = new QMediaPlayer(this);
    m_audioOutput = new QAudioOutput(this);
    m_player->setAudioOutput(m_audioOutput);

    QObject::connect(m_player, &QMediaPlayer::positionChanged,
                     this, &AudioEngine::onMediaPositionChanged);
    QObject::connect(m_player, &QMediaPlayer::playbackStateChanged,
                     this, &AudioEngine::onMediaStateChanged);
}

AudioEngine::~AudioEngine()
{
    stop();
}

void AudioEngine::setTimelineModel(TimelineModel *model)
{
    if (m_timeline == model)
        return;
    if (m_timeline) {
        QObject::disconnect(m_timeline, nullptr, this, nullptr);
    }
    m_timeline = model;
    if (m_timeline) {
        QObject::connect(m_timeline, &TimelineModel::playingChanged,
                         this, [this]() {
            if (m_timeline && m_timeline->playing())
                onTimelinePlay();
            else
                onTimelinePause();
        });
        QObject::connect(m_timeline, &TimelineModel::currentFrameChanged,
                         this, [this]() {
            if (m_timeline)
                onTimelineFrameChanged(m_timeline->currentFrame());
        });
    }
    emit timelineModelChanged();
}

void AudioEngine::setMasterVolume(qreal vol)
{
    vol = qBound(0.0, vol, 1.0);
    if (!qFuzzyCompare(m_masterVolume, vol)) {
        m_masterVolume = vol;
        if (m_audioOutput)
            m_audioOutput->setVolume(vol);
        emit masterVolumeChanged();
    }
}

void AudioEngine::play()
{
    m_playing = true;
    emit playingChanged();
    syncToTimeline();
}

void AudioEngine::pause()
{
    m_playing = false;
    emit playingChanged();
    m_player->pause();
}

void AudioEngine::stop()
{
    m_playing = false;
    emit playingChanged();
    m_player->stop();
}

bool AudioEngine::hasAudioAtFrame(int frame) const
{
    return findAudioLayerAtFrame(frame) != nullptr;
}

void AudioEngine::onTimelinePlay()
{
    play();
}

void AudioEngine::onTimelinePause()
{
    pause();
}

void AudioEngine::onTimelineFrameChanged(int frame)
{
    if (!m_timeline || m_seeking)
        return;

    // If timeline is playing, let the media position sync handle it
    if (m_timeline->playing())
        return;

    // User scrubbed — find audio at new position
    AudioLayer *layer = findAudioLayerAtFrame(frame);
    if (!layer) {
        m_player->stop();
        return;
    }

    if (m_player->source() != layer->source()) {
        m_player->setSource(layer->source());
    }

    // Seek to matching position
    qreal fps = 30.0;
    auto *comp = m_timeline->composition();
    if (comp && comp->frameRate() > 0)
        fps = comp->frameRate();

    int clipFrame = frame - layer->startFrame();
    qint64 posMs = qint64(clipFrame / fps * 1000.0);
    m_player->setPosition(posMs);
}

void AudioEngine::onMediaPositionChanged(qint64 position)
{
    if (!m_timeline || !m_timeline->playing())
        return;

    qreal fps = 30.0;
    auto *comp = m_timeline->composition();
    if (comp && comp->frameRate() > 0)
        fps = comp->frameRate();

    // Convert media position to frame
    int frame = qRound(position / 1000.0 * fps);

    AudioLayer *layer = findAudioLayerAtFrame(frame);
    if (!layer) {
        // No audio at this frame — stop if playing
        if (m_timeline && m_timeline->playing())
            m_timeline->pause();
        return;
    }

    // Check if we've exceeded the clip duration
    int stripEnd = layer->startFrame() + layer->duration();
    if (frame >= stripEnd) {
        m_timeline->pause();
        return;
    }

    // Sync timeline frame without recursion
    m_seeking = true;
    // Don't update timeline frame from audio — timeline drives frame
    m_seeking = false;
}

void AudioEngine::onMediaStateChanged()
{
    // Handle media end
    if (m_player->playbackState() == QMediaPlayer::StoppedState && m_playing) {
        if (m_timeline)
            m_timeline->pause();
    }
}

void AudioEngine::syncToTimeline()
{
    if (!m_timeline) return;

    int frame = m_timeline->currentFrame();
    AudioLayer *layer = findAudioLayerAtFrame(frame);
    if (!layer) return;

    qreal fps = 30.0;
    auto *comp = m_timeline->composition();
    if (comp && comp->frameRate() > 0)
        fps = comp->frameRate();

    if (m_player->source() != layer->source()) {
        m_player->setSource(layer->source());
    }

    int clipFrame = frame - layer->startFrame();
    qint64 posMs = qint64(clipFrame / fps * 1000.0);
    m_seeking = true;
    m_player->setPosition(posMs);
    m_player->play();
    m_seeking = false;
}

AudioLayer* AudioEngine::findAudioLayerAtFrame(int frame) const
{
    if (!m_timeline || !m_timeline->composition())
        return nullptr;

    auto *comp = m_timeline->composition();
    for (int li = 0; li < comp->layerCount(); li++) {
        auto *tl = comp->layerAt(li);
        if (!tl) continue;
        for (int ti = 0; ti < tl->trackCount(); ti++) {
            auto *tr = tl->trackAt(ti);
            if (!tr || tr->trackType() != Track::Audio || tr->mute())
                continue;
            for (int si = 0; si < tr->stripCount(); si++) {
                auto *st = tr->stripAt(si);
                if (!st) continue;
                int start = st->startFrame();
                int end = start + st->duration();
                if (frame >= start && frame < end) {
                    return qobject_cast<AudioLayer*>(st->element());
                }
            }
        }
    }
    return nullptr;
}
