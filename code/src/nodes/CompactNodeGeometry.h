#pragma once

#include <QtNodes/AbstractNodeGeometry>
#include <QtGui/QFontMetrics>

namespace QtNodes
{
    class AbstractGraphModel;
}

class CompactNodeGeometry : public QtNodes::AbstractNodeGeometry
{
public:
    CompactNodeGeometry(QtNodes::AbstractGraphModel &graphModel);

    QRectF boundingRect(QtNodes::NodeId const nodeId) const override;
    QSize size(QtNodes::NodeId const nodeId) const override;
    void recomputeSize(QtNodes::NodeId const nodeId) const override;

    QPointF portPosition(QtNodes::NodeId const nodeId,
                         QtNodes::PortType const portType,
                         QtNodes::PortIndex const index) const override;

    QPointF portTextPosition(QtNodes::NodeId const nodeId,
                             QtNodes::PortType const portType,
                             QtNodes::PortIndex const portIndex) const override;

    QPointF captionPosition(QtNodes::NodeId const nodeId) const override;
    QRectF captionRect(QtNodes::NodeId const nodeId) const override;

    QPointF labelPosition(QtNodes::NodeId const nodeId) const override;
    QRectF labelRect(QtNodes::NodeId const nodeId) const override;

    QPointF widgetPosition(QtNodes::NodeId const nodeId) const override;
    QRect resizeHandleRect(QtNodes::NodeId const nodeId) const override;

    int getPortSpacing() override { return _portSpacing; }

private:
    unsigned int maxVerticalPortsExtent(QtNodes::NodeId const nodeId) const;
    unsigned int maxPortsTextAdvance(QtNodes::NodeId const nodeId, QtNodes::PortType const portType) const;

    mutable unsigned int _portSize;
    unsigned int _portSpacing;
    mutable QFontMetrics _fontMetrics;
    mutable QFontMetrics _boldFontMetrics;
};
