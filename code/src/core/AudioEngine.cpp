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
#include <cmath>

// ── AudioEngine implementation ──────────────────────────────
AudioEngine::AudioEngine(QObject *parent)
    : QObject(parent)
{
    QAudioFormat format;
    format.setSampleRate(48000);
    format.setChannelCount(2);
    format.setSampleFormat(QAudioFormat::Float);

    auto deviceInfo = QMediaDevices::defaultAudioOutput();
    qDebug() << "Using audio device:" << deviceInfo.description()
             << "isNull:" << deviceInfo.isNull();

    if (deviceInfo.isNull())
        qWarning() << "No audio output device available!";

    if (!deviceInfo.isFormatSupported(format)) {
        qDebug() << "Float not supported, falling back to Int32";
        format.setSampleFormat(QAudioFormat::Int32);
        if (!deviceInfo.isFormatSupported(format)) {
            qDebug() << "Int32 not supported either, falling back to Int16";
            format.setSampleFormat(QAudioFormat::Int16);
        }
    }

    m_audioSink = new QAudioSink(deviceInfo, format, this);
    m_audioSink->setBufferSize(65536);       // Request large buffer to reduce drain frequency
    connect(m_audioSink, &QAudioSink::stateChanged, this, [this](QAudio::State state) {
        qDebug() << "AudioSink state changed:" << state;
    });

    m_format = format;
    switch (format.sampleFormat()) {
    case QAudioFormat::Float: m_bytesPerSample = 4; break;
    case QAudioFormat::Int32: m_bytesPerSample = 4; break;
    case QAudioFormat::Int16: m_bytesPerSample = 2; break;
    default:                  m_bytesPerSample = 2; break;
    }

    qDebug() << "AudioEngine: actual buffer size:" << m_audioSink->bufferSize();

    m_audioTimer = new QTimer(this);
    m_audioTimer->setInterval(8);  // ~125 Hz — fast enough to keep small buffers filled
    connect(m_audioTimer, &QTimer::timeout, this, &AudioEngine::writeAudio);

    qDebug() << "AudioEngine initialized. Format:" << format.sampleFormat()
             << "Rate:" << format.sampleRate()
             << "Channels:" << format.channelCount()
             << "BytesPerSample:" << m_bytesPerSample;
}

AudioEngine::~AudioEngine()
{
    stop();
}

void AudioEngine::setTimelineModel(TimelineModel *model)
{
    if (m_timeline == model)
        return;
    if (m_timeline)
        disconnect(m_timeline, nullptr, this, nullptr);

    m_timeline = model;
    if (m_timeline) {
        connect(m_timeline, &TimelineModel::playingChanged, this, [this]() {
            qDebug() << "TimelineModel::playingChanged -> audio"
                     << (m_timeline && m_timeline->playing() ? "play" : "pause");
            if (m_timeline && m_timeline->playing())
                play();
            else
                pause();
        });
    }
    emit timelineModelChanged();
    qDebug() << "AudioEngine::setTimelineModel — connected.";
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
    {
        QMutexLocker lock(&m_audioMutex);
        if (m_playing) return;

        if (m_timeline) {
            qreal fps = m_timeline->composition() ? m_timeline->composition()->frameRate() : 30.0;
            if (fps <= 0) fps = 30.0;
            m_currentPositionSamples = (m_timeline->currentFrame() / fps) * 48000;
        }

        m_playing = true;
    }

    // FFmpeg media backend: start() returns a QIODevice* to write to
    m_audioOutputDevice = m_audioSink->start();
    if (!m_audioOutputDevice) {
        qWarning() << "AudioEngine::play() — start() returned null!";
        return;
    }
    qDebug() << "AudioEngine::play() — sink state:" << m_audioSink->state()
             << "outputDevice writable:" << m_audioOutputDevice->isWritable();
    m_audioTimer->start();
    emit playingChanged();
}

void AudioEngine::pause()
{
    {
        QMutexLocker lock(&m_audioMutex);
        if (!m_playing) return;
        m_playing = false;
    }

    m_audioTimer->stop();
    m_audioSink->stop();
    m_audioOutputDevice = nullptr;
    qDebug() << "AudioEngine::pause() — sink state:" << m_audioSink->state();
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

void AudioEngine::writeAudio()
{
    QMutexLocker lock(&m_audioMutex);
    if (!m_playing || !m_timeline || !m_audioOutputDevice)
        return;

    const int sampleRate = 48000;
    const int channels = 2;
    const int bytesPerFrame = channels * m_bytesPerSample;
    qreal fps = 30.0;
    auto *comp = m_timeline->composition();
    if (comp) fps = qMax(1.0, comp->frameRate());

    // Keep writing chunks until the backend's buffer is full.
    // This prevents silent gaps: we push as much data as the backend accepts
    // in one batch, then the timer refills when space frees up.
    static double positionDebugged = -1;
    for (int iteration = 0; iteration < 4; iteration++) {
        qint64 freeBytes = m_audioSink->bytesFree();
        if (freeBytes <= 0)
            break;

        int framesThisIter = freeBytes / bytesPerFrame;
        if (framesThisIter <= 0) break;

        int writeSize = framesThisIter * bytesPerFrame;

        // Build audio for this chunk
        QVector<float> leftBuf(framesThisIter, 0.0f);
        QVector<float> rightBuf(framesThisIter, 0.0f);
        float* buffers[2] = { leftBuf.data(), rightBuf.data() };

        if (comp) {
            for (int li = 0; li < comp->layerCount(); li++) {
                auto *tl = comp->layerAt(li);
                for (int ti = 0; ti < tl->trackCount(); ti++) {
                    auto *tr = tl->trackAt(ti);
                    if (!tr || tr->trackType() != Track::Audio || tr->mute()) continue;

                    qreal trackVol = tr->opacity() * m_masterVolume;

                    for (int si = 0; si < tr->stripCount(); si++) {
                        auto *st = tr->stripAt(si);
                        double startSample = (st->startFrame() / fps) * sampleRate;
                        double endSample = ((st->startFrame() + st->duration()) / fps) * sampleRate;

                        if (m_currentPositionSamples >= startSample
                            && m_currentPositionSamples < endSample) {
                            AudioLayer *al = qobject_cast<AudioLayer*>(st->element());
                            if (!al) continue;

                            double clipOffsetSamples = m_currentPositionSamples - startSample;
                            const QVector<float>& fullData = al->fullAudioData();
                            int nChannels = al->channels();
                            if (fullData.isEmpty()) continue;

                            for (int i = 0; i < framesThisIter; i++) {
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
                                    effect->clapInstance()->process(buffers, buffers, 2, framesThisIter);
                                else if (effect->vst3Instance())
                                    effect->vst3Instance()->process(buffers, buffers, 2, framesThisIter);
                            }
                        }
                    }
                }
            }
        }

        // Convert float mix to native format
        QByteArray buffer(writeSize, 0);
        float *fData = reinterpret_cast<float*>(buffer.data());
        QAudioFormat::SampleFormat outFmt = m_format.sampleFormat();
        for (int i = 0; i < framesThisIter; i++) {
            switch (outFmt) {
            case QAudioFormat::Float:
                fData[i * 2]     = leftBuf[i];
                fData[i * 2 + 1] = rightBuf[i];
                break;
            case QAudioFormat::Int32: {
                auto *out = reinterpret_cast<qint32*>(buffer.data());
                out[i * 2]     = qBound(-2147483648LL, qint64(leftBuf[i] * 2147483647.f), 2147483647LL);
                out[i * 2 + 1] = qBound(-2147483648LL, qint64(rightBuf[i] * 2147483647.f), 2147483647LL);
                break;
            }
            case QAudioFormat::Int16: {
                auto *out = reinterpret_cast<qint16*>(buffer.data());
                out[i * 2]     = qBound(-32768, qint16(leftBuf[i] * 32767.f), 32767);
                out[i * 2 + 1] = qBound(-32768, qint16(rightBuf[i] * 32767.f), 32767);
                break;
            }
            default:
                break;
            }
        }

        qint64 written = m_audioOutputDevice->write(buffer);
        if (written <= 0)
            break;

        int framesWritten = written / bytesPerFrame;
        m_currentPositionSamples += framesWritten;

        if (positionDebugged != m_currentPositionSamples) {
            positionDebugged = m_currentPositionSamples;
            qDebug() << "writeAudio: wrote" << written << "bytes (" << framesWritten << "frames)"
                     << "free=" << freeBytes << "posSamples=" << m_currentPositionSamples;
        }
    }

    // Drift correction
    int audioFrame = qFloor((m_currentPositionSamples / sampleRate) * fps);
    int timelineFrame = m_timeline->currentFrame();
    if (qAbs(audioFrame - timelineFrame) > 1)
        m_currentPositionSamples = (timelineFrame / fps) * sampleRate;
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
                if (frame >= start && frame < end)
                    return qobject_cast<AudioLayer*>(st->element());
            }
        }
    }
    return nullptr;
}

void AudioEngine::processAudioBlock(float **buffers, int nChannels, int nFrames, int frame)
{
    Q_UNUSED(buffers); Q_UNUSED(nChannels); Q_UNUSED(nFrames); Q_UNUSED(frame);
}
