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
    QString path = m_source.toLocalFile();
    if (path.isEmpty())
        return;

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return;

    QByteArray data = file.readAll();
    file.close();

    // Simple peak-based waveform extraction (works for WAV/AIFF raw PCM)
    // For compressed formats, a proper decoder will be needed later
    int sampleCount = qMin(data.size() / 2, 12000);
    if (sampleCount <= 0) {
        // Generate demo waveform for unsupported formats
        for (int i = 0; i < 1200; i++)
            m_waveformData.append(static_cast<float>(qSin(i * 0.08) * 0.7 + ((QRandomGenerator::global()->bounded(100)) / 100.0 - 0.5) * 0.3));
        return;
    }

    int step = qMax(1, sampleCount / 1200);
    m_waveformData.reserve(sampleCount / step);
    for (int i = 0; i < sampleCount; i += step) {
        qint16 sample = *reinterpret_cast<const qint16*>(data.constData() + (i * 2 % data.size()));
        m_waveformData.append(sample / 32768.0f);
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
