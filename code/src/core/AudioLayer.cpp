#include "AudioLayer.h"
#include <QFile>
#include <QtMath>
#include <QFileInfo>
#include <QRandomGenerator>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/avutil.h>
#include <libavutil/opt.h>
}

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

void AudioLayer::setCompositionFrameRate(qreal fps)
{
    if (fps <= 0) fps = 30.0;
    if (!qFuzzyCompare(m_compositionFrameRate, fps)) {
        m_compositionFrameRate = fps;
        loadWaveform();
        emit frameCountChanged();
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

double AudioLayer::ffmpegAudioDuration(const QString &path)
{
    AVFormatContext *fmtCtx = nullptr;
    if (avformat_open_input(&fmtCtx, path.toUtf8().constData(), nullptr, nullptr) < 0)
        return 0.0;
    if (avformat_find_stream_info(fmtCtx, nullptr) < 0) {
        avformat_close_input(&fmtCtx);
        return 0.0;
    }
    qreal durationSec = fmtCtx->duration / (qreal)AV_TIME_BASE;
    avformat_close_input(&fmtCtx);
    return qMax(0.0, durationSec);
}

QVector<float> AudioLayer::ffmpegWaveform(const QString &path, int targetSamples)
{
    QVector<float> result;
    AVFormatContext *fmtCtx = nullptr;
    if (avformat_open_input(&fmtCtx, path.toUtf8().constData(), nullptr, nullptr) < 0)
        return result;
    if (avformat_find_stream_info(fmtCtx, nullptr) < 0) {
        avformat_close_input(&fmtCtx);
        return result;
    }

    int audioStream = -1;
    for (unsigned i = 0; i < fmtCtx->nb_streams; i++) {
        if (fmtCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            audioStream = i;
            break;
        }
    }
    if (audioStream < 0) {
        avformat_close_input(&fmtCtx);
        return result;
    }

    const AVCodec *codec = avcodec_find_decoder(fmtCtx->streams[audioStream]->codecpar->codec_id);
    if (!codec) {
        avformat_close_input(&fmtCtx);
        return result;
    }

    AVCodecContext *codecCtx = avcodec_alloc_context3(codec);
    if (!codecCtx) {
        avformat_close_input(&fmtCtx);
        return result;
    }
    if (avcodec_parameters_to_context(codecCtx, fmtCtx->streams[audioStream]->codecpar) < 0) {
        avcodec_free_context(&codecCtx);
        avformat_close_input(&fmtCtx);
        return result;
    }
    if (avcodec_open2(codecCtx, codec, nullptr) < 0) {
        avcodec_free_context(&codecCtx);
        avformat_close_input(&fmtCtx);
        return result;
    }

    QVector<float> allSamples;
    AVPacket *pkt = av_packet_alloc();
    AVFrame *frame = av_frame_alloc();

    while (av_read_frame(fmtCtx, pkt) >= 0) {
        if (pkt->stream_index == audioStream) {
            if (avcodec_send_packet(codecCtx, pkt) == 0) {
                while (avcodec_receive_frame(codecCtx, frame) == 0) {
                    int channels = frame->ch_layout.nb_channels;
                    int nbSamples = frame->nb_samples;
                    if (!frame->data[0] || nbSamples <= 0)
                        continue;
                    for (int j = 0; j < nbSamples; j++) {
                        float val = 0.0f;
                        switch (frame->format) {
                        case AV_SAMPLE_FMT_FLT:
                            if (j * channels + 1 <= nbSamples * channels)
                                val = ((float*)frame->data[0])[j * channels];
                            break;
                        case AV_SAMPLE_FMT_FLTP:
                            val = ((float*)frame->data[0])[j];
                            break;
                        case AV_SAMPLE_FMT_S16:
                            if (j * channels + 1 <= nbSamples * channels)
                                val = ((int16_t*)frame->data[0])[j * channels] / 32768.0f;
                            break;
                        case AV_SAMPLE_FMT_S16P:
                            val = ((int16_t*)frame->data[0])[j] / 32768.0f;
                            break;
                        case AV_SAMPLE_FMT_S32:
                            if (j * channels + 1 <= nbSamples * channels)
                                val = ((int32_t*)frame->data[0])[j * channels] / 2147483648.0f;
                            break;
                        case AV_SAMPLE_FMT_S32P:
                            val = ((int32_t*)frame->data[0])[j] / 2147483648.0f;
                            break;
                        case AV_SAMPLE_FMT_U8:
                            if (j * channels + 1 <= nbSamples * channels)
                                val = ((uint8_t*)frame->data[0])[j * channels] / 128.0f - 1.0f;
                            break;
                        case AV_SAMPLE_FMT_U8P:
                            val = ((uint8_t*)frame->data[0])[j] / 128.0f - 1.0f;
                            break;
                        case AV_SAMPLE_FMT_DBL:
                            if (j * channels + 1 <= nbSamples * channels)
                                val = (float)((double*)frame->data[0])[j * channels];
                            break;
                        case AV_SAMPLE_FMT_DBLP:
                            val = (float)((double*)frame->data[0])[j];
                            break;
                        default:
                            val = 0.0f;
                        }
                        allSamples.append(val);
                    }
                    av_frame_unref(frame);
                }
            }
        }
        av_packet_unref(pkt);
    }

    av_frame_free(&frame);
    av_packet_free(&pkt);
    avcodec_free_context(&codecCtx);
    avformat_close_input(&fmtCtx);

    if (allSamples.isEmpty())
        return result;

    result.reserve(targetSamples);
    int step = qMax(1, allSamples.size() / targetSamples);
    for (int i = 0; i < allSamples.size(); i += step)
        result.append(allSamples.at(i));

    return result;
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

    bool isWav = (data.size() >= 12
                  && qstrncmp(data.constData(), "RIFF", 4) == 0
                  && qstrncmp(data.constData() + 8, "WAVE", 4) == 0);

    if (isWav && data.size() >= 44) {
        int channels = *reinterpret_cast<const quint16*>(data.constData() + 22);
        int sampleRate = *reinterpret_cast<const quint32*>(data.constData() + 24);
        int bitsPerSample = *reinterpret_cast<const quint16*>(data.constData() + 34);

        if (channels > 0 && sampleRate > 0 && bitsPerSample > 0) {
            int dataOffset = -1;
            int dataSize = 0;
            for (int i = 12; i < data.size() - 8; i++) {
                if (qstrncmp(data.constData() + i, "data", 4) == 0) {
                    dataOffset = i + 8;
                    dataSize = *reinterpret_cast<const quint32*>(data.constData() + i + 4);
                    break;
                }
            }
            if (dataOffset >= 0 && dataSize > 0) {
                dataSize = qMin(dataSize, data.size() - dataOffset);
                int bytesPerSample = bitsPerSample / 8;
                if (bytesPerSample > 0) {
                    int totalSamples = dataSize / bytesPerSample / channels;
                    m_frameCount = qMax(1, (int)((qreal)totalSamples / sampleRate * m_compositionFrameRate + 0.5));
                    setDuration(m_frameCount);

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
                    emit frameCountChanged();
                    return;
                }
            }
        }
    }

    // Non-WAV: use FFmpeg
    m_fullAudioData.clear();
    double durationSec = ffmpegAudioDuration(path);
    if (durationSec > 0) {
        m_frameCount = qMax(1, (int)(durationSec * m_compositionFrameRate + 0.5));
        setDuration(m_frameCount);
        
        // Use a modified ffmpegWaveform to get full data
        // For now, let's keep the existing logic and add full data decoding
        AVFormatContext *fmtCtx = nullptr;
        if (avformat_open_input(&fmtCtx, path.toUtf8().constData(), nullptr, nullptr) >= 0) {
            if (avformat_find_stream_info(fmtCtx, nullptr) >= 0) {
                int audioStream = -1;
                for (unsigned i = 0; i < fmtCtx->nb_streams; i++) {
                    if (fmtCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
                        audioStream = i; break;
                    }
                }
                if (audioStream >= 0) {
                    const AVCodec *codec = avcodec_find_decoder(fmtCtx->streams[audioStream]->codecpar->codec_id);
                    AVCodecContext *codecCtx = avcodec_alloc_context3(codec);
                    avcodec_parameters_to_context(codecCtx, fmtCtx->streams[audioStream]->codecpar);
                    avcodec_open2(codecCtx, codec, nullptr);
                    
                    m_sampleRate = codecCtx->sample_rate;
                    m_channels = codecCtx->ch_layout.nb_channels;
                    
                    int pktCount = 0;
                    int frameCount = 0;
                    
                    AVPacket *pkt = av_packet_alloc();
                    AVFrame *frame = av_frame_alloc();
                    while (av_read_frame(fmtCtx, pkt) >= 0) {
                        if (pkt->stream_index == audioStream) {
                            pktCount++;
                            if (avcodec_send_packet(codecCtx, pkt) == 0) {
                                while (avcodec_receive_frame(codecCtx, frame) == 0) {
                                    frameCount++;
                                    int nbSamples = frame->nb_samples;
                                    for (int j = 0; j < nbSamples; j++) {
                                        for (int c = 0; c < m_channels; c++) {
                                            float val = 0.0f;
                                            switch (codecCtx->sample_fmt) {
                                                case AV_SAMPLE_FMT_FLT:
                                                case AV_SAMPLE_FMT_FLTP:
                                                    val = av_sample_fmt_is_planar(codecCtx->sample_fmt) ? 
                                                          ((float*)frame->data[c])[j] : ((float*)frame->data[0])[j * m_channels + c];
                                                    break;
                                                case AV_SAMPLE_FMT_S16:
                                                case AV_SAMPLE_FMT_S16P:
                                                    val = av_sample_fmt_is_planar(codecCtx->sample_fmt) ? 
                                                          ((int16_t*)frame->data[c])[j] / 32768.0f : ((int16_t*)frame->data[0])[j * m_channels + c] / 32768.0f;
                                                    break;
                                                case AV_SAMPLE_FMT_S32:
                                                case AV_SAMPLE_FMT_S32P:
                                                    val = av_sample_fmt_is_planar(codecCtx->sample_fmt) ? 
                                                          ((int32_t*)frame->data[c])[j] / 2147483648.0f : ((int32_t*)frame->data[0])[j * m_channels + c] / 2147483648.0f;
                                                    break;
                                                default:
                                                    val = 0.0f;
                                            }
                                            m_fullAudioData.append(val);
                                        }
                                    }
                                    av_frame_unref(frame);
                                }
                            }
                        }
                        av_packet_unref(pkt);
                    }
                    qDebug() << "FFmpeg decoding finished. Packets read:" << pktCount << "Frames decoded:" << frameCount << "Samples stored:" << m_fullAudioData.size();
                    av_frame_free(&frame);
                    av_packet_free(&pkt);
                    avcodec_free_context(&codecCtx);
                }
            }
            avformat_close_input(&fmtCtx);
        }

        // Re-generate waveform from full data
        int displaySamples = 1200;
        int totalSamples = m_fullAudioData.size() / m_channels;
        int step = qMax(1, totalSamples / displaySamples);
        m_waveformData.clear();
        for (int i = 0; i < totalSamples; i += step) {
            m_waveformData.append(m_fullAudioData.at(i * m_channels));
        }
        emit frameCountChanged();
    }
}

QVariantList AudioLayer::waveformDataList() const
{
    QVariantList list;
    list.reserve(m_waveformData.size());
    for (float v : m_waveformData)
        list.append(v);
    return list;
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
    l->m_compositionFrameRate = m_compositionFrameRate;
    l->m_volume = m_volume;
    l->m_pan = m_pan;
    l->m_mute = m_mute;
    l->m_solo = m_solo;
    l->m_waveformData = m_waveformData;
    l->m_fullAudioData = m_fullAudioData;
    l->m_sampleRate = m_sampleRate;
    l->m_channels = m_channels;
    return l;
}

QJsonObject AudioLayer::toJson() const
{
    QJsonObject obj = Layer::toJson();
    obj["source"] = m_source.toString();
    obj["compositionFrameRate"] = m_compositionFrameRate;
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
