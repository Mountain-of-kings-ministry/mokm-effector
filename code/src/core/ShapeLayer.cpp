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
