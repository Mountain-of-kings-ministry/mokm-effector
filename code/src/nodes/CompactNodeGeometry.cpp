#include "CompactNodeGeometry.h"

#include <QtNodes/AbstractGraphModel>
#include <QtNodes/Definitions>
#include <QWidget>

CompactNodeGeometry::CompactNodeGeometry(QtNodes::AbstractGraphModel &graphModel)
    : AbstractNodeGeometry(graphModel)
    , _portSize(14)
    , _portSpacing(6)
    , _fontMetrics(QFont())
    , _boldFontMetrics(QFont())
{
    QFont f;
    f.setBold(true);
    _boldFontMetrics = QFontMetrics(f);

    _portSize = _fontMetrics.height();
}

QRectF CompactNodeGeometry::boundingRect(QtNodes::NodeId const nodeId) const
{
    QSize s = size(nodeId);
    qreal marginSize = 1.5 * _portSpacing;
    return QRectF(0, 0, s.width(), s.height()).marginsAdded({marginSize, marginSize, marginSize, marginSize});
}

QSize CompactNodeGeometry::size(QtNodes::NodeId const nodeId) const
{
    return _graphModel.nodeData<QSize>(nodeId, QtNodes::NodeRole::Size);
}

void CompactNodeGeometry::recomputeSize(QtNodes::NodeId const nodeId) const
{
    unsigned int height = maxVerticalPortsExtent(nodeId);

    if (auto w = _graphModel.nodeData<QWidget *>(nodeId, QtNodes::NodeRole::Widget)) {
        height = std::max(height, static_cast<unsigned int>(w->height()));
    }

    QRectF const capRect = captionRect(nodeId);
    height += capRect.height();
    height += _portSpacing * 2; // Reduced header padding

    unsigned int inPortWidth = maxPortsTextAdvance(nodeId, QtNodes::PortType::In);
    unsigned int outPortWidth = maxPortsTextAdvance(nodeId, QtNodes::PortType::Out);

    unsigned int width = inPortWidth + outPortWidth + 3 * _portSpacing;

    if (auto w = _graphModel.nodeData<QWidget *>(nodeId, QtNodes::NodeRole::Widget)) {
        width += w->width();
    }

    width = std::max(width, static_cast<unsigned int>(capRect.width()) + 2 * _portSpacing);
    width = std::max(width, 80u); // Minimum width

    _graphModel.setNodeData(nodeId, QtNodes::NodeRole::Size, QSize(width, height));
}

QPointF CompactNodeGeometry::portPosition(QtNodes::NodeId const nodeId,
                                         QtNodes::PortType const portType,
                                         QtNodes::PortIndex const portIndex) const
{
    unsigned int const step = _portSize + _portSpacing;
    double totalHeight = captionRect(nodeId).height() + _portSpacing;
    totalHeight += step * portIndex + step / 2.0;

    QSize sz = size(nodeId);
    return (portType == QtNodes::PortType::In) ? QPointF(0.0, totalHeight) : QPointF(sz.width(), totalHeight);
}

QPointF CompactNodeGeometry::portTextPosition(QtNodes::NodeId const nodeId,
                                              QtNodes::PortType const portType,
                                              QtNodes::PortIndex const portIndex) const
{
    QPointF p = portPosition(nodeId, portType, portIndex);
    QString s = _graphModel.portData<QString>(nodeId, portType, portIndex, QtNodes::PortRole::Caption);
    QRectF rect = _fontMetrics.boundingRect(s);
    
    p.setY(p.y() + rect.height() / 4.0);
    if (portType == QtNodes::PortType::In)
        p.setX(_portSpacing);
    else
        p.setX(size(nodeId).width() - _portSpacing - rect.width());
    
    return p;
}

QPointF CompactNodeGeometry::captionPosition(QtNodes::NodeId const nodeId) const
{
    QSize sz = size(nodeId);
    return QPointF(0.5 * (sz.width() - captionRect(nodeId).width()), _portSpacing + _fontMetrics.ascent());
}

QRectF CompactNodeGeometry::captionRect(QtNodes::NodeId const nodeId) const
{
    if (!_graphModel.nodeData<bool>(nodeId, QtNodes::NodeRole::CaptionVisible))
        return QRect();
    return _boldFontMetrics.boundingRect(_graphModel.nodeData<QString>(nodeId, QtNodes::NodeRole::Caption));
}

QPointF CompactNodeGeometry::labelPosition(QtNodes::NodeId const nodeId) const
{
    return QPointF(0, 0); // Not used in this compact version yet
}

QRectF CompactNodeGeometry::labelRect(QtNodes::NodeId const nodeId) const
{
    return QRectF();
}

QPointF CompactNodeGeometry::widgetPosition(QtNodes::NodeId const nodeId) const
{
    unsigned int captionHeight = captionRect(nodeId).height();
    return QPointF(_portSpacing + maxPortsTextAdvance(nodeId, QtNodes::PortType::In),
                   _portSpacing + captionHeight + _portSpacing);
}

QRect CompactNodeGeometry::resizeHandleRect(QtNodes::NodeId const nodeId) const
{
    QSize sz = size(nodeId);
    return QRect(sz.width() - 8, sz.height() - 8, 8, 8);
}

unsigned int CompactNodeGeometry::maxVerticalPortsExtent(QtNodes::NodeId const nodeId) const
{
    unsigned int nIn = _graphModel.nodeData<unsigned int>(nodeId, QtNodes::NodeRole::InPortCount);
    unsigned int nOut = _graphModel.nodeData<unsigned int>(nodeId, QtNodes::NodeRole::OutPortCount);
    return (_portSize + _portSpacing) * std::max(nIn, nOut);
}

unsigned int CompactNodeGeometry::maxPortsTextAdvance(QtNodes::NodeId const nodeId, QtNodes::PortType const portType) const
{
    unsigned int width = 0;
    unsigned int n = _graphModel.nodeData<unsigned int>(nodeId, (portType == QtNodes::PortType::Out) ? QtNodes::NodeRole::OutPortCount : QtNodes::NodeRole::InPortCount);
    for (unsigned int i = 0; i < n; ++i) {
        QString s = _graphModel.portData<QString>(nodeId, portType, i, QtNodes::PortRole::Caption);
        width = std::max(width, static_cast<unsigned int>(_fontMetrics.horizontalAdvance(s)));
    }
    return width;
}
