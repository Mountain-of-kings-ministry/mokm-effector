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
    qDebug() << "AudioEngineDevice initialized.";
}

qint64 AudioEngineDevice::readData(char *data, qint64 maxlen)
{
    qDebug() << "READ_DATA_ENTERED: Playing=" << m_engine->m_playing << "MaxLen=" << maxlen;
    if (!m_engine->m_playing || !m_engine->m_timeline) {
        std::memset(data, 0, maxlen);
        return maxlen;
    }

    const int sampleRate = 48000;
    const int channels = 2;
    const int bytesPerSample = sizeof(float);
    const int framesToRead = maxlen / (channels * bytesPerSample);
    
    float *fData = reinterpret_cast<float*>(data);
    std::memset(fData, 0, maxlen);

    QVector<float> leftBuf(framesToRead, 0.0f);
    QVector<float> rightBuf(framesToRead, 0.0f);
    float* buffers[2] = { leftBuf.data(), rightBuf.data() };

    qreal fps = m_engine->m_timeline->composition() ? m_engine->m_timeline->composition()->frameRate() : 30.0;
    if (fps <= 0) fps = 30.0;

    auto *comp = m_engine->m_timeline->composition();
    int layersFound = 0;
    if (comp) {
        qDebug() << "Processing composition with" << comp->layerCount() << "layers.";
        for (int li = 0; li < comp->layerCount(); li++) {
            auto *tl = comp->layerAt(li);
            if (!tl) continue;
            for (int ti = 0; ti < tl->trackCount(); ti++) {
                auto *tr = tl->trackAt(ti);
                if (!tr || tr->trackType() != Track::Audio || tr->mute()) continue;
                
                qreal trackVol = tr->opacity() * m_engine->m_masterVolume;

                for (int si = 0; si < tr->stripCount(); si++) {
                    auto *st = tr->stripAt(si);
                    if (!st) continue;
                    
                    double startSample = (st->startFrame() / fps) * sampleRate;
                    double endSample = ((st->startFrame() + st->duration()) / fps) * sampleRate;
                    
                    if (m_engine->m_currentPositionSamples >= startSample && m_engine->m_currentPositionSamples < endSample) {
                        layersFound++;
                        AudioLayer *al = qobject_cast<AudioLayer*>(st->element());
                        if (!al) continue;

                        const QVector<float>& fullData = al->fullAudioData();
                        if (fullData.isEmpty()) {
                             qDebug() << "Layer audio data is empty! Layer pointer:" << al;
                             continue;
                        }
                        
                        double clipOffsetSamples = m_engine->m_currentPositionSamples - startSample;
                        int nChannels = al->channels();
                        
                        for (int i = 0; i < framesToRead; i++) {
                            qint64 layerSampleIdx = qint64(clipOffsetSamples + i);
                            qint64 pos = layerSampleIdx * nChannels;
                            if (pos + 1 < fullData.size()) {
                                leftBuf[i] += fullData[pos] * trackVol * al->volume();
                                rightBuf[i] += (nChannels > 1 ? fullData[pos + 1] : fullData[pos]) * trackVol * al->volume();
                            }
                        }
                    }
                }

                if (tr->effectChain() && tr->effectChain()->count() > 0) {
                    for (int ei = 0; ei < tr->effectChain()->count(); ei++) {
                        auto *effect = tr->effectChain()->effectAt(ei);
                        if (effect && !effect->bypassed()) {
                            if (effect->clapInstance())
                                effect->clapInstance()->process(buffers, buffers, 2, framesToRead);
                            else if (effect->vst3Instance())
                                effect->vst3Instance()->process(buffers, buffers, 2, framesToRead);
                        }
                    }
                }
            }
        }
    }
    
    static int logCount = 0;
    if (logCount++ % 500 == 0) {
        qDebug() << "Layers processed:" << layersFound << "Frames to read:" << framesToRead;
        float peak = 0;
        for(int i=0; i<framesToRead; i++) peak = qMax(peak, qAbs(leftBuf[i]));
        qDebug() << "Peak signal:" << peak;
    }

    for (int i = 0; i < framesToRead; i++) {
        fData[i * 2] = leftBuf[i];
        fData[i * 2 + 1] = rightBuf[i];
    }

    m_engine->m_currentPositionSamples += framesToRead;
    int newFrame = qFloor((m_engine->m_currentPositionSamples / sampleRate) * fps);
    if (newFrame != m_engine->m_timeline->currentFrame()) {
        QMetaObject::invokeMethod(m_engine->m_timeline, "setCurrentFrame", 
                                  Qt::QueuedConnection, Q_ARG(int, newFrame));
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
    qDebug() << "Using audio device:" << device.description();
    m_audioSink = new QAudioSink(device, format, this);
    m_audioSink->setBufferSize(2048); 

    m_audioDevice = new AudioEngineDevice(this, this);
    qDebug() << "AudioSink initialized with device:" << device.description();
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
    
    if (m_timeline) {
        qreal fps = m_timeline->composition() ? m_timeline->composition()->frameRate() : 30.0;
        if (fps <= 0) fps = 30.0;
        m_currentPositionSamples = (m_timeline->currentFrame() / fps) * 48000;
    }

    if (!m_audioDevice->isOpen()) {
        qDebug() << "Re-opening audio device...";
        m_audioDevice->open(QIODevice::ReadOnly);
    }

    m_playing = true;
    m_audioSink->start(m_audioDevice);
    qDebug() << "AudioSink started. Sink state:" << m_audioSink->state();
    qDebug() << "Device is open:" << m_audioDevice->isOpen();
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
}

void AudioEngine::syncToTimeline()
{
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
