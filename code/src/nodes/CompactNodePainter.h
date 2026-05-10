#pragma once

#include <QtNodes/AbstractNodePainter>
#include <QtGui/QPainter>

class CompactNodePainter : public QtNodes::AbstractNodePainter
{
public:
    void paint(QPainter *painter, QtNodes::NodeGraphicsObject &ngo) const override;

private:
    void drawNodeRect(QPainter *painter, QtNodes::NodeGraphicsObject &ngo) const;
    void drawHeader(QPainter *painter, QtNodes::NodeGraphicsObject &ngo) const;
    void drawPorts(QPainter *painter, QtNodes::NodeGraphicsObject &ngo) const;
    void drawCaption(QPainter *painter, QtNodes::NodeGraphicsObject &ngo) const;

    QColor getCategoryColor(QString const &category) const;
};
