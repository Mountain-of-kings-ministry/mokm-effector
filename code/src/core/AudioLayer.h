#ifndef AUDIOLAYER_H
#define AUDIOLAYER_H

#include "Layer.h"
#include <QUrl>
#include <QVector>

struct AVFormatContext;

class AudioLayer : public Layer
{
    Q_OBJECT
    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(qreal volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(qreal pan READ pan WRITE setPan NOTIFY panChanged)
    Q_PROPERTY(bool mute READ mute WRITE setMute NOTIFY muteChanged)
    Q_PROPERTY(bool solo READ solo WRITE setSolo NOTIFY soloChanged)
    Q_PROPERTY(int frameCount READ frameCount NOTIFY frameCountChanged)
    Q_PROPERTY(qreal compositionFrameRate READ compositionFrameRate WRITE setCompositionFrameRate NOTIFY frameCountChanged)
    Q_PROPERTY(QVariantList waveformDataList READ waveformDataList NOTIFY sourceChanged)
public:
    explicit AudioLayer(QObject *parent = nullptr);
    ~AudioLayer() override = default;

    QUrl source() const { return m_source; }
    void setSource(const QUrl &url);

    int frameCount() const { return m_frameCount; }

    qreal compositionFrameRate() const { return m_compositionFrameRate; }
    void setCompositionFrameRate(qreal fps);

    qreal volume() const { return m_volume; }
    void setVolume(qreal v);

    qreal pan() const { return m_pan; }
    void setPan(qreal v);

    bool mute() const { return m_mute; }
    void setMute(bool v);

    bool solo() const { return m_solo; }
    void setSolo(bool v);

    const QVector<float>& waveformData() const { return m_waveformData; }
    QVariantList waveformDataList() const;

    Layer* clone(QObject *parent = nullptr) const override;
    QJsonObject toJson() const override;
    void fromJson(const QJsonObject &obj) override;

    // Non-WAV duration via FFmpeg
    static double ffmpegAudioDuration(const QString &path);
    static QVector<float> ffmpegWaveform(const QString &path, int targetSamples);

signals:
    void sourceChanged();
    void volumeChanged();
    void panChanged();
    void muteChanged();
    void soloChanged();
    void frameCountChanged();

private:
    void loadWaveform();

    QUrl m_source;
    qreal m_compositionFrameRate = 30.0;
    qreal m_volume = 1.0;
    qreal m_pan = 0.0;
    bool m_mute = false;
    bool m_solo = false;
    int m_frameCount = 0;
    QVector<float> m_waveformData;
};

#endif
