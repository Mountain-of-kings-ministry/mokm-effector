#include "ThorVGViewport.h"
#include "../core/Composition.h"
#include "../core/Layer.h"
#include "../core/ShapeLayer.h"
#include "../core/TextLayer.h"

#include <QPainter>
#include <QFontMetrics>
#include <QMouseEvent>
#include <QCursor>
#include "../core/ShapeLayer.h"

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

    for (int i = 0; i < m_composition->layerCount(); ++i) {
        auto *layer = m_composition->layerAt(i);
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

void ThorVGViewport::paint(QPainter *painter)
{
    painter->setRenderHint(QPainter::Antialiasing, true);

    // Background
    QColor bg(26, 26, 26);
    painter->fillRect(boundingRect(), bg);

    if (!m_composition)
        return;

    // Draw checkerboard for transparent areas
    int checkSize = 16;
    QColor c1(40, 40, 40);
    QColor c2(50, 50, 50);
    for (int y = 0; y < height(); y += checkSize) {
        for (int x = 0; x < width(); x += checkSize) {
            painter->fillRect(x, y, checkSize, checkSize,
                              ((x / checkSize + y / checkSize) % 2) ? c1 : c2);
        }
    }

    // Scale to fit composition
    qreal compW = m_composition->width();
    qreal compH = m_composition->height();
    if (compW <= 0 || compH <= 0) return;

    qreal scale = qMin(width() / compW, height() / compH);
    qreal offsetX = (width() - compW * scale) / 2.0;
    qreal offsetY = (height() - compH * scale) / 2.0;

    painter->save();
    painter->translate(offsetX, offsetY);
    painter->scale(scale, scale);

    // Clip to comp bounds
    painter->setClipRect(0, 0, (int)compW, (int)compH);

    // Fill comp background
    painter->fillRect(0, 0, (int)compW, (int)compH, QColor(18, 18, 18));

    // Render layers bottom-to-top
    for (int i = 0; i < m_composition->layerCount(); ++i) {
        auto *layer = m_composition->layerAt(i);
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
    }

    painter->restore();
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

    for (int i = m_composition->layerCount() - 1; i >= 0; --i) {
        auto *layer = m_composition->layerAt(i);
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

        qreal halfW = 100.0;
        qreal halfH = 50.0;
        if (auto *sl = qobject_cast<ShapeLayer*>(layer)) {
            halfW = sl->shapeWidth() / 2.0;
            halfH = sl->shapeHeight() / 2.0;
        }

        if (local.x() >= -halfW && local.x() <= halfW &&
            local.y() >= -halfH && local.y() <= halfH)
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
        return;
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
    QQuickPaintedItem::mouseMoveEvent(event);
}

void ThorVGViewport::mouseReleaseEvent(QMouseEvent *event)
{
    if (event->button() == Qt::LeftButton && m_draggedLayer) {
        m_draggedLayer = nullptr;
        unsetCursor();
        return;
    }
    QQuickPaintedItem::mouseReleaseEvent(event);
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
        tri << QPointF(0, -h / 2.0) << QPointF(-w / 2.0, h / 2.0) << QPointF(w / 2.0, h / 2.0);
        painter->drawPolygon(tri);
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
