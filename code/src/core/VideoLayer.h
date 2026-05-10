#ifndef VIDEOLAYER_H
#define VIDEOLAYER_H

#include "Layer.h"
#include <QImage>
#include <QUrl>
#include <QHash>

struct AVFormatContext;
struct AVCodecContext;
struct AVFrame;
struct SwsContext;

class VideoLayer : public Layer
{
    Q_OBJECT
    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(QImage currentImage READ currentImage NOTIFY currentImageChanged)
    Q_PROPERTY(int videoWidth READ videoWidth NOTIFY videoInfoChanged)
    Q_PROPERTY(int videoHeight READ videoHeight NOTIFY videoInfoChanged)
    Q_PROPERTY(double frameRate READ frameRate NOTIFY videoInfoChanged)
    Q_PROPERTY(int frameCount READ frameCount NOTIFY videoInfoChanged)
public:
    explicit VideoLayer(QObject *parent = nullptr);
    ~VideoLayer() override;

    QUrl source() const { return m_source; }
    void setSource(const QUrl &url);

    QImage currentImage() const { return m_currentImage; }
    int videoWidth() const { return m_videoWidth; }
    int videoHeight() const { return m_videoHeight; }
    double frameRate() const { return m_frameRate; }
    int frameCount() const { return m_frameCount; }

    QImage frameAt(int frameNumber);

    Layer* clone(QObject *parent = nullptr) const override;
    QJsonObject toJson() const override;
    void fromJson(const QJsonObject &obj) override;

signals:
    void sourceChanged();
    void currentImageChanged();
    void videoInfoChanged();

private:
    void openVideo();
    void closeVideo();
    QImage decodeFrame(AVFrame *frame);

    QUrl m_source;

    AVFormatContext *m_formatCtx = nullptr;
    AVCodecContext *m_codecCtx = nullptr;
    SwsContext *m_swsCtx = nullptr;
    int m_videoStreamIndex = -1;

    int m_videoWidth = 0;
    int m_videoHeight = 0;
    double m_frameRate = 30.0;
    int m_frameCount = 0;

    QImage m_currentImage;
    mutable QHash<int, QImage> m_frameCache;
};

#endif
