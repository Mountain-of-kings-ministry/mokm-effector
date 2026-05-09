#include "Composition.h"
#include "Layer.h"

Composition::Composition(QObject *parent)
    : QObject(parent)
{
}

Composition::~Composition()
{
    qDeleteAll(m_layers);
    m_layers.clear();
}

void Composition::setName(const QString &name)
{
    if (m_name != name) {
        m_name = name;
        emit nameChanged();
    }
}

void Composition::setWidth(int w)
{
    if (m_width != w) {
        m_width = w;
        emit resolutionChanged();
    }
}

void Composition::setHeight(int h)
{
    if (m_height != h) {
        m_height = h;
        emit resolutionChanged();
    }
}

void Composition::setDuration(int frames)
{
    frames = qMax(1, frames);
    if (m_duration != frames) {
        m_duration = frames;
        emit durationChanged();
    }
}

void Composition::setFrameRate(qreal fps)
{
    fps = qMax(1.0, fps);
    if (!qFuzzyCompare(m_frameRate, fps)) {
        m_frameRate = fps;
        emit frameRateChanged();
    }
}

QQmlListProperty<Layer> Composition::layers()
{
    return QQmlListProperty<Layer>(this, &m_layers);
}

Layer* Composition::layerAt(int index) const
{
    if (index >= 0 && index < m_layers.size())
        return m_layers[index];
    return nullptr;
}

void Composition::addLayer(Layer *layer)
{
    if (!layer || m_layers.contains(layer))
        return;
    layer->setParent(this);
    m_layers.append(layer);
    emit layersChanged();
}

void Composition::removeLayer(Layer *layer)
{
    if (m_layers.removeOne(layer)) {
        emit layersChanged();
    }
}

void Composition::moveLayer(int fromIndex, int toIndex)
{
    if (fromIndex < 0 || fromIndex >= m_layers.size())
        return;
    if (toIndex < 0 || toIndex >= m_layers.size())
        return;
    if (fromIndex == toIndex)
        return;
    m_layers.move(fromIndex, toIndex);
    emit layersChanged();
}

void Composition::clearLayers()
{
    qDeleteAll(m_layers);
    m_layers.clear();
    emit layersChanged();
}


