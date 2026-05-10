#include "ColorWheelItem.h"
#include <QPainter>
#include <QMouseEvent>
#include <QtMath>
#include <QPolygonF>

ColorWheelItem::ColorWheelItem(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setAcceptHoverEvents(true);
    setAcceptedMouseButtons(Qt::AllButtons);
    m_dirty = true;
}

void ColorWheelItem::setColor(const QColor &c)
{
    if (m_color != c) {
        m_color = c;
        emit colorChanged(c);
        update();
    }
}

void ColorWheelItem::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    QQuickPaintedItem::geometryChange(newGeometry, oldGeometry);
    m_dirty = true;
}

qreal ColorWheelItem::ringRadius() const
{
    return qMin(width(), height()) / 2.0;
}

QRectF ColorWheelItem::ringRect() const
{
    qreal r = ringRadius();
    return QRectF(-r, -r, r * 2, r * 2);
}

QPointF ColorWheelItem::trianglePoint(qreal sat, qreal val) const
{
    qreal r = ringRadius() - m_ringWidth - 4;
    qreal h = r * qSqrt(3) / 2.0;
    qreal triCenterY = -h / 3.0;

    QPointF white(0, -h * 2.0 / 3.0);
    QPointF black(-r * 0.866, triCenterY);
    QPointF hue(r * 0.866, triCenterY);

    qreal s1 = 1.0 - sat;
    qreal s2 = sat * (1.0 - val);
    qreal s3 = sat * val;

    return white * s1 + black * s2 + hue * s3;
}

QPointF ColorWheelItem::posFromColor(const QColor &c) const
{
    float h = 0, s = 0, v = 0, a = 0;
    c.getHsvF(&h, &s, &v, &a);
    qreal cx = width() / 2.0;
    qreal cy = height() / 2.0;

    if (s < 0.01) {
        // Pure grayscale — place on the left edge of triangle
        return QPointF(cx, cy) + trianglePoint(0, v);
    }

    qreal angle = h * 2.0 * M_PI - M_PI_2;
    qreal r = ringRadius() - m_ringWidth / 2.0;
    qreal rx = r * qCos(angle);
    qreal ry = r * qSin(angle);

    // Check if point is on ring (fully saturated) or in triangle
    if (s > 0.99 && v > 0.99) {
        return QPointF(cx + rx, cy + ry);
    }

    return QPointF(cx, cy) + trianglePoint(s, v);
}

QColor ColorWheelItem::colorFromPos(const QPointF &pos) const
{
    qreal cx = width() / 2.0;
    qreal cy = height() / 2.0;
    qreal dx = pos.x() - cx;
    qreal dy = pos.y() - cy;
    qreal dist = qSqrt(dx * dx + dy * dy);

    if (dist < 2) return m_color;

    qreal r = ringRadius();
    qreal innerR = r - m_ringWidth;

    if (dist >= innerR && dist <= r) {
        qreal angle = qAtan2(dy, dx) + M_PI_2;
        if (angle < 0) angle += 2.0 * M_PI;
        qreal hue = angle / (2.0 * M_PI);
        return QColor::fromHsvF(hue, 1.0, 1.0);
    }

    // Triangle area
    qreal triH = (r - m_ringWidth - 4) * qSqrt(3) / 2.0;
    qreal triCenterY = -triH / 3.0;
    QPointF local(dx, dy);

    QPointF white(0, -triH * 2.0 / 3.0);
    qreal triR = (r - m_ringWidth - 4) * 0.866;
    QPointF black(-triR, triCenterY);
    QPointF huePt(triR, triCenterY);

    // Barycentric coordinates
    qreal denom = (black.y() - huePt.y()) * (white.x() - huePt.x())
                + (huePt.x() - black.x()) * (white.y() - huePt.y());
    if (qAbs(denom) < 0.001) return m_color;

    qreal a = ((black.y() - huePt.y()) * (local.x() - huePt.x())
             + (huePt.x() - black.x()) * (local.y() - huePt.y())) / denom;
    qreal b = ((huePt.y() - white.y()) * (local.x() - white.x())
             + (white.x() - huePt.x()) * (local.y() - white.y())) / denom;
    qreal c = 1.0 - a - b;

    if (a < 0 || b < 0 || c < 0 || a > 1 || b > 1 || c > 1)
        return m_color;

    // a = white weight, b = black weight, c = hue weight
    qreal sat = c / (c + b + 0.001);
    qreal val = (c + b) / (a + b + c + 0.001);
    sat = qBound(0.0, sat, 1.0);
    val = qBound(0.0, val, 1.0);

    float h = 0, s = 0, v = 0;
    m_color.getHsvF(&h, &s, &v);
    return QColor::fromHsvF(h, sat, val);
}

void ColorWheelItem::paint(QPainter *painter)
{
    if (width() <= 0 || height() <= 0) return;

    painter->setRenderHint(QPainter::Antialiasing, true);
    painter->translate(width() / 2.0, height() / 2.0);

    qreal r = ringRadius();
    qreal innerR = r - m_ringWidth;

    // ── Hue ring ──
    if (m_dirty) {
        m_ringCache = QImage((int)(r * 2 + 2), (int)(r * 2 + 2), QImage::Format_ARGB32_Premultiplied);
        m_ringCache.fill(Qt::transparent);
        QPainter rp(&m_ringCache);
        rp.setRenderHint(QPainter::Antialiasing, true);
        rp.translate(r + 1, r + 1);
        for (int i = 0; i < 360; ++i) {
            qreal hue = i / 360.0;
            qreal startAngle = (i * 16) - 90 * 16;
            QColor c = QColor::fromHsvF(hue, 1.0, 1.0);
            rp.setPen(QPen(c, m_ringWidth + 1));
            rp.drawArc(QRectF(-innerR, -innerR, innerR * 2, innerR * 2), startAngle, 16);
        }
        m_dirty = false;
    }
    painter->drawImage(QPointF(-r - 1, -r - 1), m_ringCache);

    // ── SV triangle ──
    qreal triR = r - m_ringWidth - 4;
    qreal triH = triR * qSqrt(3) / 2.0;
    qreal triCenterY = -triH / 3.0;

    QPointF white(0, -triH * 2.0 / 3.0);
    QPointF black(-triR * 0.866, triCenterY);
    QPointF huePt(triR * 0.866, triCenterY);

    float h = 0, s = 0, v = 0;
    m_color.getHsvF(&h, &s, &v);

    int triW = qCeil(triR * 1.732);
    int triHpx = qCeil(triH);
    if (m_triangleCache.isNull() || m_triangleCache.size() != QSize(triW, triHpx)) {
        m_triangleCache = QImage(triW, triHpx, QImage::Format_ARGB32_Premultiplied);
    }
    m_triangleCache.fill(Qt::transparent);
    QPainter tp(&m_triangleCache);
    tp.setRenderHint(QPainter::Antialiasing, true);

    QPointF offset(triR * 0.866, triH / 3.0);
    QPolygonF tri;
    tri << white + offset << black + offset << huePt + offset;

    for (int y = 0; y < triHpx; ++y) {
        for (int x = 0; x < triW; ++x) {
            QPointF px(x, y);
            if (!tri.containsPoint(px, Qt::OddEvenFill))
                continue;

            QPointF local = px - offset;
            qreal denom = (black.y() - huePt.y()) * (white.x() - huePt.x())
                        + (huePt.x() - black.x()) * (white.y() - huePt.y());
            if (qAbs(denom) < 0.001) continue;

            qreal a = ((black.y() - huePt.y()) * (local.x() - huePt.x())
                     + (huePt.x() - black.x()) * (local.y() - huePt.y())) / denom;
            qreal b = ((huePt.y() - white.y()) * (local.x() - white.x())
                     + (white.x() - huePt.x()) * (local.y() - white.y())) / denom;
            qreal c = 1.0 - a - b;

            if (a < 0 || b < 0 || c < 0) continue;

            qreal sat = qBound(0.0, c / (c + b + 0.001), 1.0);
            qreal val = qBound(0.0, (c + b) / (a + b + c + 0.001), 1.0);
            tp.setPen(QColor::fromHsvF(h, sat, val));
            tp.drawPoint(x, y);
        }
    }
    tp.end();

    painter->drawImage(QPointF(-triR * 0.866, -triH * 2.0 / 3.0), m_triangleCache);

    // ── Selection indicator ──
    qreal indR = 5;
    QPointF selPos = posFromColor(m_color) - QPointF(width() / 2.0, height() / 2.0);
    painter->setPen(QPen(Qt::white, 2));
    painter->setBrush(Qt::NoBrush);
    painter->drawEllipse(selPos, indR + 1, indR + 1);
    painter->setPen(QPen(Qt::black, 1));
    painter->drawEllipse(selPos, indR + 2, indR + 2);
}

void ColorWheelItem::mousePressEvent(QMouseEvent *event)
{
    qreal cx = width() / 2.0;
    qreal cy = height() / 2.0;
    qreal dx = event->position().x() - cx;
    qreal dy = event->position().y() - cy;
    qreal dist = qSqrt(dx * dx + dy * dy);
    qreal outerR = ringRadius();
    qreal innerR = outerR - m_ringWidth;

    if (dist >= innerR && dist <= outerR) {
        m_draggingRing = true;
        setColor(colorFromPos(event->position()));
        return;
    }

    qreal triR = outerR - m_ringWidth - 4;
    qreal triH = triR * qSqrt(3) / 2.0;
    QPointF white(0, -triH * 2.0 / 3.0);
    qreal triCenterY = -triH / 3.0;
    QPointF black(-triR * 0.866, triCenterY);
    QPointF huePt(triR * 0.866, triCenterY);
    QPolygonF tri;
    tri << white << black << huePt;

    if (tri.containsPoint(QPointF(dx, dy), Qt::OddEvenFill)) {
        m_draggingTriangle = true;
        setColor(colorFromPos(event->position()));
        return;
    }

    QQuickPaintedItem::mousePressEvent(event);
}

void ColorWheelItem::mouseMoveEvent(QMouseEvent *event)
{
    if (m_draggingRing || m_draggingTriangle) {
        setColor(colorFromPos(event->position()));
        return;
    }
    QQuickPaintedItem::mouseMoveEvent(event);
}

void ColorWheelItem::mouseReleaseEvent(QMouseEvent *event)
{
    m_draggingRing = false;
    m_draggingTriangle = false;
    QQuickPaintedItem::mouseReleaseEvent(event);
}
