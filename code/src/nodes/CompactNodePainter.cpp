#include "CompactNodePainter.h"

#include <QtNodes/AbstractGraphModel>
#include <QtNodes/AbstractNodeGeometry>
#include <QtNodes/BasicGraphicsScene>
#include <QtNodes/NodeGraphicsObject>
#include <QtNodes/StyleCollection>
#include <QtNodes/Definitions>
#include <QPainterPath>

void CompactNodePainter::paint(QPainter *painter, QtNodes::NodeGraphicsObject &ngo) const
{
    painter->setRenderHint(QPainter::Antialiasing);

    drawNodeRect(painter, ngo);
    drawHeader(painter, ngo);
    drawCaption(painter, ngo);
    drawPorts(painter, ngo);
}

void CompactNodePainter::drawNodeRect(QPainter *painter, QtNodes::NodeGraphicsObject &ngo) const
{
    QtNodes::AbstractGraphModel &model = ngo.graphModel();
    QtNodes::NodeId const nodeId = ngo.nodeId();
    QtNodes::AbstractNodeGeometry &geometry = ngo.nodeScene()->nodeGeometry();
    QSize size = geometry.size(nodeId);

    QRectF rect(0, 0, size.width(), size.height());
    double const radius = 5.0;

    // Body
    painter->setPen(Qt::NoPen);
    painter->setBrush(QColor(35, 35, 35, 230));
    painter->drawRoundedRect(rect, radius, radius);

    // Border
    QColor borderColor = ngo.isSelected() ? QColor(255, 170, 0) : QColor(20, 20, 20);
    painter->setPen(QPen(borderColor, ngo.isSelected() ? 1.5 : 1.0));
    painter->setBrush(Qt::NoBrush);
    painter->drawRoundedRect(rect, radius, radius);
}

void CompactNodePainter::drawHeader(QPainter *painter, QtNodes::NodeGraphicsObject &ngo) const
{
    QtNodes::AbstractGraphModel &model = ngo.graphModel();
    QtNodes::NodeId const nodeId = ngo.nodeId();
    QtNodes::AbstractNodeGeometry &geometry = ngo.nodeScene()->nodeGeometry();
    QSize size = geometry.size(nodeId);

    // Get category from model if possible, or use type
    // In QtNodes v3, we can try to find the category in the registry or just use a default
    // For now, I'll use a placeholder or check if the caption contains hints
    QString type = model.nodeData(nodeId, QtNodes::NodeRole::Type).toString();
    
    // We'll hardcode some category mapping for now based on the requested taxonomy
    QString category = "Other";
    if (type == "Rectangle" || type == "Circle" || type == "Ellipse" || type == "Polygon" || type == "Star" || type == "Line" || type == "Arrow" || type == "Triangle")
        category = "Generators";
    else if (type == "Text")
        category = "Text";
    else if (type == "Blur")
        category = "Effects";
    else if (type == "Output")
        category = "Rendering";

    QRectF headerRect(0, 0, size.width(), geometry.captionRect(nodeId).height() + 12);
    QPainterPath path;
    path.addRoundedRect(headerRect, 5.0, 5.0);
    
    // Clip to top only
    QRectF bottomClip(0, 5.0, size.width(), headerRect.height());
    path.addRect(bottomClip);
    
    painter->setPen(Qt::NoPen);
    painter->setBrush(getCategoryColor(category));
    painter->drawPath(path.simplified());
}

void CompactNodePainter::drawCaption(QPainter *painter, QtNodes::NodeGraphicsObject &ngo) const
{
    QtNodes::AbstractGraphModel &model = ngo.graphModel();
    QtNodes::NodeId const nodeId = ngo.nodeId();
    QtNodes::AbstractNodeGeometry &geometry = ngo.nodeScene()->nodeGeometry();

    if (!model.nodeData(nodeId, QtNodes::NodeRole::CaptionVisible).toBool())
        return;

    QString name = model.nodeData(nodeId, QtNodes::NodeRole::Caption).toString();
    QPointF pos = geometry.captionPosition(nodeId);

    QFont font = painter->font();
    font.setBold(true);
    font.setPointSize(9);
    painter->setFont(font);
    painter->setPen(Qt::white);
    painter->drawText(pos, name);
}

void CompactNodePainter::drawPorts(QPainter *painter, QtNodes::NodeGraphicsObject &ngo) const
{
    QtNodes::AbstractGraphModel &model = ngo.graphModel();
    QtNodes::NodeId const nodeId = ngo.nodeId();
    QtNodes::AbstractNodeGeometry &geometry = ngo.nodeScene()->nodeGeometry();

    for (QtNodes::PortType portType : {QtNodes::PortType::In, QtNodes::PortType::Out}) {
        unsigned int n = model.nodeData<unsigned int>(nodeId, (portType == QtNodes::PortType::Out) ? QtNodes::NodeRole::OutPortCount : QtNodes::NodeRole::InPortCount);

        for (unsigned int i = 0; i < n; ++i) {
            QPointF p = geometry.portPosition(nodeId, portType, i);
            
            // Draw port circle
            painter->setPen(QPen(QColor(100, 100, 100), 1.0));
            painter->setBrush(QColor(50, 50, 50));
            
            // If connected, fill it
            if (!model.connections(nodeId, portType, i).empty()) {
                painter->setBrush(QColor(200, 200, 200));
            }
            
            painter->drawEllipse(p, 4.0, 4.0);
        }
    }
}

QColor CompactNodePainter::getCategoryColor(QString const &category) const
{
    if (category == "Generators") return QColor(100, 150, 50, 200); // Green
    if (category == "Effects")    return QColor(50, 100, 150, 200); // Blue
    if (category == "Text")       return QColor(150, 100, 50, 200); // Orange
    if (category == "Rendering")  return QColor(150, 50, 50, 200);  // Red
    if (category == "Motion")     return QColor(50, 150, 150, 200); // Cyan
    if (category == "Animation")  return QColor(150, 50, 150, 200); // Purple
    return QColor(80, 80, 80, 200); // Gray
}
