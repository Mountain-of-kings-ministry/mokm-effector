#ifndef AUDIOLAYER_H
#define AUDIOLAYER_H

#include "Layer.h"
#include <QUrl>
#include <QVector>

class AudioLayer : public Layer
{
    Q_OBJECT
    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(qreal volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(qreal pan READ pan WRITE setPan NOTIFY panChanged)
    Q_PROPERTY(bool mute READ mute WRITE setMute NOTIFY muteChanged)
    Q_PROPERTY(bool solo READ solo WRITE setSolo NOTIFY soloChanged)
public:
    explicit AudioLayer(QObject *parent = nullptr);
    ~AudioLayer() override = default;

    QUrl source() const { return m_source; }
    void setSource(const QUrl &url);

    qreal volume() const { return m_volume; }
    void setVolume(qreal v);

    qreal pan() const { return m_pan; }
    void setPan(qreal v);

    bool mute() const { return m_mute; }
    void setMute(bool v);

    bool solo() const { return m_solo; }
    void setSolo(bool v);

    const QVector<float>& waveformData() const { return m_waveformData; }

    Layer* clone(QObject *parent = nullptr) const override;
    QJsonObject toJson() const override;
    void fromJson(const QJsonObject &obj) override;

signals:
    void sourceChanged();
    void volumeChanged();
    void panChanged();
    void muteChanged();
    void soloChanged();

private:
    void loadWaveform();

    QUrl m_source;
    qreal m_volume = 1.0;
    qreal m_pan = 0.0;
    bool m_mute = false;
    bool m_solo = false;
    QVector<float> m_waveformData;
};

#endif
