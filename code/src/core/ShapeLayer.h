#ifndef SHAPELAYER_H
#define SHAPELAYER_H

#include "Layer.h"
#include <QColor>

class ShapeLayer : public Layer
{
    Q_OBJECT
    Q_PROPERTY(ShapeType shapeType READ shapeType WRITE setShapeType NOTIFY shapeTypeChanged)
    Q_PROPERTY(qreal shapeWidth READ shapeWidth WRITE setShapeWidth NOTIFY shapeGeometryChanged)
    Q_PROPERTY(qreal shapeHeight READ shapeHeight WRITE setShapeHeight NOTIFY shapeGeometryChanged)
    Q_PROPERTY(qreal radius READ radius WRITE setRadius NOTIFY shapeGeometryChanged)
    Q_PROPERTY(int sides READ sides WRITE setSides NOTIFY sidesChanged)
    Q_PROPERTY(qreal startAngle READ startAngle WRITE setStartAngle NOTIFY shapeGeometryChanged)
    Q_PROPERTY(qreal spanAngle READ spanAngle WRITE setSpanAngle NOTIFY shapeGeometryChanged)
    Q_PROPERTY(int gridColumns READ gridColumns WRITE setGridColumns NOTIFY shapeGeometryChanged)
    Q_PROPERTY(int gridRows READ gridRows WRITE setGridRows NOTIFY shapeGeometryChanged)
    Q_PROPERTY(int turns READ turns WRITE setTurns NOTIFY shapeGeometryChanged)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(QColor strokeColor READ strokeColor WRITE setStrokeColor NOTIFY strokeChanged)
    Q_PROPERTY(qreal strokeWidth READ strokeWidth WRITE setStrokeWidth NOTIFY strokeChanged)
public:
    enum ShapeType {
        Rectangle, Ellipse, Circle, Triangle,
        Polygon, Star, Line, Arrow, RoundedRect,
        Arc, Grid, Spiral
    };
    Q_ENUM(ShapeType)

    explicit ShapeLayer(QObject *parent = nullptr);
    ~ShapeLayer() override = default;

    ShapeType shapeType() const { return m_shapeType; }
    void setShapeType(ShapeType type);

    qreal shapeWidth() const { return m_shapeWidth; }
    void setShapeWidth(qreal w);
    qreal shapeHeight() const { return m_shapeHeight; }
    void setShapeHeight(qreal h);
    qreal radius() const { return m_radius; }
    void setRadius(qreal r);
    int sides() const { return m_sides; }
    void setSides(int s);

    qreal startAngle() const { return m_startAngle; }
    void setStartAngle(qreal a);
    qreal spanAngle() const { return m_spanAngle; }
    void setSpanAngle(qreal a);
    int gridColumns() const { return m_gridColumns; }
    void setGridColumns(int c);
    int gridRows() const { return m_gridRows; }
    void setGridRows(int r);
    int turns() const { return m_turns; }
    void setTurns(int t);

    QColor color() const { return m_color; }
    void setColor(const QColor &color);
    QColor strokeColor() const { return m_strokeColor; }
    void setStrokeColor(const QColor &color);
    qreal strokeWidth() const { return m_strokeWidth; }
    void setStrokeWidth(qreal w);

    Layer* clone(QObject *parent = nullptr) const override;
    QJsonObject toJson() const override;
    void fromJson(const QJsonObject &obj) override;

signals:
    void shapeTypeChanged();
    void shapeGeometryChanged();
    void sidesChanged();
    void colorChanged();
    void strokeChanged();

private:
    ShapeType m_shapeType = Rectangle;
    qreal m_shapeWidth = 200;
    qreal m_shapeHeight = 200;
    qreal m_radius = 0;
    int m_sides = 6;
    qreal m_startAngle = 0;
    qreal m_spanAngle = 360;
    int m_gridColumns = 5;
    int m_gridRows = 5;
    int m_turns = 5;
    QColor m_color = QColor("#eab308");
    QColor m_strokeColor = Qt::transparent;
    qreal m_strokeWidth = 0;
};

#endif
