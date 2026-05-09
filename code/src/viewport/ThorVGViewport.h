#ifndef THORVGVIEWPORT_H
#define THORVGVIEWPORT_H

#include <QQuickPaintedItem>
#include <QPainter>
#include <QTimer>
#include <QVector>
#include <QPointF>

class Composition;
class Layer;
class ShapeLayer;
class TextLayer;

class ThorVGViewport : public QQuickPaintedItem
{
    Q_OBJECT
    Q_PROPERTY(Composition* composition READ composition WRITE setComposition NOTIFY compositionChanged)
    Q_PROPERTY(int currentFrame READ currentFrame WRITE setCurrentFrame NOTIFY currentFrameChanged)
public:
    explicit ThorVGViewport(QQuickItem *parent = nullptr);
    ~ThorVGViewport() override;

    Composition* composition() const { return m_composition; }
    void setComposition(Composition *comp);

    int currentFrame() const { return m_currentFrame; }
    void setCurrentFrame(int frame);

    void paint(QPainter *painter) override;

    void mousePressEvent(QMouseEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;

signals:
    void compositionChanged();
    void currentFrameChanged();
    void layerSelected(Layer *layer);

private:
    void renderShapeLayer(QPainter *painter, ShapeLayer *layer);
    void renderTextLayer(QPainter *painter, TextLayer *layer);
    void reconnectLayerSignals();
    QPointF viewportToComp(QPointF viewportPos) const;
    Layer *hitTest(qreal compX, qreal compY) const;

    Composition *m_composition = nullptr;
    int m_currentFrame = 0;
    QVector<Layer*> m_connectedLayers;
    Layer *m_draggedLayer = nullptr;
    QPointF m_dragOffset;
};

#endif
