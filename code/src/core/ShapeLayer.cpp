#include "ShapeLayer.h"

ShapeLayer::ShapeLayer(QObject *parent)
    : Layer(Layer::ShapeLayer, parent)
{
    setName("Shape");
}

void ShapeLayer::setShapeType(ShapeType type)
{
    if (m_shapeType != type) {
        m_shapeType = type;
        emit shapeTypeChanged();
    }
}

void ShapeLayer::setShapeWidth(qreal w)
{
    if (!qFuzzyCompare(m_shapeWidth, w)) {
        m_shapeWidth = w;
        emit shapeGeometryChanged();
    }
}

void ShapeLayer::setShapeHeight(qreal h)
{
    if (!qFuzzyCompare(m_shapeHeight, h)) {
        m_shapeHeight = h;
        emit shapeGeometryChanged();
    }
}

void ShapeLayer::setRadius(qreal r)
{
    if (!qFuzzyCompare(m_radius, r)) {
        m_radius = r;
        emit shapeGeometryChanged();
    }
}

void ShapeLayer::setSides(int s)
{
    if (m_sides != s) {
        m_sides = qBound(3, s, 64);
        emit sidesChanged();
    }
}

void ShapeLayer::setStartAngle(qreal a)
{
    if (!qFuzzyCompare(m_startAngle, a)) {
        m_startAngle = a;
        emit shapeGeometryChanged();
    }
}

void ShapeLayer::setSpanAngle(qreal a)
{
    if (!qFuzzyCompare(m_spanAngle, a)) {
        m_spanAngle = a;
        emit shapeGeometryChanged();
    }
}

void ShapeLayer::setGridColumns(int c)
{
    if (m_gridColumns != c) {
        m_gridColumns = qBound(1, c, 100);
        emit shapeGeometryChanged();
    }
}

void ShapeLayer::setGridRows(int r)
{
    if (m_gridRows != r) {
        m_gridRows = qBound(1, r, 100);
        emit shapeGeometryChanged();
    }
}

void ShapeLayer::setTurns(int t)
{
    if (m_turns != t) {
        m_turns = qBound(1, t, 100);
        emit shapeGeometryChanged();
    }
}

void ShapeLayer::setColor(const QColor &color)
{
    if (m_color != color) {
        m_color = color;
        emit colorChanged();
    }
}

void ShapeLayer::setStrokeColor(const QColor &color)
{
    if (m_strokeColor != color) {
        m_strokeColor = color;
        emit strokeChanged();
    }
}

void ShapeLayer::setStrokeWidth(qreal w)
{
    if (!qFuzzyCompare(m_strokeWidth, w)) {
        m_strokeWidth = w;
        emit strokeChanged();
    }
}

Layer* ShapeLayer::clone(QObject *parent) const
{
    auto *s = new ShapeLayer(parent);
    s->setName(name());
    s->setEnabled(enabled());
    s->setOpacity(opacity());
    s->setVisible(visible());
    s->setX(x());
    s->setY(y());
    s->setRotation(rotation());
    s->setScaleX(scaleX());
    s->setScaleY(scaleY());
    s->setStartFrame(startFrame());
    s->setDuration(duration());
    s->m_shapeType = m_shapeType;
    s->m_shapeWidth = m_shapeWidth;
    s->m_shapeHeight = m_shapeHeight;
    s->m_radius = m_radius;
    s->m_sides = m_sides;
    s->m_startAngle = m_startAngle;
    s->m_spanAngle = m_spanAngle;
    s->m_gridColumns = m_gridColumns;
    s->m_gridRows = m_gridRows;
    s->m_turns = m_turns;
    s->m_color = m_color;
    s->m_strokeColor = m_strokeColor;
    s->m_strokeWidth = m_strokeWidth;
    return s;
}

QJsonObject ShapeLayer::toJson() const
{
    QJsonObject obj = Layer::toJson();
    obj["shapeType"] = (int)m_shapeType;
    obj["shapeWidth"] = m_shapeWidth;
    obj["shapeHeight"] = m_shapeHeight;
    obj["radius"] = m_radius;
    obj["sides"] = m_sides;
    obj["startAngle"] = m_startAngle;
    obj["spanAngle"] = m_spanAngle;
    obj["gridColumns"] = m_gridColumns;
    obj["gridRows"] = m_gridRows;
    obj["turns"] = m_turns;
    obj["color"] = m_color.name();
    obj["strokeColor"] = m_strokeColor.name();
    obj["strokeWidth"] = m_strokeWidth;
    return obj;
}

void ShapeLayer::fromJson(const QJsonObject &obj)
{
    Layer::fromJson(obj);
    setShapeType(static_cast<ShapeType>(obj["shapeType"].toInt()));
    setShapeWidth(obj["shapeWidth"].toDouble(200));
    setShapeHeight(obj["shapeHeight"].toDouble(200));
    setRadius(obj["radius"].toDouble());
    setSides(obj["sides"].toInt(6));
    setStartAngle(obj["startAngle"].toDouble());
    setSpanAngle(obj["spanAngle"].toDouble(360));
    setGridColumns(obj["gridColumns"].toInt(5));
    setGridRows(obj["gridRows"].toInt(5));
    setTurns(obj["turns"].toInt(5));
    setColor(QColor(obj["color"].toString("#eab308")));
    setStrokeColor(QColor(obj["strokeColor"].toString("transparent")));
    setStrokeWidth(obj["strokeWidth"].toDouble());
}
