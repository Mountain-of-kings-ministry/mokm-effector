#include "ThorVGViewport.h"
#include "../core/Composition.h"
#include "../core/Layer.h"
#include "../core/ShapeLayer.h"
#include "../core/TextLayer.h"
#include "../core/Track.h"

#include <QPainter>
#include <QFontMetrics>
#include <QMouseEvent>
#include <QCursor>

ThorVGViewport::ThorVGViewport(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setAntialiasing(true);
    setAcceptHoverEvents(true);
    setAcceptedMouseButtons(Qt::AllButtons);
    connect(this, &QQuickPaintedItem::widthChanged, this, [this]{ update(); });
    connect(this, &QQuickPaintedItem::heightChanged, this, [this]{ update(); });
}

ThorVGViewport::~ThorVGViewport() = default;

void ThorVGViewport::setComposition(Composition *comp)
{
    if (m_composition == comp)
        return;

    if (m_composition)
        disconnect(m_composition, nullptr, this, nullptr);

    for (auto *layer : m_connectedLayers)
        disconnect(layer, nullptr, this, nullptr);
    m_connectedLayers.clear();

    m_composition = comp;

    if (comp) {
        connect(comp, &Composition::layersChanged, this, [this]{ reconnectLayerSignals(); update(); });
        connect(comp, &Composition::resolutionChanged, this, [this]{ update(); });
        reconnectLayerSignals();
    }
    emit compositionChanged();
    update();
}

void ThorVGViewport::reconnectLayerSignals()
{
    for (auto *layer : m_connectedLayers)
        disconnect(layer, nullptr, this, nullptr);
    m_connectedLayers.clear();

    if (!m_composition)
        return;

    for (int i = 0; i < m_composition->flatLayerCount(); ++i) {
        auto *layer = m_composition->flatLayerAt(i);
        if (!layer) continue;
        connect(layer, &Layer::transformChanged, this, [this]{ update(); });
        connect(layer, &Layer::opacityChanged, this, [this]{ update(); });
        connect(layer, &Layer::visibleChanged, this, [this]{ update(); });
        connect(layer, &Layer::enabledChanged, this, [this]{ update(); });
        connect(layer, &Layer::startFrameChanged, this, [this]{ update(); });
        connect(layer, &Layer::durationChanged, this, [this]{ update(); });
        m_connectedLayers.append(layer);
    }
}

void ThorVGViewport::setCurrentFrame(int frame)
{
    if (m_currentFrame != frame) {
        m_currentFrame = frame;
        emit currentFrameChanged();
        update();
    }
}

void ThorVGViewport::setSelectedLayers(const QVariantList &layers)
{
    m_selectedLayers.clear();
    for (const auto &v : layers) {
        auto *layer = qvariant_cast<Layer*>(v);
        if (layer)
            m_selectedLayers.insert(layer);
    }
    update();
}

void ThorVGViewport::paint(QPainter *painter)
{
    painter->setRenderHint(QPainter::Antialiasing, true);

    QColor bg(26, 26, 26);
    painter->fillRect(boundingRect(), bg);

    if (!m_composition)
        return;

    // Checkerboard
    int checkSize = 16;
    QColor c1(40, 40, 40);
    QColor c2(50, 50, 50);
    for (int y = 0; y < height(); y += checkSize) {
        for (int x = 0; x < width(); x += checkSize) {
            painter->fillRect(x, y, checkSize, checkSize,
                              ((x / checkSize + y / checkSize) % 2) ? c1 : c2);
        }
    }

    qreal compW = m_composition->width();
    qreal compH = m_composition->height();
    if (compW <= 0 || compH <= 0) return;

    qreal scale = qMin(width() / compW, height() / compH);
    qreal offsetX = (width() - compW * scale) / 2.0;
    qreal offsetY = (height() - compH * scale) / 2.0;

    painter->save();
    painter->translate(offsetX, offsetY);
    painter->scale(scale, scale);

    painter->setClipRect(0, 0, (int)compW, (int)compH);
    painter->fillRect(0, 0, (int)compW, (int)compH, QColor(18, 18, 18));

    // Render layers bottom-to-top with selection outlines
    for (int i = 0; i < m_composition->flatLayerCount(); ++i) {
        auto *layer = m_composition->flatLayerAt(i);
        if (!layer || !layer->enabled() || !layer->visible())
            continue;
        if (m_currentFrame < layer->startFrame() || m_currentFrame >= layer->startFrame() + layer->duration())
            continue;

        painter->save();
        painter->setOpacity(layer->opacity());
        painter->translate(layer->x(), layer->y());
        painter->translate(compW / 2.0, compH / 2.0);
        painter->rotate(layer->rotation());
        painter->scale(layer->scaleX(), layer->scaleY());
        painter->translate(-compW / 2.0, -compH / 2.0);

        if (layer->type() == Layer::ShapeLayer)
            renderShapeLayer(painter, qobject_cast<ShapeLayer*>(layer));
        else if (layer->type() == Layer::TextLayer)
            renderTextLayer(painter, qobject_cast<TextLayer*>(layer));

        painter->restore();

        // Selection outline
        if (m_selectedLayers.contains(layer))
            renderSelectionOutline(painter, layer);
    }

    painter->restore();

    // Box select rubber-band
    if (m_boxSelecting) {
        painter->save();
        QPen boxPen(QColor("#0066ff"), 1);
        boxPen.setStyle(Qt::DashLine);
        painter->setPen(boxPen);
        painter->setBrush(QColor(0, 102, 255, 30));
        QRectF boxRect = QRectF(m_boxStart, m_boxCurrent).normalized();
        // Map from comp space to viewport space
        qreal bx = boxRect.x() * scale + offsetX;
        qreal by = boxRect.y() * scale + offsetY;
        qreal bw = boxRect.width() * scale;
        qreal bh = boxRect.height() * scale;
        painter->drawRect(bx, by, bw, bh);
        painter->restore();
    }
}

void ThorVGViewport::renderShapeLayer(QPainter *painter, ShapeLayer *layer)
{
    if (!layer) return;

    qreal w = layer->shapeWidth();
    qreal h = layer->shapeHeight();
    qreal r = layer->radius();
    QRectF rect(-w / 2.0, -h / 2.0, w, h);

    QPen pen(layer->strokeColor(), layer->strokeWidth());

    switch (layer->shapeType()) {
    case ShapeLayer::Rectangle:
        painter->setBrush(layer->color());
        painter->setPen(pen);
        if (r > 0)
            painter->drawRoundedRect(rect, r, r);
        else
            painter->drawRect(rect);
        break;
    case ShapeLayer::Ellipse:
        painter->setBrush(layer->color());
        painter->setPen(pen);
        painter->drawEllipse(rect);
        break;
    case ShapeLayer::Circle: {
        painter->setBrush(layer->color());
        painter->setPen(pen);
        qreal d = qMin(w, h);
        painter->drawEllipse(QRectF(-d / 2.0, -d / 2.0, d, d));
        break;
    }
    case ShapeLayer::Triangle: {
        painter->setBrush(layer->color());
        painter->setPen(pen);
        QPolygonF tri;
        tri << QPointF(0, -h / 2.0) << QPointF(-h / 2.0, h / 2.0) << QPointF(w / 2.0, h / 2.0);
        painter->drawPolygon(tri);
        break;
    }
    case ShapeLayer::Polygon: {
        painter->setBrush(layer->color());
        painter->setPen(pen);
        QPolygonF poly;
        int sides = layer->sides();
        qreal a = qMin(w, h) / 2.0;
        for (int i = 0; i < sides; ++i) {
            qreal angle = 2.0 * M_PI * i / sides - M_PI_2;
            poly << QPointF(a * cos(angle), a * sin(angle));
        }
        painter->drawPolygon(poly);
        break;
    }
    case ShapeLayer::Star: {
        painter->setBrush(layer->color());
        painter->setPen(pen);
        QPolygonF star;
        int points = layer->sides();
        qreal outer = qMin(w, h) / 2.0;
        qreal inner = outer * 0.4;
        for (int i = 0; i < points * 2; ++i) {
            qreal angle = M_PI * i / points - M_PI_2;
            qreal r2 = (i % 2 == 0) ? outer : inner;
            star << QPointF(r2 * cos(angle), r2 * sin(angle));
        }
        painter->drawPolygon(star);
        break;
    }
    case ShapeLayer::Line: {
        QPen linePen(layer->strokeColor() == Qt::transparent ? layer->color() : layer->strokeColor(),
                     layer->strokeWidth() > 0 ? layer->strokeWidth() : 2);
        painter->setPen(linePen);
        painter->setBrush(Qt::NoBrush);
        qreal len = qMin(w, h) * 0.8;
        painter->drawLine(QPointF(-len / 2, 0), QPointF(len / 2, 0));
        break;
    }
    case ShapeLayer::Arrow: {
        QPen arrowPen(layer->strokeColor() == Qt::transparent ? layer->color() : layer->strokeColor(),
                      layer->strokeWidth() > 0 ? layer->strokeWidth() : 2);
        painter->setPen(arrowPen);
        painter->setBrush(layer->color());
        qreal len = qMin(w, h) * 0.7;
        qreal head = qMin(w, h) * 0.25;
        QPolygonF arrow;
        arrow << QPointF(len / 2, 0)
              << QPointF(len / 2 - head, -head * 0.4)
              << QPointF(len / 2 - head, head * 0.4);
        painter->drawLine(QPointF(-len / 2, 0), QPointF(len / 2, 0));
        painter->drawPolygon(arrow);
        break;
    }
    case ShapeLayer::RoundedRect: {
        painter->setBrush(layer->color());
        painter->setPen(pen);
        painter->drawRoundedRect(rect, qMin(r > 0 ? r : 20.0, qMin(w, h) / 2.0),
                                 qMin(r > 0 ? r : 20.0, qMin(w, h) / 2.0));
        break;
    }
    case ShapeLayer::Arc: {
        QPen arcPen(layer->strokeColor() == Qt::transparent ? layer->color() : layer->strokeColor(),
                    layer->strokeWidth() > 0 ? layer->strokeWidth() : 2);
        painter->setPen(arcPen);
        painter->setBrush(layer->color());
        qreal sa = layer->startAngle() * 16;
        qreal span = layer->spanAngle() * 16;
        painter->drawPie(rect, static_cast<int>(sa), static_cast<int>(span));
        break;
    }
    case ShapeLayer::Grid: {
        QPen gridPen(layer->strokeColor() == Qt::transparent ? layer->color() : layer->strokeColor(),
                     layer->strokeWidth() > 0 ? layer->strokeWidth() : 1);
        painter->setPen(gridPen);
        painter->setBrush(Qt::NoBrush);
        int cols = layer->gridColumns();
        int rows = layer->gridRows();
        qreal cellSize = w;
        qreal gap = h;
        qreal totalW = cols * cellSize + (cols - 1) * gap;
        qreal totalH = rows * cellSize + (rows - 1) * gap;
        qreal ox = -totalW / 2.0;
        qreal oy = -totalH / 2.0;
        for (int x = 0; x < cols; ++x) {
            for (int y = 0; y < rows; ++y) {
                qreal cx = ox + x * (cellSize + gap);
                qreal cy = oy + y * (cellSize + gap);
                painter->drawRect(QRectF(cx, cy, cellSize, cellSize));
            }
        }
        break;
    }
    case ShapeLayer::Spiral: {
        QPen spiralPen(layer->strokeColor() == Qt::transparent ? layer->color() : layer->strokeColor(),
                       layer->strokeWidth() > 0 ? layer->strokeWidth() : 1.5);
        painter->setPen(spiralPen);
        painter->setBrush(Qt::NoBrush);
        int turns = layer->turns();
        qreal maxRadius = w;
        qreal spacing = h > 0 ? h : 20;
        int segments = turns * 72;
        QPolygonF spiral;
        for (int i = 0; i <= segments; ++i) {
            qreal t = (qreal)i / segments * turns * 2.0 * M_PI;
            qreal radius = spacing * t / (2.0 * M_PI);
            if (radius > maxRadius) break;
            spiral << QPointF(radius * cos(t), radius * sin(t));
        }
        painter->drawPolyline(spiral);
        break;
    }
    }
}

void ThorVGViewport::renderTextLayer(QPainter *painter, TextLayer *layer)
{
    if (!layer) return;

    QFont font(layer->fontFamily(), (int)layer->fontSize());
    font.setWeight(static_cast<QFont::Weight>(layer->fontWeight()));

    painter->setFont(font);
    painter->setPen(layer->color());

    QRectF textRect(-500, -200, 1000, 400);
    painter->drawText(textRect, layer->alignment() | Qt::TextWordWrap, layer->text());
}

void ThorVGViewport::renderSelectionOutline(QPainter *painter, Layer *layer)
{
    QRectF bounds = layerBounds(layer);
    if (bounds.isEmpty()) return;

    painter->save();
    painter->setBrush(Qt::NoBrush);

    // Apply layer transform
    qreal compW = m_composition ? m_composition->width() : 1920;
    qreal compH = m_composition ? m_composition->height() : 1080;
    painter->translate(layer->x(), layer->y());
    painter->translate(compW / 2.0, compH / 2.0);
    painter->rotate(layer->rotation());
    painter->scale(layer->scaleX(), layer->scaleY());
    painter->translate(-compW / 2.0, -compH / 2.0);

    QPen outlinePen(QColor("#0066ff"), 2);
    outlinePen.setStyle(Qt::SolidLine);
    painter->setPen(outlinePen);
    painter->drawRect(bounds);

    // Corner handles
    qreal handleSize = 6;
    QColor handleColor("#0066ff");
    painter->setBrush(handleColor);
    painter->setPen(Qt::NoPen);

    QPointF corners[] = {
        bounds.topLeft(), bounds.topRight(),
        bounds.bottomLeft(), bounds.bottomRight()
    };
    for (auto &c : corners)
        painter->drawRect(QRectF(c.x() - handleSize/2, c.y() - handleSize/2, handleSize, handleSize));

    painter->restore();
}

QRectF ThorVGViewport::layerBounds(Layer *layer) const
{
    if (!layer) return QRectF();

    if (auto *sl = qobject_cast<ShapeLayer*>(layer)) {
        return QRectF(-sl->shapeWidth() / 2.0, -sl->shapeHeight() / 2.0,
                       sl->shapeWidth(), sl->shapeHeight());
    }
    if (auto *tl = qobject_cast<TextLayer*>(layer)) {
        return QRectF(-500, -200, 1000, 400);
    }
    return QRectF(-100, -50, 200, 100);
}

QPointF ThorVGViewport::viewportToComp(QPointF viewportPos) const
{
    if (!m_composition) return viewportPos;
    qreal compW = m_composition->width();
    qreal compH = m_composition->height();
    if (compW <= 0 || compH <= 0) return viewportPos;
    qreal scale = qMin(width() / compW, height() / compH);
    qreal offsetX = (width() - compW * scale) / 2.0;
    qreal offsetY = (height() - compH * scale) / 2.0;
    return QPointF((viewportPos.x() - offsetX) / scale,
                   (viewportPos.y() - offsetY) / scale);
}

Layer *ThorVGViewport::hitTest(qreal compX, qreal compY) const
{
    if (!m_composition) return nullptr;
    qreal compW = m_composition->width();
    qreal compH = m_composition->height();

    for (int i = m_composition->flatLayerCount() - 1; i >= 0; --i) {
        auto *layer = m_composition->flatLayerAt(i);
        if (!layer || !layer->enabled() || !layer->visible())
            continue;
        if (m_currentFrame < layer->startFrame() ||
            m_currentFrame >= layer->startFrame() + layer->duration())
            continue;

        QTransform t;
        t.translate(layer->x(), layer->y());
        t.translate(compW / 2.0, compH / 2.0);
        t.rotate(layer->rotation());
        t.scale(layer->scaleX(), layer->scaleY());
        t.translate(-compW / 2.0, -compH / 2.0);

        bool ok = false;
        t = t.inverted(&ok);
        if (!ok) continue;

        QPointF local = t.map(QPointF(compX, compY));
        QRectF bounds = layerBounds(layer);

        if (bounds.contains(local))
            return layer;
    }
    return nullptr;
}

void ThorVGViewport::mousePressEvent(QMouseEvent *event)
{
    if (event->button() != Qt::LeftButton) {
        QQuickPaintedItem::mousePressEvent(event);
        return;
    }

    QPointF compPos = viewportToComp(event->position());
    Layer *layer = hitTest(compPos.x(), compPos.y());

    if (layer) {
        m_draggedLayer = layer;
        m_dragOffset = QPointF(compPos.x() - layer->x(),
                               compPos.y() - layer->y());
        setCursor(QCursor(Qt::ClosedHandCursor));

        // Multi-select with Shift
        if (event->modifiers() & Qt::ShiftModifier) {
            if (m_selectedLayers.contains(layer))
                m_selectedLayers.remove(layer);
            else
                m_selectedLayers.insert(layer);
        } else if (!m_selectedLayers.contains(layer)) {
            m_selectedLayers.clear();
            m_selectedLayers.insert(layer);
        }
        // If clicking already-selected layer in non-shift mode, keep multi-select

        QVariantList selList;
        for (auto *l : m_selectedLayers)
            selList.append(QVariant::fromValue(l));
        emit selectionChanged(selList);
        emit layerSelected(layer);
        update();
        return;
    }

    // Start box select on empty space
    m_boxSelecting = true;
    m_boxStart = compPos;
    m_boxCurrent = compPos;
    if (!(event->modifiers() & Qt::ShiftModifier)) {
        m_selectedLayers.clear();
        QVariantList empty;
        emit selectionChanged(empty);
        update();
    }

    QQuickPaintedItem::mousePressEvent(event);
}

void ThorVGViewport::mouseMoveEvent(QMouseEvent *event)
{
    if (m_draggedLayer && (event->buttons() & Qt::LeftButton)) {
        QPointF compPos = viewportToComp(event->position());
        m_draggedLayer->setX(compPos.x() - m_dragOffset.x());
        m_draggedLayer->setY(compPos.y() - m_dragOffset.y());
        return;
    }

    if (m_boxSelecting) {
        m_boxCurrent = viewportToComp(event->position());
        update();
        return;
    }

    QQuickPaintedItem::mouseMoveEvent(event);
}

void ThorVGViewport::mouseReleaseEvent(QMouseEvent *event)
{
    if (event->button() == Qt::LeftButton && m_draggedLayer) {
        Layer *layer = m_draggedLayer;
        qreal x = layer->x();
        qreal y = layer->y();
        m_draggedLayer = nullptr;
        unsetCursor();
        emit layerDragFinished(layer, x, y);
        return;
    }

    if (m_boxSelecting) {
        m_boxSelecting = false;

        // Check if this was a click (no drag)
        QPointF diff = m_boxCurrent - m_boxStart;
        bool wasClick = (qAbs(diff.x()) < 3 && qAbs(diff.y()) < 3);

        if (wasClick) {
            if (!(event->modifiers() & Qt::ShiftModifier)) {
                m_selectedLayers.clear();
            }
            // Click without drag on empty space does nothing special
        } else {
            // Select all layers intersecting the box
            QRectF boxRect = QRectF(m_boxStart, m_boxCurrent).normalized();
            for (int i = 0; i < m_composition->flatLayerCount(); ++i) {
                auto *layer = m_composition->flatLayerAt(i);
                if (!layer || !layer->enabled() || !layer->visible())
                    continue;
                if (m_currentFrame < layer->startFrame() ||
                    m_currentFrame >= layer->startFrame() + layer->duration())
                    continue;
                QRectF lb = layerBounds(layer);
                lb.translate(layer->x(), layer->y());
                if (boxRect.intersects(lb))
                    m_selectedLayers.insert(layer);
            }
        }

        QVariantList selList;
        for (auto *l : m_selectedLayers)
            selList.append(QVariant::fromValue(l));
        emit selectionChanged(selList);
        update();
        return;
    }

    QQuickPaintedItem::mouseReleaseEvent(event);
}
