#pragma once

#include <QQuickPaintedItem>
#include <QQuickWindow>
#include <QMouseEvent>
#include <QWheelEvent>
#include <QKeyEvent>

namespace QtNodes {
class GraphicsView;
}

class NodeGraph;

class NodeGraphView : public QQuickPaintedItem
{
    Q_OBJECT
    Q_PROPERTY(NodeGraph* nodeGraph READ nodeGraph WRITE setNodeGraph NOTIFY nodeGraphChanged)
    Q_PROPERTY(qreal scale READ scale WRITE setScale NOTIFY scaleChanged)
    Q_PROPERTY(bool interactive READ interactive WRITE setInteractive NOTIFY interactiveChanged)

public:
    explicit NodeGraphView(QQuickItem *parent = nullptr);
    ~NodeGraphView() override;

    NodeGraph* nodeGraph() const { return m_nodeGraph; }
    void setNodeGraph(NodeGraph *graph);

    qreal scale() const { return m_scale; }
    void setScale(qreal s);

    bool interactive() const { return m_interactive; }
    void setInteractive(bool v);

    void paint(QPainter *painter) override;

    Q_INVOKABLE void resetView();
    Q_INVOKABLE void fitContent();

signals:
    void nodeGraphChanged();
    void scaleChanged();
    void interactiveChanged();

protected:
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;
    void mousePressEvent(QMouseEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;
    void mouseDoubleClickEvent(QMouseEvent *event) override;
    void wheelEvent(QWheelEvent *event) override;
    void keyPressEvent(QKeyEvent *event) override;
    void keyReleaseEvent(QKeyEvent *event) override;
    void hoverMoveEvent(QHoverEvent *event) override;

private:
    void ensureView();

    NodeGraph *m_nodeGraph = nullptr;
    QtNodes::GraphicsView *m_view = nullptr;
    qreal m_scale = 1.0;
    bool m_interactive = true;
};
