#ifndef COLORWHEELITEM_H
#define COLORWHEELITEM_H

#include <QQuickPaintedItem>
#include <QColor>
#include <QPointF>
#include <QImage>

class ColorWheelItem : public QQuickPaintedItem
{
    Q_OBJECT
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
public:
    explicit ColorWheelItem(QQuickItem *parent = nullptr);

    QColor color() const { return m_color; }
    void setColor(const QColor &c);

    void paint(QPainter *painter) override;

signals:
    void colorChanged(const QColor &color);

protected:
    void mousePressEvent(QMouseEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;

private:
    QPointF posFromColor(const QColor &c) const;
    QColor colorFromPos(const QPointF &pos) const;
    qreal ringRadius() const;
    QRectF ringRect() const;
    QPointF trianglePoint(qreal sat, qreal val) const;

    QColor m_color = Qt::red;
    QImage m_ringCache;
    QImage m_triangleCache;
    bool m_dirty = true;
    bool m_draggingRing = false;
    bool m_draggingTriangle = false;

    qreal m_triSize = 0;
    qreal m_ringWidth = 16;
};

#endif
