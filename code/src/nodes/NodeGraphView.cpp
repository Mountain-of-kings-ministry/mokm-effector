#include "NodeGraphView.h"
#include "NodeGraph.h"

#include <QtNodes/GraphicsView>
#include <QtNodes/DataFlowGraphicsScene>
#include <QtNodes/BasicGraphicsScene>
#include <QPainter>
#include <QDebug>
#include <QContextMenuEvent>

NodeGraphView::NodeGraphView(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setAcceptHoverEvents(true);
    setAcceptedMouseButtons(Qt::AllButtons);
    setFlag(ItemAcceptsDrops, true);
    setFlag(ItemIsFocusScope, true);

    // Enable multisampling for smooth rendering
    setAntialiasing(true);
    setRenderTarget(QQuickPaintedItem::FramebufferObject);
}

NodeGraphView::~NodeGraphView()
{
    delete m_view;
}

void NodeGraphView::setNodeGraph(NodeGraph *graph)
{
    if (m_nodeGraph != graph)
    {
        // Disconnect from old graph
        if (m_nodeGraph)
            disconnect(m_nodeGraph, &NodeGraph::graphChanged, this, nullptr);

        m_nodeGraph = graph;
        ensureView();
        emit nodeGraphChanged();

        // Repaint when the graph changes (nodes added/removed/connected)
        if (m_nodeGraph)
        {
            connect(m_nodeGraph, &NodeGraph::graphChanged, this, [this]()
                    { update(); });
        }

        update();
    }
}

void NodeGraphView::setScale(qreal s)
{
    s = qBound(0.1, s, 10.0);
    if (!qFuzzyCompare(m_scale, s))
    {
        m_scale = s;
        if (m_view)
            m_view->setupScale(s);
        emit scaleChanged();
        update();
    }
}

void NodeGraphView::setInteractive(bool v)
{
    if (m_interactive != v)
    {
        m_interactive = v;
        emit interactiveChanged();
    }
}

void NodeGraphView::ensureView()
{
    if (!m_nodeGraph || !m_nodeGraph->graphicsScene())
        return;

    // If we already have a view for this scene, reuse it
    if (m_view && m_view->scene() == m_nodeGraph->graphicsScene())
        return;

    // Scene changed — delete old view
    delete m_view;
    m_view = nullptr;

    // Create a new GraphicsView for the scene
    m_view = new QtNodes::GraphicsView();
    m_view->setScene(m_nodeGraph->graphicsScene());
    m_view->setScaleRange(0.1, 10.0);
    m_view->setupScale(m_scale);
    m_view->centerScene();
    m_view->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
    m_view->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
    m_view->setViewportUpdateMode(QGraphicsView::SmartViewportUpdate);
    m_view->setRenderHint(QPainter::Antialiasing);
    m_view->setRenderHint(QPainter::SmoothPixmapTransform);
    m_view->resize(static_cast<int>(width()), static_cast<int>(height()));
}

void NodeGraphView::paint(QPainter *painter)
{
    painter->setRenderHint(QPainter::Antialiasing);
    painter->setRenderHint(QPainter::SmoothPixmapTransform);

    if (!m_nodeGraph || !m_view)
    {
        // Draw placeholder grid
        painter->fillRect(boundingRect(), QColor(30, 30, 30));
        painter->setPen(QColor(50, 50, 50));
        qreal gridSize = 24.0;
        for (qreal x = 0; x < width(); x += gridSize)
            painter->drawLine(QPointF(x, 0), QPointF(x, height()));
        for (qreal y = 0; y < height(); y += gridSize)
            painter->drawLine(QPointF(0, y), QPointF(width(), y));
        return;
    }

    // Ensure the view is sized to match our geometry
    QRectF br = boundingRect();
    QSize viewSize = m_view->viewport()->size();
    if (viewSize != br.size().toSize())
    {
        m_view->resize(static_cast<int>(br.width()), static_cast<int>(br.height()));
    }

    // Render the viewport content directly (view is already sized to match)
    m_view->render(painter, br, m_view->viewport()->rect(), Qt::IgnoreAspectRatio);
}

void NodeGraphView::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    QQuickPaintedItem::geometryChange(newGeometry, oldGeometry);
    if (m_view && newGeometry.isValid())
    {
        m_view->resize(static_cast<int>(newGeometry.width()),
                       static_cast<int>(newGeometry.height()));
    }
}

void NodeGraphView::resetView()
{
    if (m_view)
        m_view->centerScene();
    update();
}

void NodeGraphView::fitContent()
{
    if (m_view)
        m_view->zoomFitAll();
    update();
}

// ── Mouse event forwarding ──

void NodeGraphView::mousePressEvent(QMouseEvent *event)
{
    if (event->button() == Qt::RightButton)
    {
        if (m_view)
        {
            QPointF scenePos = m_view->mapToScene(event->position().toPoint());
            // Only show canvas context menu when clicking empty scene background
            auto item = m_view->scene()->itemAt(scenePos, m_view->transform());
            if (!item)
            {
                QPointF screenPos = event->globalPosition();
                emit canvasRightClicked(scenePos.x(), scenePos.y(), screenPos.x(), screenPos.y());
                return;
            }
            // If an item exists, forward a context menu event to the viewport so the item receives it
            QPoint vpLocal = m_view->viewport()->mapFromGlobal(event->globalPosition().toPoint());
            QContextMenuEvent ctx(QContextMenuEvent::Mouse, vpLocal, event->globalPosition().toPoint());
            QCoreApplication::sendEvent(m_view->viewport(), &ctx);
            qDebug() << "Right-click forwarded as context menu to item:" << item << "scenePos:" << scenePos;
        }
        return;
    }

    if (m_interactive && m_view)
    {
        QPointF scenePos = m_view->mapToScene(event->position().toPoint());
        auto item = m_view->scene()->itemAt(scenePos, m_view->transform());
        qDebug() << "mousePressEvent: scenePos=" << scenePos << " item=" << item;
        QPoint vpLocal = m_view->viewport()->mapFromGlobal(event->globalPosition().toPoint());
        QPointF localF(vpLocal.x(), vpLocal.y());
        QPointF windowF = event->globalPosition();
        QMouseEvent viewEvent(event->type(), localF, windowF, event->globalPosition(),
                              event->button(), event->buttons(), event->modifiers());
        QCoreApplication::sendEvent(m_view->viewport(), &viewEvent);
        m_lastMousePos = event->position();
    }
    update();
}

void NodeGraphView::mouseMoveEvent(QMouseEvent *event)
{
    if (m_interactive && m_view)
    {
        QPoint vpLocal = m_view->viewport()->mapFromGlobal(event->globalPosition().toPoint());
        QPointF localF(vpLocal.x(), vpLocal.y());
        QPointF windowF = event->globalPosition();
        QMouseEvent viewEvent(event->type(), localF, windowF, event->globalPosition(),
                              event->button(), event->buttons(), event->modifiers());
        QCoreApplication::sendEvent(m_view->viewport(), &viewEvent);
    }
    update();
}

void NodeGraphView::mouseReleaseEvent(QMouseEvent *event)
{
    if (m_interactive && m_view)
    {
        QPoint vpLocal = m_view->viewport()->mapFromGlobal(event->globalPosition().toPoint());
        QPointF localF(vpLocal.x(), vpLocal.y());
        QPointF windowF = event->globalPosition();
        QMouseEvent viewEvent(event->type(), localF, windowF, event->globalPosition(),
                              event->button(), event->buttons(), event->modifiers());
        QCoreApplication::sendEvent(m_view->viewport(), &viewEvent);
    }
    update();
}

void NodeGraphView::mouseDoubleClickEvent(QMouseEvent *event)
{
    if (m_interactive && m_view)
    {
        QMouseEvent viewEvent(event->type(), event->position(), event->globalPosition(),
                              event->button(), event->buttons(), event->modifiers());
        QCoreApplication::sendEvent(m_view->viewport(), &viewEvent);
    }
    update();
}

void NodeGraphView::wheelEvent(QWheelEvent *event)
{
    if (m_interactive && m_view)
    {
        QWheelEvent viewEvent(event->position(), event->globalPosition(),
                              event->pixelDelta(), event->angleDelta(),
                              event->buttons(), event->modifiers(),
                              event->phase(), event->inverted());
        QCoreApplication::sendEvent(m_view->viewport(), &viewEvent);
        m_scale = m_view->getScale();
        emit scaleChanged();
    }
    update();
}

void NodeGraphView::keyPressEvent(QKeyEvent *event)
{
    if (m_interactive && m_view)
    {
        QKeyEvent viewEvent(event->type(), event->key(), event->modifiers(),
                            event->text(), event->isAutoRepeat(), static_cast<quint16>(event->count()));
        QCoreApplication::sendEvent(m_view, &viewEvent);
    }
}

void NodeGraphView::keyReleaseEvent(QKeyEvent *event)
{
    if (m_interactive && m_view)
    {
        QKeyEvent viewEvent(event->type(), event->key(), event->modifiers(),
                            event->text(), event->isAutoRepeat(), static_cast<quint16>(event->count()));
        QCoreApplication::sendEvent(m_view, &viewEvent);
    }
}

void NodeGraphView::hoverMoveEvent(QHoverEvent *event)
{
    if (m_interactive && m_view)
    {
        // Update cursor based on what's under the mouse in the scene
        QPointF pos = event->position();
        QPointF scenePos = m_view->mapToScene(pos.toPoint());
        auto item = m_view->scene()->itemAt(scenePos, m_view->transform());
        if (item)
            m_view->viewport()->setCursor(item->cursor());
        else
            m_view->viewport()->setCursor(Qt::ArrowCursor);
    }
    update();
}
