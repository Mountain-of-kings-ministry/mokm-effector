#include "AudioEngine.h"
#include "AudioLayer.h"
#include "Track.h"
#include "Strip.h"
#include "Composition.h"
#include "TimelineLayer.h"
#include "EffectChain.h"
#include "EffectInstance.h"
#include "CLAPInstance.h"
#include "VST3Instance.h"

#include <QAudioSink>
#include <QAudioDevice>
#include <QMediaDevices>
#include <QDebug>

// ── AudioEngineDevice implementation ────────────────────────
AudioEngineDevice::AudioEngineDevice(AudioEngine *engine, QObject *parent)
    : QIODevice(parent), m_engine(engine)
{
    open(QIODevice::ReadOnly);
}

qint64 AudioEngineDevice::readData(char *data, qint64 maxlen)
{
    if (!m_engine->m_playing || !m_engine->m_timeline) {
        std::memset(data, 0, maxlen);
        return maxlen;
    }

    int sampleRate = 48000;
    int channels = 2;
    int bytesPerSample = sizeof(float);
    int framesToRead = maxlen / (channels * bytesPerSample);
    
    float *fData = reinterpret_cast<float*>(data);
    std::memset(fData, 0, maxlen);

    // Temporary buffers for processing
    QVector<float> leftBuf(framesToRead, 0.0f);
    QVector<float> rightBuf(framesToRead, 0.0f);
    float* buffers[2] = { leftBuf.data(), rightBuf.data() };

    int currentFrame = m_engine->m_timeline->currentFrame();
    qreal fps = m_engine->m_timeline->composition() ? m_engine->m_timeline->composition()->frameRate() : 30.0;
    if (fps <= 0) fps = 30.0;

    // Fetch audio from layers
    auto *comp = m_engine->m_timeline->composition();
    if (comp) {
        for (int li = 0; li < comp->layerCount(); li++) {
            auto *tl = comp->layerAt(li);
            for (int ti = 0; ti < tl->trackCount(); ti++) {
                auto *tr = tl->trackAt(ti);
                if (!tr || tr->trackType() != Track::Audio || tr->mute()) continue;
                
                // Track volume/pan
                qreal trackVol = tr->opacity() * m_engine->m_masterVolume;

                for (int si = 0; si < tr->stripCount(); si++) {
                    auto *st = tr->stripAt(si);
                    int start = st->startFrame();
                    int end = start + st->duration();
                    
                    if (currentFrame >= start && currentFrame < end) {
                        AudioLayer *al = qobject_cast<AudioLayer*>(st->element());
                        if (!al) continue;

                        int clipFrame = currentFrame - start;
                        qint64 samplePos = qint64(clipFrame / fps * al->sampleRate());
                        const auto& fullData = al->fullAudioData();
                        
                        for (int i = 0; i < framesToRead; i++) {
                            qint64 pos = (samplePos + i) * al->channels();
                            if (pos + 1 < fullData.size()) {
                                leftBuf[i] += fullData[pos] * trackVol * al->volume();
                                if (al->channels() > 1)
                                    rightBuf[i] += fullData[pos + 1] * trackVol * al->volume();
                                else
                                    rightBuf[i] += fullData[pos] * trackVol * al->volume();
                            }
                        }
                    }
                }

                // Process effect chain for this track
                if (tr->effectChain() && tr->effectChain()->count() > 0) {
                    for (int ei = 0; ei < tr->effectChain()->count(); ei++) {
                        auto *effect = tr->effectChain()->effectAt(ei);
                        if (effect && !effect->bypassed()) {
                            if (effect->clapInstance()) {
                                effect->clapInstance()->process(buffers, buffers, 2, framesToRead);
                            } else if (effect->vst3Instance()) {
                                effect->vst3Instance()->process(buffers, buffers, 2, framesToRead);
                            }
                        }
                    }
                }
            }
        }
    }

    // Interleave and write to output
    for (int i = 0; i < framesToRead; i++) {
        fData[i * 2] = leftBuf[i];
        fData[i * 2 + 1] = rightBuf[i];
    }

    // Advance timeline based on read samples
    double secondsRead = (double)framesToRead / sampleRate;
    int framesRead = qRound(secondsRead * fps);
    if (framesRead > 0) {
        // We use a non-blocking way to update timeline from audio thread
        QMetaObject::invokeMethod(m_engine->m_timeline, "setCurrentFrame", 
                                  Qt::QueuedConnection, 
                                  Q_ARG(int, currentFrame + framesRead));
    }

    return maxlen;
}

// ── AudioEngine implementation ──────────────────────────────
AudioEngine::AudioEngine(QObject *parent)
    : QObject(parent)
{
    QAudioFormat format;
    format.setSampleRate(48000);
    format.setChannelCount(2);
    format.setSampleFormat(QAudioFormat::Float);

    auto device = QMediaDevices::defaultAudioOutput();
    m_audioSink = new QAudioSink(device, format, this);
    m_audioSink->setBufferSize(4096 * 4); // Sufficient for low-latency processing

    m_audioDevice = new AudioEngineDevice(this, this);
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
        disconnect(m_timeline, nullptr, this, nullptr);
    }
    m_timeline = model;
    if (m_timeline) {
        connect(m_timeline, &TimelineModel::playingChanged, this, [this]() {
            if (m_timeline && m_timeline->playing())
                play();
            else
                pause();
        });
    }
    emit timelineModelChanged();
}

void AudioEngine::setMasterVolume(qreal vol)
{
    m_masterVolume = qBound(0.0, vol, 1.0);
    emit masterVolumeChanged();
}

void AudioEngine::setMasterPan(qreal pan)
{
    m_masterPan = qBound(-1.0, pan, 1.0);
    emit masterPanChanged();
}

void AudioEngine::play()
{
    if (m_playing) return;
    m_playing = true;
    m_audioSink->start(m_audioDevice);
    emit playingChanged();
}

void AudioEngine::pause()
{
    if (!m_playing) return;
    m_playing = false;
    m_audioSink->stop();
    emit playingChanged();
}

void AudioEngine::stop()
{
    pause();
    if (m_timeline)
        m_timeline->setCurrentFrame(0);
}

bool AudioEngine::hasAudioAtFrame(int frame) const
{
    return findAudioLayerAtFrame(frame) != nullptr;
}

void AudioEngine::onTimelinePlay() { play(); }
void AudioEngine::onTimelinePause() { pause(); }

void AudioEngine::onTimelineFrameChanged(int frame)
{
    Q_UNUSED(frame);
    // With pull-based audio, we don't need to do much here unless seeking
}

void AudioEngine::syncToTimeline()
{
    // Implementation for sync if needed
}

void AudioEngine::applyTrackVolume(int frame)
{
    Q_UNUSED(frame);
}

AudioLayer* AudioEngine::findAudioLayerAtFrame(int frame) const
{
    if (!m_timeline || !m_timeline->composition())
        return nullptr;

    auto *comp = m_timeline->composition();
    for (int li = 0; li < comp->layerCount(); li++) {
        auto *tl = comp->layerAt(li);
        for (int ti = 0; ti < tl->trackCount(); ti++) {
            auto *tr = tl->trackAt(ti);
            if (!tr || tr->trackType() != Track::Audio || tr->mute()) continue;
            for (int si = 0; si < tr->stripCount(); si++) {
                auto *st = tr->stripAt(si);
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

void AudioEngine::processAudioBlock(float **buffers, int nChannels, int nFrames, int frame)
{
    Q_UNUSED(buffers); Q_UNUSED(nChannels); Q_UNUSED(nFrames); Q_UNUSED(frame);
}
