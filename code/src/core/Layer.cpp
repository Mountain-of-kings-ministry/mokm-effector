#include "Layer.h"
#include <QJsonArray>
#include <QJsonDocument>

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

void Layer::setBlurRadius(qreal r)
{
    r = qMax(0.0, r);
    if (!qFuzzyCompare(m_blurRadius, r)) {
        m_blurRadius = r;
        emit blurChanged();
    }
}

void Layer::setBlendMode(int mode)
{
    mode = qBound(0, mode, 4);
    if (m_blendMode != mode) {
        m_blendMode = mode;
        emit blendModeChanged();
    }
}

Layer* Layer::clone(QObject *parent) const
{
    auto *l = new Layer(m_type, parent);
    l->m_name = m_name;
    l->m_enabled = m_enabled;
    l->m_opacity = m_opacity;
    l->m_visible = m_visible;
    l->m_x = m_x;
    l->m_y = m_y;
    l->m_rotation = m_rotation;
    l->m_scaleX = m_scaleX;
    l->m_scaleY = m_scaleY;
    l->m_startFrame = m_startFrame;
    l->m_duration = m_duration;
    l->m_blurRadius = m_blurRadius;
    l->m_blendMode = m_blendMode;
    return l;
}

QJsonObject Layer::toJson() const
{
    QJsonObject obj;
    obj["type"] = (m_type == ShapeLayer) ? "shape" : (m_type == TextLayer) ? "text" : "null";
    obj["name"] = m_name;
    obj["enabled"] = m_enabled;
    obj["opacity"] = m_opacity;
    obj["visible"] = m_visible;
    obj["x"] = m_x;
    obj["y"] = m_y;
    obj["rotation"] = m_rotation;
    obj["scaleX"] = m_scaleX;
    obj["scaleY"] = m_scaleY;
    obj["startFrame"] = m_startFrame;
    obj["duration"] = m_duration;
    obj["blurRadius"] = m_blurRadius;
    obj["blendMode"] = m_blendMode;
    return obj;
}

void Layer::fromJson(const QJsonObject &obj)
{
    setName(obj["name"].toString());
    setEnabled(obj["enabled"].toBool(true));
    setOpacity(obj["opacity"].toDouble(1.0));
    setVisible(obj["visible"].toBool(true));
    setX(obj["x"].toDouble());
    setY(obj["y"].toDouble());
    setRotation(obj["rotation"].toDouble());
    setScaleX(obj["scaleX"].toDouble(1.0));
    setScaleY(obj["scaleY"].toDouble(1.0));
    setStartFrame(obj["startFrame"].toInt());
    setDuration(obj["duration"].toInt(90));
    setBlurRadius(obj["blurRadius"].toDouble());
    setBlendMode(obj["blendMode"].toInt());
}

QString Layer::serialize() const
{
    return QString::fromUtf8(QJsonDocument(toJson()).toJson(QJsonDocument::Compact));
}

void Layer::deserialize(const QString &json)
{
    QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8());
    if (doc.isObject())
        fromJson(doc.object());
}
