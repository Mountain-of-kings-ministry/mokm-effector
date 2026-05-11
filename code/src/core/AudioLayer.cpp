#include "AudioLayer.h"
#include <QFile>
#include <QtMath>
#include <QFileInfo>
#include <QRandomGenerator>

AudioLayer::AudioLayer(QObject *parent)
    : Layer(Layer::AudioLayer, parent)
{
    setName("Audio");
}

void AudioLayer::setSource(const QUrl &url)
{
    if (m_source != url) {
        m_source = url;
        emit sourceChanged();
        loadWaveform();
    }
}

void AudioLayer::setVolume(qreal v)
{
    v = qBound(0.0, v, 1.0);
    if (!qFuzzyCompare(m_volume, v)) {
        m_volume = v;
        emit volumeChanged();
    }
}

void AudioLayer::setPan(qreal v)
{
    v = qBound(-1.0, v, 1.0);
    if (!qFuzzyCompare(m_pan, v)) {
        m_pan = v;
        emit panChanged();
    }
}

void AudioLayer::setMute(bool v)
{
    if (m_mute != v) {
        m_mute = v;
        emit muteChanged();
    }
}

void AudioLayer::setSolo(bool v)
{
    if (m_solo != v) {
        m_solo = v;
        emit soloChanged();
    }
}

void AudioLayer::loadWaveform()
{
    m_waveformData.clear();
    m_frameCount = 0;
    QString path = m_source.toLocalFile();
    if (path.isEmpty())
        return;

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return;

    QByteArray data = file.readAll();
    file.close();

    // Parse WAV header to determine duration and extract waveform
    if (data.size() < 44)
        return;

    // WAV header fields (little-endian)
    int channels = *reinterpret_cast<const quint16*>(data.constData() + 22);
    int sampleRate = *reinterpret_cast<const quint32*>(data.constData() + 24);
    int bitsPerSample = *reinterpret_cast<const quint16*>(data.constData() + 34);

    if (channels <= 0 || sampleRate <= 0 || bitsPerSample <= 0)
        return;

    // Find "data" chunk (may not start at offset 36 in all WAV files)
    int dataOffset = 44; // default PCM offset
    int dataSize = *reinterpret_cast<const quint32*>(data.constData() + 40);
    // For non-standard WAV files, search for "data" marker
    if (dataSize <= 0 || dataOffset + dataSize > data.size()) {
        dataOffset = -1;
        for (int i = 0; i < data.size() - 8; i++) {
            if (qstrncmp(data.constData() + i, "data", 4) == 0) {
                dataOffset = i + 8;
                dataSize = *reinterpret_cast<const quint32*>(data.constData() + i + 4);
                break;
            }
        }
        if (dataOffset < 0) return;
    }

    int bytesPerSample = bitsPerSample / 8;
    if (bytesPerSample <= 0) return;
    int totalSamples = dataSize / bytesPerSample / channels;
    int targetFps = 30;
    m_frameCount = qMax(1, (int)((qreal)totalSamples / sampleRate * targetFps + 0.5));
    setDuration(m_frameCount);
    emit frameCountChanged();

    // Generate waveform at ~1200 samples
    int displaySamples = qMin(1200, totalSamples);
    int step = qMax(1, totalSamples / displaySamples);
    m_waveformData.reserve(totalSamples / step);

    if (bitsPerSample == 16) {
        for (int i = 0; i < totalSamples; i += step) {
            int byteOffset = dataOffset + i * bytesPerSample * channels;
            if (byteOffset + bytesPerSample > data.size()) break;
            qint16 sample = *reinterpret_cast<const qint16*>(data.constData() + byteOffset);
            m_waveformData.append(sample / 32768.0f);
        }
    } else if (bitsPerSample == 8) {
        for (int i = 0; i < totalSamples; i += step) {
            int byteOffset = dataOffset + i * bytesPerSample * channels;
            if (byteOffset >= data.size()) break;
            quint8 sample = *reinterpret_cast<const quint8*>(data.constData() + byteOffset);
            m_waveformData.append((sample - 128) / 128.0f);
        }
    } else if (bitsPerSample == 32) {
        for (int i = 0; i < totalSamples; i += step) {
            int byteOffset = dataOffset + i * bytesPerSample * channels;
            if (byteOffset + 4 > data.size()) break;
            float sample = *reinterpret_cast<const float*>(data.constData() + byteOffset);
            m_waveformData.append(qBound(-1.0f, sample, 1.0f));
        }
    }
}

Layer* AudioLayer::clone(QObject *parent) const
{
    auto *l = new AudioLayer(parent);
    l->setName(name());
    l->setEnabled(enabled());
    l->setOpacity(opacity());
    l->setVisible(visible());
    l->setX(x());
    l->setY(y());
    l->setRotation(rotation());
    l->setScaleX(scaleX());
    l->setScaleY(scaleY());
    l->setStartFrame(startFrame());
    l->setDuration(duration());
    l->m_source = m_source;
    l->m_frameCount = m_frameCount;
    l->m_volume = m_volume;
    l->m_pan = m_pan;
    l->m_mute = m_mute;
    l->m_solo = m_solo;
    l->m_waveformData = m_waveformData;
    return l;
}

QJsonObject AudioLayer::toJson() const
{
    QJsonObject obj = Layer::toJson();
    obj["source"] = m_source.toString();
    obj["volume"] = m_volume;
    obj["pan"] = m_pan;
    obj["mute"] = m_mute;
    obj["solo"] = m_solo;
    return obj;
}

void AudioLayer::fromJson(const QJsonObject &obj)
{
    Layer::fromJson(obj);
    setSource(QUrl(obj["source"].toString()));
    setVolume(obj["volume"].toDouble(1.0));
    setPan(obj["pan"].toDouble(0.0));
    setMute(obj["mute"].toBool(false));
    setSolo(obj["solo"].toBool(false));
}
