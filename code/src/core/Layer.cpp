#include "Layer.h"

Layer::Layer(Type type, QObject *parent)
    : QObject(parent), m_type(type), m_name("Layer")
{
}

void Layer::setName(const QString &name)
{
    if (m_name != name) {
        m_name = name;
        emit nameChanged();
    }
}

void Layer::setEnabled(bool enabled)
{
    if (m_enabled != enabled) {
        m_enabled = enabled;
        emit enabledChanged();
    }
}

void Layer::setOpacity(qreal opacity)
{
    opacity = qBound(0.0, opacity, 1.0);
    if (!qFuzzyCompare(m_opacity, opacity)) {
        m_opacity = opacity;
        emit opacityChanged();
    }
}

void Layer::setVisible(bool visible)
{
    if (m_visible != visible) {
        m_visible = visible;
        emit visibleChanged();
    }
}

void Layer::setX(qreal x)
{
    if (!qFuzzyCompare(m_x, x)) {
        m_x = x;
        emit transformChanged();
    }
}

void Layer::setY(qreal y)
{
    if (!qFuzzyCompare(m_y, y)) {
        m_y = y;
        emit transformChanged();
    }
}

void Layer::setRotation(qreal rotation)
{
    if (!qFuzzyCompare(m_rotation, rotation)) {
        m_rotation = rotation;
        emit transformChanged();
    }
}

void Layer::setScaleX(qreal scaleX)
{
    if (!qFuzzyCompare(m_scaleX, scaleX)) {
        m_scaleX = scaleX;
        emit transformChanged();
    }
}

void Layer::setScaleY(qreal scaleY)
{
    if (!qFuzzyCompare(m_scaleY, scaleY)) {
        m_scaleY = scaleY;
        emit transformChanged();
    }
}

void Layer::setStartFrame(int frame)
{
    frame = qMax(0, frame);
    if (m_startFrame != frame) {
        m_startFrame = frame;
        emit startFrameChanged();
    }
}

void Layer::setDuration(int frames)
{
    frames = qMax(1, frames);
    if (m_duration != frames) {
        m_duration = frames;
        emit durationChanged();
    }
}
