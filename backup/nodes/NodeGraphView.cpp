#include "NodeGraphView.h"
#include "NodeGraph.h"

#include <QtNodes/GraphicsView>
#include <QtNodes/DataFlowGraphicsScene>
#include <QtNodes/BasicGraphicsScene>
#include <QtNodes/NodeGraphicsObject>
#include <QPainter>
#include <QDebug>
#include <QContextMenuEvent>
#include <QGraphicsProxyWidget>

// Helper: walk parent chain to find a NodeGraphicsObject
static QtNodes::NodeGraphicsObject *findNodeItem(QGraphicsItem *item)
{
    if (!item) return nullptr;
    auto *node = qgraphicsitem_cast<QtNodes::NodeGraphicsObject *>(item);
    if (node) return node;
    for (QGraphicsItem *p = item->parentItem(); p; p = p->parentItem())
    {
        node = qgraphicsitem_cast<QtNodes::NodeGraphicsObject *>(p);
        if (node) return node;
    }
    return nullptr;
}

NodeGraphView::NodeGraphView(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setAcceptHoverEvents(true);
    setAcceptedMouseButtons(Qt::AllButtons);
    setFlag(ItemAcceptsDrops, true);
    setFlag(ItemIsFocusScope, true);

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
        if (m_nodeGraph)
            disconnect(m_nodeGraph, &NodeGraph::graphChanged, this, nullptr);

        m_nodeGraph = graph;
        ensureView();
        emit nodeGraphChanged();

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

    if (m_view && m_view->scene() == m_nodeGraph->graphicsScene())
        return;

    delete m_view;
    m_view = nullptr;

    m_view = new QtNodes::GraphicsView();
    m_view->setScene(m_nodeGraph->graphicsScene());
    m_view->setDragMode(QGraphicsView::NoDrag);
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
        painter->fillRect(boundingRect(), QColor(30, 30, 30));
        painter->setPen(QColor(50, 50, 50));
        qreal gridSize = 24.0;
        for (qreal x = 0; x < width(); x += gridSize)
            painter->drawLine(QPointF(x, 0), QPointF(x, height()));
        for (qreal y = 0; y < height(); y += gridSize)
            painter->drawLine(QPointF(0, y), QPointF(width(), y));
        return;
    }

    QRectF br = boundingRect();
    QSize viewSize = m_view->viewport()->size();
    if (viewSize != br.size().toSize())
    {
        m_view->resize(static_cast<int>(br.width()), static_cast<int>(br.height()));
    }

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

static const char *itemTypeName(QGraphicsItem *item)
{
    if (!item) return "nullptr";
    if (qgraphicsitem_cast<QtNodes::NodeGraphicsObject *>(item)) return "NodeGraphicsObject";
    if (item->type() == QGraphicsProxyWidget::Type) return "QGraphicsProxyWidget(embedded-widget)";
    return "other";
}

void NodeGraphView::mousePressEvent(QMouseEvent *event)
{
    if (event->button() == Qt::RightButton)
    {
        if (m_view)
        {
            QPointF scenePos = m_view->mapToScene(event->position().toPoint());
            QPointF winPos = event->scenePosition();
            auto item = m_view->scene()->itemAt(scenePos, m_view->transform());

            if (!item)
            {
                qDebug() << "[NODE] Right-click on EMPTY canvas — showing Add Node menu at winPos=" << winPos;
                emit canvasRightClicked(scenePos.x(), scenePos.y(), winPos.x(), winPos.y());
                return;
            }

            auto *nodeItem = findNodeItem(item);
            if (nodeItem)
            {
                QtNodes::NodeId nid = nodeItem->nodeId();
                qDebug() << "[NODE] Right-click on NODE id=" << nid << "(" << itemTypeName(item) << ") — showing node context menu at winPos=" << winPos;
                emit nodeRightClicked(static_cast<int>(nid), winPos.x(), winPos.y());
                return;
            }

            qDebug() << "[NODE] Right-click on non-node item" << item << " — showing canvas menu";
            emit canvasRightClicked(scenePos.x(), scenePos.y(), winPos.x(), winPos.y());
        }
        return;
    }

    if (m_interactive && m_view)
    {
        QPointF scenePos = m_view->mapToScene(event->position().toPoint());
        auto item = m_view->scene()->itemAt(scenePos, m_view->transform());

        auto *nodeItem = findNodeItem(item);

        if (nodeItem)
            qDebug() << "[NODE] Left-click on NODE id=" << static_cast<int>(nodeItem->nodeId()) << " item=" << itemTypeName(item);
        else
            qDebug() << "[NODE] Left-click on EMPTY canvas — will pan on drag";

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
        bool wasDragging = m_isDragging;
        m_isDragging = true;

        QPointF scenePos = m_view->mapToScene(event->position().toPoint());
        QPointF delta = event->position() - m_lastMousePos;

        if (!wasDragging && delta.manhattanLength() > 4)
        {
            auto item = m_view->scene()->itemAt(scenePos, m_view->transform());
            auto *nodeItem = findNodeItem(item);
            if (nodeItem)
                qDebug() << "[NODE] DRAG START — moving NODE id=" << static_cast<int>(nodeItem->nodeId());
            else
                qDebug() << "[NODE] DRAG START — panning canvas";
        }

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

void NodeGraphView::mouseReleaseEvent(QMouseEvent *event)
{
    if (m_interactive && m_view)
    {
        if (m_isDragging)
            qDebug() << "[NODE] DRAG END";
        m_isDragging = false;

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
        QPointF scenePos = m_view->mapToScene(event->position().toPoint());
        auto item = m_view->scene()->itemAt(scenePos, m_view->transform());
        auto *nodeItem = findNodeItem(item);

        // Check if we're near a connection port
        if (nodeItem)
        {
            QRectF nodeRect = nodeItem->boundingRect();
            // Ports are typically at the left (input) and right (output) edges
            qreal portThreshold = 16.0;
            QPointF localPos = nodeItem->mapFromScene(scenePos);
            bool nearLeftEdge = localPos.x() < portThreshold;
            bool nearRightEdge = localPos.x() > nodeRect.width() - portThreshold;
            bool nearPort = nearLeftEdge || nearRightEdge;

            static bool prevNearPort = false;
            if (nearPort && !prevNearPort)
                qDebug() << "[NODE] HOVER — near connection PORT on node id=" << static_cast<int>(nodeItem->nodeId()) << (nearLeftEdge ? "INPUT" : "OUTPUT");
            prevNearPort = nearPort;
        }

        if (item)
            m_view->viewport()->setCursor(item->cursor());
        else
            m_view->viewport()->setCursor(Qt::ArrowCursor);
    }
    update();
}
