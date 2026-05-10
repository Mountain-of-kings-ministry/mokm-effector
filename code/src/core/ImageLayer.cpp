#include "ImageLayer.h"
#include <QFileInfo>

ImageLayer::ImageLayer(QObject *parent)
    : Layer(Layer::ImageLayer, parent)
{
    setName("Image");
    setDuration(90);
}

void ImageLayer::setSource(const QUrl &url)
{
    if (m_source != url) {
        m_source = url;
        emit sourceChanged();
        loadImage();
    }
}

void ImageLayer::loadImage()
{
    QString path = m_source.toLocalFile();
    if (path.isEmpty())
        return;
    QImage img(path);
    if (!img.isNull()) {
        m_image = img;
        emit imageChanged();
    }
}

Layer* ImageLayer::clone(QObject *parent) const
{
    auto *l = new ImageLayer(parent);
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
    l->m_image = m_image;
    return l;
}

QJsonObject ImageLayer::toJson() const
{
    QJsonObject obj = Layer::toJson();
    obj["source"] = m_source.toString();
    return obj;
}

void ImageLayer::fromJson(const QJsonObject &obj)
{
    Layer::fromJson(obj);
    setSource(QUrl(obj["source"].toString()));
}
