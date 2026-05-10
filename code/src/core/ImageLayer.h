#ifndef IMAGELAYER_H
#define IMAGELAYER_H

#include "Layer.h"
#include <QImage>
#include <QUrl>

class ImageLayer : public Layer
{
    Q_OBJECT
    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(QImage image READ image NOTIFY imageChanged)
    Q_PROPERTY(int imageWidth READ imageWidth NOTIFY imageChanged)
    Q_PROPERTY(int imageHeight READ imageHeight NOTIFY imageChanged)
public:
    explicit ImageLayer(QObject *parent = nullptr);
    ~ImageLayer() override = default;

    QUrl source() const { return m_source; }
    void setSource(const QUrl &url);

    QImage image() const { return m_image; }
    int imageWidth() const { return m_image.width(); }
    int imageHeight() const { return m_image.height(); }

    Layer* clone(QObject *parent = nullptr) const override;
    QJsonObject toJson() const override;
    void fromJson(const QJsonObject &obj) override;

signals:
    void sourceChanged();
    void imageChanged();

private:
    void loadImage();

    QUrl m_source;
    QImage m_image;
};

#endif
