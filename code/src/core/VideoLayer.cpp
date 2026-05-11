#include "VideoLayer.h"
#include <QFileInfo>
#include <QRandomGenerator>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/imgutils.h>
#include <libavutil/opt.h>
#include <libswscale/swscale.h>
}

VideoLayer::VideoLayer(QObject *parent)
    : Layer(Layer::VideoLayer, parent)
{
    setName("Video");
    setDuration(150);
}

VideoLayer::~VideoLayer()
{
    closeVideo();
}

void VideoLayer::setSource(const QUrl &url)
{
    if (m_source != url) {
        m_source = url;
        emit sourceChanged();
        m_frameCache.clear();
        closeVideo();
        openVideo();
    }
}

void VideoLayer::openVideo()
{
    QString path = m_source.toLocalFile();
    if (path.isEmpty()) return;

    if (avformat_open_input(&m_formatCtx, path.toUtf8().constData(), nullptr, nullptr) != 0)
        return;

    if (avformat_find_stream_info(m_formatCtx, nullptr) < 0) {
        avformat_close_input(&m_formatCtx);
        m_formatCtx = nullptr;
        return;
    }

    m_videoStreamIndex = av_find_best_stream(m_formatCtx, AVMEDIA_TYPE_VIDEO, -1, -1, nullptr, 0);
    if (m_videoStreamIndex < 0) {
        avformat_close_input(&m_formatCtx);
        m_formatCtx = nullptr;
        return;
    }

    const AVStream *stream = m_formatCtx->streams[m_videoStreamIndex];
    const AVCodec *codec = avcodec_find_decoder(stream->codecpar->codec_id);
    if (!codec) {
        avformat_close_input(&m_formatCtx);
        m_formatCtx = nullptr;
        return;
    }

    m_codecCtx = avcodec_alloc_context3(codec);
    if (!m_codecCtx) {
        avformat_close_input(&m_formatCtx);
        m_formatCtx = nullptr;
        return;
    }

    if (avcodec_parameters_to_context(m_codecCtx, stream->codecpar) < 0) {
        avcodec_free_context(&m_codecCtx);
        avformat_close_input(&m_formatCtx);
        m_formatCtx = nullptr;
        return;
    }

    m_codecCtx->thread_count = 0;

    if (avcodec_open2(m_codecCtx, codec, nullptr) < 0) {
        avcodec_free_context(&m_codecCtx);
        avformat_close_input(&m_formatCtx);
        m_formatCtx = nullptr;
        return;
    }

    m_videoWidth = m_codecCtx->width;
    m_videoHeight = m_codecCtx->height;

    if (stream->avg_frame_rate.num && stream->avg_frame_rate.den)
        m_frameRate = av_q2d(stream->avg_frame_rate);
    else if (stream->r_frame_rate.num && stream->r_frame_rate.den)
        m_frameRate = av_q2d(stream->r_frame_rate);
    else
        m_frameRate = 30.0;

    if (m_formatCtx->duration > 0 && m_formatCtx->duration != AV_NOPTS_VALUE) {
        double durationSec = m_formatCtx->duration / (double)AV_TIME_BASE;
        m_frameCount = qMax(1, (int)(durationSec * m_frameRate + 0.5));
    } else if (stream->nb_frames > 0) {
        m_frameCount = (int)stream->nb_frames;
    } else {
        m_frameCount = (int)(150 * m_frameRate / 30.0);
    }

    setDuration(m_frameCount);

    emit videoInfoChanged();
    emit currentImageChanged();
}

void VideoLayer::closeVideo()
{
    m_frameCache.clear();
    if (m_swsCtx) {
        sws_freeContext(m_swsCtx);
        m_swsCtx = nullptr;
    }
    if (m_codecCtx) {
        avcodec_free_context(&m_codecCtx);
        m_codecCtx = nullptr;
    }
    if (m_formatCtx) {
        avformat_close_input(&m_formatCtx);
        m_formatCtx = nullptr;
    }
    m_videoStreamIndex = -1;
    m_videoWidth = 0;
    m_videoHeight = 0;
    m_frameRate = 30.0;
    m_frameCount = 0;
    m_currentImage = QImage();
}

QImage VideoLayer::frameAt(int frameNumber)
{
    if (!m_formatCtx || !m_codecCtx || m_videoStreamIndex < 0)
        return QImage();

    frameNumber = qBound(0, frameNumber, m_frameCount - 1);

    if (m_frameCache.contains(frameNumber))
        return m_frameCache[frameNumber];

    AVStream *stream = m_formatCtx->streams[m_videoStreamIndex];
    AVRational frameRate = stream->avg_frame_rate;

    int64_t targetPts;
    if (frameRate.num && frameRate.den) {
        AVRational frameDuration = av_inv_q(frameRate);
        targetPts = av_rescale_q(frameNumber, frameDuration, stream->time_base);
    } else {
        targetPts = av_rescale_q(frameNumber, (AVRational){1, (int)m_frameRate}, stream->time_base);
    }

    av_seek_frame(m_formatCtx, m_videoStreamIndex, targetPts, AVSEEK_FLAG_BACKWARD);
    avcodec_flush_buffers(m_codecCtx);

    AVFrame *frame = av_frame_alloc();
    AVPacket *packet = av_packet_alloc();

    int maxAttempts = m_frameCount * 2;
    int attempts = 0;
    QImage result;
    int lastFrameDecoded = -1;

    while (attempts < maxAttempts) {
        attempts++;
        int ret = av_read_frame(m_formatCtx, packet);
        if (ret < 0) break;

        if (packet->stream_index != m_videoStreamIndex) {
            av_packet_unref(packet);
            continue;
        }

        ret = avcodec_send_packet(m_codecCtx, packet);
        av_packet_unref(packet);
        if (ret < 0) continue;

        ret = avcodec_receive_frame(m_codecCtx, frame);
        if (ret == 0) {
            lastFrameDecoded++;
            if (lastFrameDecoded == frameNumber) {
                result = decodeFrame(frame);
                m_frameCache.insert(frameNumber, result);
                if (m_frameCache.size() > 60) {
                    auto it = m_frameCache.begin();
                    m_frameCache.erase(it);
                }
                break;
            }
        }
    }

    av_frame_free(&frame);
    av_packet_free(&packet);

    if (!result.isNull())
        m_currentImage = result;

    return result;
}

QImage VideoLayer::decodeFrame(AVFrame *frame)
{
    if (!frame) return QImage();

    if (!m_swsCtx) {
        m_swsCtx = sws_getContext(
            frame->width, frame->height, m_codecCtx->pix_fmt,
            frame->width, frame->height, AV_PIX_FMT_RGBA,
            SWS_BILINEAR, nullptr, nullptr, nullptr);
    }

    QImage img(frame->width, frame->height, QImage::Format_RGBA8888);

    uint8_t *dst[] = { img.bits() };
    int dstStride[] = { (int)img.bytesPerLine() };

    sws_scale(m_swsCtx, frame->data, frame->linesize, 0, frame->height, dst, dstStride);

    return img;
}

Layer* VideoLayer::clone(QObject *parent) const
{
    auto *l = new VideoLayer(parent);
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
    l->setSource(m_source);
    l->m_videoWidth = m_videoWidth;
    l->m_videoHeight = m_videoHeight;
    l->m_frameRate = m_frameRate;
    l->m_frameCount = m_frameCount;
    l->m_currentImage = m_currentImage;
    return l;
}

QJsonObject VideoLayer::toJson() const
{
    QJsonObject obj = Layer::toJson();
    obj["source"] = m_source.toString();
    return obj;
}

void VideoLayer::fromJson(const QJsonObject &obj)
{
    Layer::fromJson(obj);
    setSource(QUrl(obj["source"].toString()));
}
